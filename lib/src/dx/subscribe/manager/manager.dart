import 'dart:async';

import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/dx/_endpoints/subscribe.dart';
import 'package:pubnub/src/state_machine/state_machine.dart';

import 'exceptions.dart';

final _logger = injectLogger('pubnub.dx.subscribe.manager');

class SubscribeFiber implements Fiber {
  @override
  int tries;

  SubscribeFiber(this.tries);

  @override
  final action = null;

  @override
  Future get future => Future.value(null);

  @override
  int get id => -1;

  @override
  Future<void> run() async {}
}

class SubscriptionManager {
  Core core;
  Keyset keyset;

  StreamController<dynamic> _messagesController;
  Stream<dynamic> get messages => _messagesController.stream;

  Blueprint<String, Map<String, dynamic>> _RequestMachine;
  Blueprint<String, Map<String, dynamic>> _SubscriptionMachine;

  StateMachine<String, Map<String, dynamic>> machine;

  SubscriptionManager(this.core, this.keyset) {
    _RequestMachine = Blueprint<String, Map<String, dynamic>>()
      ..define('send', from: ['initialized'], to: 'pending')
      ..define('reject', from: ['pending'], to: 'rejected')
      ..define('resolve', from: ['pending'], to: 'resolved')
      ..define('timeout', from: ['pending'], to: 'rejected')
      ..when('resolved', 'enters').exit(withPayload: true)
      ..when('rejected', 'enters').exit(withPayload: true)
      ..when('initialized', 'enters').callback((ctx) {
        core.networking.handler().then((handler) {
          if (ctx.machine.state == null) {
            handler.cancel();
            return;
          }

          ctx.update({'handler': handler, 'params': ctx.payload});
          ctx.machine.send('send', handler);
        });
      })
      ..when('pending', 'enters').callback((ctx) {
        (ctx.payload as IRequestHandler)
            .response(ctx.context['params'].toRequest())
            .then((response) {
          ctx.machine.send('resolve', response);
        }).catchError((error) {
          ctx.machine.send('reject', error);
        });
      })
      ..when(null, 'enters').callback((ctx) {
        if (ctx.context != null) {
          ctx.context['handler']?.cancel();
        }
      });

    _SubscriptionMachine = Blueprint<String, Map<String, dynamic>>()
      ..define('fetch',
          from: ['state.idle', 'state.fetching'], to: 'state.fetching')
      ..define('idle', from: ['state.fetching', 'state.idle'], to: 'state.idle')
      ..define('update',
          from: ['state.idle', 'state.fetching'], to: 'state.idle')
      ..when(null, 'exits').callback((ctx) {
        ctx.update(ctx.payload);
      })
      ..when('state.idle', 'enters').callback((ctx) {
        _logger.silly(
            'TOP: Entering ${ctx.entering} from ${ctx.exiting} because of ${ctx.event} with ${ctx.payload}');

        if (ctx.event == 'update') {
          var newContext = <String, dynamic>{...ctx.context, ...ctx.payload};
          Completer<void> completer = newContext['completer'];
          newContext.remove('completer');
          ctx.update(newContext);

          if ((newContext['channels'].length > 0 ||
              newContext['channelGroups'].length > 0)) {
            if (_messagesController == null || _messagesController.isClosed) {
              _logger.silly('TOP: Creating the controller...');
              _messagesController = StreamController.broadcast();
            }

            ctx.machine.send('fetch');
          } else {
            if (_messagesController != null) {
              _logger.silly('TOP: Disposing the controller...');
              _messagesController.close();
              _messagesController = null;
            }
          }

          completer?.complete();
        }
      });

    _SubscriptionMachine
      ..when('state.fetching').machine(
        'request',
        _RequestMachine,
        onParentEnter: (m, sm) {
          Future.delayed(Duration(seconds: 270), () {
            sm.send('timeout', SubscribeTimeoutException());
          });
        },
        onParentExit: (m, sm) {
          _logger.silly('SUB: Parent is exiting when my state is ${sm.state}');
          if (sm.state == 'pending' || sm.state == 'initialized') {
            _logger.silly('SUB: Cancelling pending request.');
            if (sm.context != null) sm.context['handler']?.cancel();
          }
        },
        onBuild: (m, sm) {
          _logger.silly('TOP: Entering state.fetching');
          var params = SubscribeParams(keyset, m.context['timetoken'].value,
              region: m.context['region'],
              channels: m.context['channels'],
              channelGroups: m.context['channelGroups']);

          sm.enter('initialized', params);
        },
        onEnter: (ctx, m, sm) {
          _logger.silly(
              'SUB: Submachine entered ${ctx.exiting} from ${ctx.entering} because ${ctx.event} (with ${ctx.payload}).');
        },
        onExit: (ctx, m, sm) async {
          switch (ctx.exiting) {
            case 'resolved':
              _logger.silly(
                  'SUB: Submachine exited ${ctx.exiting} to ${ctx.entering} because ${ctx.event} (with ${ctx.payload}).');
              IResponse response = ctx.payload;
              var object = await core.parser.decode(await response.text);
              var result = SubscribeResult.fromJson(object);

              await _messagesController
                  .addStream(Stream.fromIterable(result.messages));

              m.send('update', {
                'timetoken': result.timetoken,
                'region': result.region,
                'retry': 1
              });
              break;
            case 'rejected':
              var fiber = SubscribeFiber(m.context['retry'] ?? 1);
              _logger.warning(
                  'An exception has occured while running a subscribe loop (retry #${fiber.tries}).');
              var diagnostic =
                  core.supervisor.runDiagnostics(fiber, ctx.payload);

              if (diagnostic == null) {
                return _messagesController.addError(ctx.payload);
              }

              _logger.silly('Possible reason found: $diagnostic');

              var resolutions =
                  core.supervisor.runStrategies(fiber, diagnostic);

              for (var resolution in resolutions) {
                if (resolution is FailResolution) {
                  _messagesController.addError(ctx.payload);
                } else if (resolution is DelayResolution) {
                  await Future.delayed(resolution.delay);
                } else if (resolution is RetryResolution) {
                  m.send('update', {'retry': fiber.tries + 1});
                }
              }
              break;
          }
        },
      );

    machine = _SubscriptionMachine.build();

    machine.enter('state.idle', {
      'channels': <String>{},
      'channelGroups': <String>{},
      'timetoken': Timetoken(0),
      'region': null,
    });

    core.supervisor.events
        .where((event) => event is NetworkIsDownEvent)
        .listen((_event) {
      machine.send('update', {'retry': (machine.context['retry'] ?? 1) + 1});
    });
  }

  Future<void> update(
      Map<String, dynamic> Function(Map<String, dynamic> ctx) cb) {
    var completer = Completer<void>();
    if (machine.state != 'state.idle') {
      machine.send('fail', SubscribeOutdatedException());
    }

    machine.send('update', {
      ...cb(
        machine.context,
      ),
      'completer': completer,
    });

    return completer.future;
  }
}
