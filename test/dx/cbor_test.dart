import 'package:test/test.dart';

import 'package:pubnub/src/dx/pam/cbor.dart';
import 'package:pubnub/src/dx/pam/pam.dart';

part './fixtures/cbor.dart';

void main() {
  test('decode should return token object with valid permissions for user', () {
    var tokenObject = decode(_tokenWithUserResource);
    var user = tokenObject.resources[ResourceType.user.value] as Map;
    expect(user.keys, contains('user1'));
    expect((user['user1'] as Permissions).read, equals(true));
  });

  test('decode should return token object with valid resource pattern details',
      () {
    var tokenObject = decode(_tokenWithUserPattern);
    var user = tokenObject.patterns[ResourceType.user.value] as Map;
    expect(user.keys, contains('.*'));
    expect((user['.*'] as Permissions).read, equals(true));
  });

  test('decode should return token object with valid permissions for space',
      () {
    var tokenObject = decode(_tokenWithSpaceResource);
    var space = tokenObject.resources[ResourceType.space.value] as Map;
    expect(space.keys, contains('space1'));
    expect((space['space1'] as Permissions).read, equals(true));
  });

  test(
      'decode should return token object with valid permissions for space pattern',
      () {
    var tokenObject = decode(_tokenWithSpaceResourcePattern);
    var space = tokenObject.patterns[ResourceType.space.value] as Map;
    expect(space.keys, contains('.*'));
    expect((space['.*'] as Permissions).read, equals(true));
  });
}
