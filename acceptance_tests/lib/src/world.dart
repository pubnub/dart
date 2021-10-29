import 'dart:async';

import 'package:gherkin/gherkin.dart';
import 'package:pubnub/networking.dart';
import 'package:pubnub/pubnub.dart';

import 'logger.dart';
import 'config.dart';

class PubNubWorld extends World {
  final TestLogger logger;

  static Future<World> create(TestConfiguration config) async {
    if (config is PubNubConfiguration) {
      return PubNubWorld(config.logger);
    } else {
      throw Exception('Invalid configuration');
    }
  }

  late PubNub pubnub;

  Keyset? keyset;
  late Channel currentChannel;
  Subscription? currentSubscription;

  List<Envelope> messages = [];
  Completer<Envelope> firstMessageCompleter = Completer();
  Future<Envelope> get firstMessage => firstMessageCompleter.future;

  String? latestResultType;
  dynamic latestResult;
  Object? latestException;

  Map<String, dynamic> scenarioContext = {};

  PubNubWorld(this.logger) {
    pubnub = PubNub(
      defaultKeyset: Keyset(
        subscribeKey: 'demo',
        publishKey: 'demo',
        uuid: UUID('dart_acceptance_testing'),
      ),
      networking: NetworkingModule(origin: 'localhost:8090', ssl: false),
    );
  }

  Future<void> cleanup() async {
    await pubnub.unsubscribeAll();
  }

  @override
  void dispose() {
    if (currentSubscription != null && !currentSubscription!.isCancelled) {
      currentSubscription!.cancel();
    }
  }
}
