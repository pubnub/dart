import 'dart:async';
import 'package:async/async.dart';

import 'package:pubnub/core.dart';
import 'subscribe_loop_state.dart';
import 'subscribe_fiber.dart';
import '../envelope.dart';
import '../_endpoints/subscribe.dart';

final _logger = injectLogger('pubnub.subscribe.subscribe_loop');

/// @nodoc
typedef UpdateCallback = SubscribeLoopState Function(SubscribeLoopState state);

/// @nodoc
class UpdateException implements Exception {}

/// @nodoc
class CancelException implements Exception {}

/// @nodoc
Future<T> withCancel<T>(Future<T> future, Future<Exception> signal) async {
  var completer = Completer<T>();

  await Future.any([
    future.then((result) {
      if (!completer.isCompleted) completer.complete(result);
    }).catchError((error) {
      if (!completer.isCompleted) completer.completeError(error);
    }),
    signal.then((error) {
      if (!completer.isCompleted) completer.completeError(error);
    }).catchError((error) {
      if (!completer.isCompleted) completer.completeError(error);
    })
  ]);

  return completer.future;
}

/// @nodoc
class SubscribeLoop {
  SubscribeLoopState _state;
  Core core;

  SubscribeLoop(this.core, this._state) {
    _messagesController = StreamController.broadcast(
      onListen: () => update((state) => state.clone(isActive: true)),
      onCancel: () => update((state) => state.clone(isActive: false)),
    );

    var loopStream = _loop();

    loopStream.listen((envelope) {
      _messagesController.add(envelope);
    }, onError: (exception) {
      _messagesController.addError(exception);
    });

    core.supervisor.signals.networkIsConnected
        .listen((_) => update((state) => state));
  }

  late StreamController<Envelope> _messagesController;
  Stream<Envelope> get envelopes => _messagesController.stream;

  Completer<void> _whenStarts = Completer();
  Future<void> get whenStarts => _whenStarts.future;

  final StreamController<Exception> _queueController =
      StreamController.broadcast();

  void update(UpdateCallback callback, {bool skipCancel = false}) {
    var newState = callback(_state);

    _state = newState;
    _logger.silly('State has been updated.');

    if (skipCancel == false) {
      _queueController.add(CancelException());
    }
  }

  Stream<Envelope> _loop() async* {
    IRequestHandler? handler;
    var tries = 0;

    while (true) {
      var queue = StreamQueue(_queueController.stream);

      try {
        _logger.silly('Starting new loop iteration.');
        tries += 1;
        var state = _state;

        if (!state.shouldRun) {
          await queue.peek;
        }

        handler = await withCancel(core.networking.handler(), queue.peek);

        var params = SubscribeParams(state.keyset, state.timetoken.value,
            region: state.region,
            channels: state.channels,
            channelGroups: state.channelGroups);

        if (!_whenStarts.isCompleted && state.timetoken.value != BigInt.zero) {
          _whenStarts.complete();
          _whenStarts = Completer();
        }

        var response =
            await withCancel(handler!.response(params.toRequest()), queue.peek);

        core.supervisor.notify(NetworkIsUpEvent());

        var object =
            await withCancel(core.parser.decode(response.text), queue.peek);

        var result = SubscribeResult.fromJson(object);

        _logger.silly(
            'Result: timetoken ${result.timetoken}, new messages: ${result.messages.length}');

        yield* Stream.fromIterable(result.messages).asyncMap((object) async {
          if (state.keyset.cipherKey != null &&
              (object['e'] == null || object['e'] == 4) &&
              !object['c'].endsWith('-pnpres')) {
            try {
              _logger.silly('decrypting message...');
              object['d'] = await core.parser.decode(
                  core.crypto.decrypt(state.keyset.cipherKey!, object['d']));
            } catch (e) {
              throw PubNubException(
                  'Can not decrypt the message payload. Please check keyset configuration.');
            }
          }
          return Envelope.fromJson(object);
        });
        _logger.silly('Updating the state...');

        tries = 0;

        update((state) =>
            state.clone(timetoken: result.timetoken, region: result.region));
      } catch (exception) {
        var fiber = SubscribeFiber(tries);

        if (handler != null && !handler.isCancelled) {
          _logger.silly('Cancelling the handler...');
          handler.cancel();
        }

        if (exception is UpdateException || exception is CancelException) {
          continue;
        }

        _logger.warning(
            'An exception (${exception.runtimeType}) has occured while running a subscribe fiber (retry #$tries).');
        var diagnostic = core.supervisor.runDiagnostics(fiber, exception);

        if (diagnostic == null) {
          _logger.warning('No diagnostics found.');

          if (!_whenStarts.isCompleted) {
            _whenStarts.completeError(Exception('subscribe failed'));
          }
          rethrow;
        }

        _logger.silly('Possible reason found: $diagnostic');

        var resolutions = core.supervisor.runStrategies(fiber, diagnostic);

        if (resolutions == null) {
          _logger.silly('No resolutions found.');
          rethrow;
        }

        for (var resolution in resolutions) {
          if (resolution is FailResolution) {
            rethrow;
          } else if (resolution is DelayResolution) {
            await Future.delayed(resolution.delay);
          } else if (resolution is RetryResolution) {
            continue;
          } else if (resolution is NetworkStatusResolution) {
            core.supervisor.notify(
                resolution.isUp ? NetworkIsUpEvent() : NetworkIsDownEvent());
          }
        }
      } finally {
        handler = null;
        await queue.cancel(immediate: true);
      }
    }
  }
}
