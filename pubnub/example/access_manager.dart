// Snippets for the Access Manager documentation pages.
//
// Every region between `snippet.<name>` and `snippet.end` is pulled into the
// docs, so keep each one self-contained and keep the marker lines alone on
// their line. The file compiles as a whole (`dart analyze example/access_manager.dart`),
// but it is a collection of samples rather than a program to run.
//
// ignore_for_file: unused_local_variable

import 'package:pubnub/pubnub.dart';

// Granting tokens requires a client that holds a secret key.
final pubnub = PubNub(
  defaultKeyset: Keyset(
    subscribeKey: 'demo',
    publishKey: 'demo',
    secretKey: 'demo',
    userId: UserId('dart-access-manager-sample'),
  ),
);

// snippet.grant_token_categories
Future<void> grantTokenCategories() async {
  var request = pubnub.requestToken(
    ttl: 15,
    authorizedUserId: 'my-authorized-user-id',
  );

  // Lets the token holder list all channel metadata and all uuid metadata.
  // Category permissions support only the `get` operation.
  request.addCategory(ResourceType.channel);
  request.addCategory(ResourceType.uuid);

  var token = await pubnub.grantToken(request);

  print('grant token = $token');
}
// snippet.end

// snippet.parse_token_categories
void parseTokenCategories(String tokenString) {
  var token = pubnub.parseToken(tokenString);

  for (var category in token.categories) {
    print('${category.type.name} category: get=${category.get}');
  }
}
// snippet.end
