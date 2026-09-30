import 'dart:io';

import 'package:pubnub/pubnub.dart';

/// Subscribe key of the PAM-enabled keyset used by the token integration tests.
final pamSubscribeKey = Platform.environment['DS_SUBSCRIBE_KEY'] ?? '';

/// Publish key of the PAM-enabled keyset used by the token integration tests.
final pamPublishKey = Platform.environment['DS_PUBLISH_KEY'];

/// Secret key of the PAM-enabled keyset used by the token integration tests.
final pamSecretKey = Platform.environment['DS_SECRET_KEY'];

/// Creates the PAM-enabled keyset used by the token integration tests.
Keyset createPamKeyset({String userId = 'dataSync-tester'}) => Keyset(
      subscribeKey: pamSubscribeKey,
      publishKey: pamPublishKey,
      secretKey: pamSecretKey,
      userId: UserId(userId),
    );

/// Creates a [PubNub] instance for the PAM-enabled keyset.
PubNub createPamClient({String userId = 'dataSync-tester'}) => PubNub(
      defaultKeyset: createPamKeyset(userId: userId),
    );
