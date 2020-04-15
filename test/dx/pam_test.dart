import 'package:test/test.dart';
import 'package:typed_data/typed_data.dart';

import 'package:pubnub/src/core/core.dart';
import 'package:pubnub/src/default.dart';
import 'package:pubnub/src/dx/_utils/utils.dart';
import 'package:pubnub/src/dx/pam/pam.dart';
import 'package:pubnub/src/dx/_endpoints/pam.dart';

import '../net/fake_net.dart';

part './fixtures/pam.dart';

void main() {
  PubNub pubnub;
  group('DX [Pam]', () {
    setUp(() {
      pubnub = PubNub(networking: FakeNetworkingModule())
        ..keysets.add(
            Keyset(subscribeKey: 'test', publishKey: 'test', authKey: 'test'),
            name: 'default',
            useAsDefault: true);
    });

    test("grant throws for when keyset is not provided", () {
      pubnub.keysets.remove('default');
      expect(pubnub.grant(<String>{'auth'}),
          throwsA(TypeMatcher<KeysetException>()));
    });

    test("grant should return valid result", () async {
      var authKeys = <String>{'authKey'};
      var channels = <String>{'my_channel'};
      when(
          path:
              'v2/auth/grant/sub-key/test?auth=authKey&channel=my_channel&d=0&m=0&r=1&ttl=1440&w=0',
          method: 'GET',
          then: FakeResult(_grantSuccessResponse));
      var response = await pubnub.grant(authKeys,
          channels: channels,
          read: true,
          write: false,
          manage: false,
          ttl: 1440);
      expect(response, isA<GrantResult>());
    });

    test("grantToken throws when resources null", () async {
      int ttl = 1440;
      var request = GrantTokenRequest(ttl)
        ..patterns = (Patterns()
          ..channels = <String, Permissions>{}
          ..groups = <String, Permissions>{}
          ..users = <String, Permissions>{}
          ..spaces = <String, Permissions>{})
        ..meta = {
          "user-id": "jay@example.com",
          "contains-unicode": "The 來 test."
        };
      var input = GrantTokenInput(request);
      expect(
          pubnub.grantToken(input), throwsA(TypeMatcher<InvariantException>()));
    });
    test("grantToken throws when patterns null", () async {
      int ttl = 1440;
      var request = GrantTokenRequest(ttl)
        ..resources = (Resources()
          ..channels = <String, Permissions>{
            'inbox-jay': Permissions()..write = true
          }
          ..groups = <String, Permissions>{}
          ..users = <String, Permissions>{}
          ..spaces = <String, Permissions>{})
        ..meta = {
          "user-id": "jay@example.com",
          "contains-unicode": "The 來 test."
        };
      var input = GrantTokenInput(request);
      expect(
          pubnub.grantToken(input), throwsA(TypeMatcher<InvariantException>()));
    });
    test("grantToken should return valid result", () async {
      int ttl = 1440;
      var request = GrantTokenRequest(ttl)
        ..resources = (Resources()
          ..channels = <String, Permissions>{
            'inbox-jay': Permissions()
              ..write = true
              ..read = true
          }
          ..groups = <String, Permissions>{}
          ..users = <String, Permissions>{}
          ..spaces = <String, Permissions>{})
        ..patterns = (Patterns()
          ..channels = <String, Permissions>{}
          ..groups = <String, Permissions>{}
          ..users = <String, Permissions>{}
          ..spaces = <String, Permissions>{})
        ..meta = {
          "user-id": "jay@example.com",
          "contains-unicode": "The 來 test."
        };
      var input = GrantTokenInput(request);
      when(
          path: 'v3/pam/test/grant',
          method: 'POST',
          body: _grantTokenBody,
          then: FakeResult(_grantTokenSuccessResponse));
      var response = await pubnub.grantToken(input);
      expect(response, isA<GrantTokenResult>());
    });

    test("grantToken returns error response", () async {
      int ttl = 1440;
      var request = GrantTokenRequest(ttl)
        ..resources = (Resources()
          ..channels = <String, Permissions>{
            'inbox-jay': Permissions()
              ..write = true
              ..read = true
          }
          ..groups = <String, Permissions>{}
          ..users = <String, Permissions>{}
          ..spaces = <String, Permissions>{})
        ..patterns = (Patterns()
          ..channels = <String, Permissions>{}
          ..groups = <String, Permissions>{}
          ..users = <String, Permissions>{}
          ..spaces = <String, Permissions>{})
        ..meta = {
          "user-id": "jay@example.com",
          "contains-unicode": "The 來 test."
        };
      var input = GrantTokenInput(request);
      when(
          path: 'v3/pam/test/grant',
          method: 'POST',
          body: _grantTokenBody,
          then: FakeResult(_grantTokenErrorResponse));
      var response = await pubnub.grantToken(input);
      expect(response, isA<GrantTokenResult>());
      expect(response.status, 400);
      expect(response.error['details'][0]['location'], 'ttl');
    });

    group('TokenManager', () {
      test("parse token should parse token info correctly", () {
        var token = pubnub.parseToken(_tokenWithUserandSpaceInfo);
        expect(token.version, equals(2));
        expect('${token.timestamp}', equals('1568768790'));
        expect(token.timeToLive, equals(1440));
        expect(token.resources, isA<Map>());
        expect(token.signature, isA<Uint8Buffer>());
      });
      test("setToken stores token info for resource and patterns", () {
        pubnub.setToken(_tokenWithUserandSpaceInfo);
        var user1Token = pubnub.getToken(ResourceType.user, 'user1');
        var spaceToken = pubnub.getToken(ResourceType.space, "space");
        var userToken = pubnub.getToken(ResourceType.user, "user");
        var space1Token = pubnub.getToken(ResourceType.space, 'space1');
        expect(user1Token, equals(_tokenWithUserandSpaceInfo));
        expect(
            userToken, equals(_tokenWithUserandSpaceInfo)); // Due to .* pattern
        expect(space1Token, equals(_tokenWithUserandSpaceInfo));
        expect(spaceToken,
            equals(_tokenWithUserandSpaceInfo)); // Due to .* pattern
      });

      test("setTokens stores token info correctly", () {
        pubnub.setTokens(_multipleTokensSet);
        var user1Token = pubnub.getToken(ResourceType.user, 'user1');
        var space1Token = pubnub.getToken(ResourceType.space, 'space1');
        expect(user1Token, equals(_multipleTokensSet.first));
        expect(space1Token, equals(_multipleTokensSet.last));
      });
      test("setTokens with multiple resource Type", () {
        pubnub.setToken(_tokenWithMultipleResourceTypes);
        var userToken = pubnub.getTokens(ResourceType.user);
        var spaceToken = pubnub.getTokens(ResourceType.space);
        expect(userToken.first, equals(_tokenWithMultipleResourceTypes));
        expect(spaceToken.first, equals(_tokenWithMultipleResourceTypes));
      });
      test("setTokens stores token info for multiple users correctly", () {
        pubnub.setTokens(_multipleUsersTokensSet);
        var user1Token = pubnub.getToken(ResourceType.user, 'user1');
        var user2Token = pubnub.getToken(ResourceType.user, 'user2');
        expect(user1Token, equals(_multipleUsersTokensSet.first));
        expect(user2Token, equals(_multipleUsersTokensSet.last));
      });

      test("getToken should retrive token info correctly", () {
        pubnub.setToken(_userPermissionToken);
        var user1Token = pubnub.getToken(ResourceType.user, 'user1');
        expect(user1Token, equals(_userPermissionToken));
      });

      test("getToken should return null token info token not found", () {
        pubnub.setToken(_userPermissionToken);
        var user1Token = pubnub.getToken(ResourceType.user, 'userX');
        expect(user1Token, equals(null));
      });

      test("getTokens should retrive asked resource type tokens", () {
        pubnub.setToken(_userPermissionToken);
        var userTokens = pubnub.getTokens(ResourceType.user);
        expect(userTokens, contains(_userPermissionToken));
      });

      test("setToken should override old Token", () {
        pubnub.setToken(_userPermissionToken);
        var userOldTokens = pubnub.getToken(ResourceType.user, 'user1');
        pubnub.setToken(_userInfoNewToken);
        var userTokens = pubnub.getToken(ResourceType.user, 'user1');
        expect(userOldTokens, contains(_userPermissionToken));
        expect(userTokens, contains(_userInfoNewToken));
      });

      test("remove token should remove all tokens", () {
        pubnub.setTokens(_multipleTokensSet);
        pubnub.removeAllTokens();
        expect(pubnub.getTokens(ResourceType.user).length, equals(0));
      });
    });
  });
}
