import 'dart:convert';

import 'package:pubnub/pubnub.dart';

import '../../net/fake_net.dart';

export '../../net/fake_net.dart';

const subKey = 'test';

const entityContentType =
    'application/vnd.pubnub.objects.entity+json;version=1';
const relationshipContentType =
    'application/vnd.pubnub.objects.relationship+json;version=1';
const userContentType = 'application/vnd.pubnub.objects.user+json;version=1';
const channelContentType =
    'application/vnd.pubnub.objects.channel+json;version=1';
const membershipContentType =
    'application/vnd.pubnub.objects.membership+json;version=1';
const patchContentType = 'application/json-patch+json';

/// Builds the path of a DataSync request, including the query parameters the
/// SDK always adds.
String dsPath(String resource,
    {String? id,
    Map<String, String> query = const {},
    String subscribeKey = subKey,
    String uuid = 'test'}) {
  var uri = Uri(pathSegments: [
    'v1',
    'datasync',
    'subkeys',
    subscribeKey,
    resource,
    if (id != null) id,
  ], queryParameters: {
    'pnsdk': 'PubNub-Dart/${PubNub.version}',
    'uuid': uuid,
    ...query,
  });

  return '/$uri';
}

/// Header map expected by [when] for a single header.
Map<String, List<String>> header(String name, String value) => {
      name: [value]
    };

/// Headers expected by [when] for a body carrying request.
Map<String, List<String>> contentType(String type, {String? ifMatch}) => {
      'Content-Type': [type],
      if (ifMatch != null) 'If-Match': [ifMatch],
    };

PubNub newClient({String? authKey}) => PubNub(
    defaultKeyset: Keyset(
        subscribeKey: subKey,
        publishKey: 'test',
        authKey: authKey,
        userId: UserId('test')),
    networking: FakeNetworkingModule());

String body(Object value) => jsonEncode(value);

String dataBody(Map<String, dynamic> data) => jsonEncode({'data': data});

const entityCursorPage2 = 'eyJpIjoiMTQzNTYzIiwic3YiOltdfQ';
const entityCursorPage3 = 'eyJpIjoiMTQzNjEyIiwic3YiOltdfQ';

Map<String, dynamic> customerPayload(String id,
        [Map<String, dynamic> overrides = const {}]) =>
    {
      'customerId': id,
      'firstName': 'Alice',
      'lastName': 'Verma',
      'email': 'alice.verma@acme.test',
      'creditScore': 720,
      'city': 'Pune',
      ...overrides,
    };

Map<String, dynamic> userPayload([Map<String, dynamic> overrides = const {}]) =>
    {
      'firstName': 'Alice',
      'lastName': 'Verma',
      'email': 'alice.verma@acme.test',
      ...overrides,
    };

Map<String, dynamic> channelPayload(
        [Map<String, dynamic> overrides = const {}]) =>
    {
      'name': 'engineering',
      'description': 'engineering',
      'kind': 'public',
      ...overrides,
    };

Map<String, dynamic> entityObject([Map<String, dynamic> overrides = const {}]) {
  var id = overrides['id'] ?? 'customer-43508';
  return {
    'id': id,
    'createdAt': '2026-09-07T07:25:20.309207Z',
    'updatedAt': '2026-09-07T07:25:20.309207Z',
    'eTag': 'y26s8e',
    'expiresAt': '2027-09-08T00:00:00Z',
    'entityClass': 'Customer',
    'entityClassVersion': 1,
    'entityClassLevel': 'SubKey',
    'status': 'active',
    'payload': customerPayload(id),
    ...overrides,
  };
}

Map<String, dynamic> userObject([Map<String, dynamic> overrides = const {}]) =>
    {
      'id': 'user-99961',
      'createdAt': '2026-09-07T07:34:55.265874Z',
      'updatedAt': '2026-09-07T07:34:55.265874Z',
      'eTag': 'y2j3ve',
      'expiresAt': '2026-10-08T00:00:00Z',
      'entityClass': 'User',
      'entityClassVersion': 1,
      'entityClassLevel': 'Global',
      'status': 'active',
      'payload': userPayload(),
      ...overrides,
    };

Map<String, dynamic> channelObject(
        [Map<String, dynamic> overrides = const {}]) =>
    {
      'id': 'JSchannel-56738',
      'createdAt': '2026-09-07T06:57:09.375184Z',
      'updatedAt': '2026-09-07T06:57:09.375184Z',
      'eTag': 'y16jaw',
      'expiresAt': '2026-10-08T00:00:00Z',
      'entityClass': 'Channel',
      'entityClassVersion': 1,
      'entityClassLevel': 'Global',
      'status': 'active',
      'payload': channelPayload(),
      ...overrides,
    };

Map<String, dynamic> relationshipObject(
        [Map<String, dynamic> overrides = const {}]) =>
    {
      'id': 'requested-by-55620',
      'createdAt': '2026-09-07T08:09:08.253170Z',
      'updatedAt': '2026-09-07T08:09:08.253170Z',
      'eTag': 'y3r3fa',
      'expiresAt': '2027-09-08T00:00:00Z',
      'relationshipClass': 'REQUESTED_BY',
      'relationshipClassVersion': 1,
      'entityAId': 'customer-20648',
      'entityBId': 'loanquote-23500',
      'status': 'active',
      'payload': {'linkedAt': '2026-07-06T10:00:00.000Z'},
      ...overrides,
    };

Map<String, dynamic> membershipObject(
        [Map<String, dynamic> overrides = const {}]) =>
    {
      'id': 'membership-18116',
      'createdAt': '2026-09-07T07:42:29.374143Z',
      'updatedAt': '2026-09-07T07:42:29.374143Z',
      'eTag': 'y2sto7',
      'expiresAt': '2026-10-08T00:00:00Z',
      'relationshipClass': 'Membership',
      'relationshipClassVersion': 1,
      'channelId': 'JSchannel-46429',
      'userId': 'user-97219',
      'status': 'active',
      'payload': {'role': 'member', 'joinedAt': '2026-07-06T10:00:00.000Z'},
      ...overrides,
    };

Map<String, dynamic> notFoundError(String id) => {
      'errors': [
        {'errorCode': 'DS-0100', 'message': 'Entity not found: $id'}
      ]
    };

Map<String, dynamic> relationshipNotFoundError(String id) => {
      'errors': [
        {'errorCode': 'DS-0100', 'message': "Relationship '$id' not found"}
      ]
    };

const accessDeniedError = {
  'error': true,
  'status': 403,
  'service': 'Access Manager',
  'message': 'Forbidden',
};

/// A list page response.
String listBody(List<Map<String, dynamic>> rows,
        {String? nextCursor, bool hasNext = false, int? limit}) =>
    jsonEncode({
      'data': rows,
      'meta': {
        'next_cursor': nextCursor,
        'has_next': hasNext,
        if (limit != null) 'limit': limit,
      }
    });
