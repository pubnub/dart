import 'package:gherkin/gherkin.dart';
import 'package:pubnub/networking.dart';
import 'package:pubnub/pubnub.dart';

import 'logger.dart';
import 'mock_server/mock_server.dart';
import 'config.dart';

class PubNubWorld extends World {
  final TestLogger logger;

  static Future<World> create(TestConfiguration config) async {
    if (config is PubNubConfiguration) {
      var mockServer = config.blueprint.create();

      return PubNubWorld(mockServer, config.logger);
    } else {
      throw Exception('Invalid configuration');
    }
  }

  late PubNub pubnub;

  Keyset? keyset;
  late Channel currentChannel;
  late Subscription currentSubscription;

  String? latestResultType;
  dynamic latestResult;

  final MockServer mockServer;

  PubNubWorld(this.mockServer, this.logger) {
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
}
