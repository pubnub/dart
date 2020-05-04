import 'dart:async';

import 'package:logging/logging.dart';
import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/dx/_endpoints/subscribe.dart';
import 'package:pubnub/src/state_machine/state_machine.dart';

import 'exceptions.dart';

final _log = Logger('pubnub.dx.subscribe.manager');

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
      ..define('reject', from: ['pending'], to: 'rejected')
      ..define('resolve', from: ['pending'], to: 'resolved')
      ..define('timeout', from: ['pending'], to: 'rejected')
      ..when('resolved', 'enters').exit(withPayload: true)
      ..when('rejected', 'enters').exit(withPayload: true)
      ..when(null).send('timeout',
          payload: SubscribeTimeoutException(), after: Duration(seconds: 270))
      ..when('pending', 'enters').callback((ctx) async {
        SubscribeParams params = ctx.payload;

        try {
          var handler = await core.networking.handle(params.toRequest());

          ctx.update({'handler': handler});

          var result = await handler.text();
          ctx.machine.send('resolve', result);
        } catch (error) {
          ctx.machine.send('reject', error);
        }
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
        _log.info(
            'Entering ${ctx.entering} from ${ctx.exiting} because of ${ctx.event}');

        if (ctx.event == 'update') {
          var newContext = <String, dynamic>{...ctx.context, ...ctx.payload};
          ctx.update(newContext);

          if (newContext['isEnabled'] == true &&
              (newContext['channels'].length > 0 ||
                  newContext['channelGroups'].length > 0)) {
            if (_messagesController == null || _messagesController.isClosed) {
              _log.info('Creating the controller...');
              _messagesController = StreamController.broadcast();
            }
            ctx.machine.send('fetch');
          } else {
            if (_messagesController != null) {
              _log.info('Disposing the controller...');
              _messagesController.close();
              _messagesController = null;
            }
          }
        }
      });

    _SubscriptionMachine
      ..when('state.fetching').machine('request', _RequestMachine,
          onBuild: (m, sm) {
        var params = SubscribeParams(keyset, m.context['timetoken'].value,
            region: m.context['region'],
            channels: m.context['channels'],
            channelGroups: m.context['channelGroups']);

        sm.enter('pending', params);
      }, onExit: (ctx, m, sm) async {
        switch (ctx.exiting) {
          case 'resolved':
            var object = await core.parser.decode(ctx.payload);
            var result = SubscribeResult.fromJson(object);

            await _messagesController
                .addStream(Stream.fromIterable(result.messages));

            m.send('update',
                {'timetoken': result.timetoken, 'region': result.region});
            break;
          case 'rejected':
            if (ctx.payload is SubscribeTimeoutException) {
              m.send('update', {});
            }
            break;
        }
      });

    machine = _SubscriptionMachine.build();

    machine.enter('state.idle', {
      'channels': <String>{},
      'channelGroups': <String>{},
      'timetoken': Timetoken(0),
      'region': null,
    });
  }

  void update(Map<String, dynamic> Function(Map<String, dynamic> ctx) cb) {
    if (machine.state != 'state.idle') {
      machine.send('fail', SubscribeOutdatedException());
    }

    machine.send('update', cb(machine.context));
  }
}
