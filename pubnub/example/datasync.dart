// Snippets for the DataSync documentation pages.
//
// Every region between `snippet.<name>` and `snippet.end` is pulled into the
// docs, so keep each one self-contained and keep the marker lines alone on
// their line. The file compiles as a whole (`dart analyze example/datasync.dart`),
// but it is a collection of samples rather than a program to run.
//
// ignore_for_file: unused_local_variable

// snippet.setup
import 'package:pubnub/pubnub.dart';

// DataSync requests must be authorized. A client that holds a secret key signs
// its requests, a client without one sets a token with `pubnub.setToken(...)`.
final pubnub = PubNub(
  defaultKeyset: Keyset(
    subscribeKey: 'demo',
    publishKey: 'demo',
    secretKey: 'demo',
    userId: UserId('dart-datasync-sample'),
  ),
);
// snippet.end

// snippet.create_user_basic_usage
Future<void> createUser() async {
  var result = await pubnub.dataSync.createUser(UserInput(
    id: 'user-alice',
    classVersion: 1,
    payload: {'name': 'Alice', 'type': 'shopper'},
  ));

  print('Created ${result.user.id} with eTag ${result.user.eTag}');
}
// snippet.end

// snippet.get_user_basic_usage
Future<void> getUser() async {
  var result = await pubnub.dataSync.getUser('user-alice');

  print('Fetched ${result.user.id}');
}
// snippet.end

// snippet.get_users_basic_usage
Future<void> getUsers() async {
  var result = await pubnub.dataSync.getUsers();

  print('Fetched ${result.users.length} users');
}
// snippet.end

// snippet.set_user_basic_usage
Future<void> setUser() async {
  var result = await pubnub.dataSync.setUser(
    'user-alice',
    UserUpdate(
      classVersion: 1,
      payload: {'name': 'Alice B.', 'type': 'shopper'},
    ),
  );

  print('Replaced user, new eTag ${result.user.eTag}');
}
// snippet.end

// snippet.update_user_basic_usage
Future<void> updateUser() async {
  var result = await pubnub.dataSync.updateUser(
    'user-alice',
    replace: {'/payload/name': 'Alice B.'},
  );

  print('Patched user, new eTag ${result.user.eTag}');
}
// snippet.end

// snippet.remove_user_basic_usage
Future<void> removeUser() async {
  await pubnub.dataSync.removeUser('user-alice');

  print('Removed user-alice');
}
// snippet.end

// snippet.get_users_filter_fast
Future<void> getUsersFilterFast() async {
  var result = await pubnub.dataSync.getUsers(
    filterFast: 'type == "shopper"',
  );

  print('Found ${result.users.length} users');
}
// snippet.end

// snippet.get_users_filter
Future<void> getUsersFilter() async {
  var result = await pubnub.dataSync.getUsers(
    filter: 'name LIKE "*Alice*"',
  );

  print('Found ${result.users.length} users');
}
// snippet.end

// snippet.get_users_pagination
Future<void> getUsersPagination() async {
  String? cursor;

  do {
    var result = await pubnub.dataSync.getUsers(limit: 50, cursor: cursor);

    for (var user in result.users) {
      print(user.id);
    }

    cursor = result.hasNext ? result.nextCursor : null;
  } while (cursor != null);
}
// snippet.end

// snippet.create_channel_basic_usage
Future<void> createChannel() async {
  var result = await pubnub.dataSync.createChannel(ChannelInput(
    id: 'channel-summer-sale',
    classVersion: 1,
    payload: {'name': 'Summer Sale', 'type': 'promotion'},
  ));

  print('Created ${result.channel.id} with eTag ${result.channel.eTag}');
}
// snippet.end

// snippet.get_channel_basic_usage
Future<void> getChannel() async {
  var result = await pubnub.dataSync.getChannel('channel-summer-sale');

  print('Fetched ${result.channel.id}');
}
// snippet.end

// snippet.get_channels_basic_usage
Future<void> getChannels() async {
  var result = await pubnub.dataSync.getChannels();

  print('Fetched ${result.channels.length} channels');
}
// snippet.end

// snippet.set_channel_basic_usage
Future<void> setChannel() async {
  var result = await pubnub.dataSync.setChannel(
    'channel-summer-sale',
    ChannelUpdate(
      classVersion: 1,
      payload: {'name': 'Summer Sale 2026', 'type': 'promotion'},
    ),
  );

  print('Replaced channel, new eTag ${result.channel.eTag}');
}
// snippet.end

// snippet.update_channel_basic_usage
Future<void> updateChannel() async {
  var result = await pubnub.dataSync.updateChannel(
    'channel-summer-sale',
    replace: {'/payload/name': 'Summer Sale 2026'},
  );

  print('Patched channel, new eTag ${result.channel.eTag}');
}
// snippet.end

// snippet.remove_channel_basic_usage
Future<void> removeChannel() async {
  await pubnub.dataSync.removeChannel('channel-summer-sale');

  print('Removed channel-summer-sale');
}
// snippet.end

// snippet.get_channels_filter_fast
Future<void> getChannelsFilterFast() async {
  var result = await pubnub.dataSync.getChannels(
    filterFast: 'type == "promotion"',
  );

  print('Found ${result.channels.length} channels');
}
// snippet.end

// snippet.get_channels_filter
Future<void> getChannelsFilter() async {
  var result = await pubnub.dataSync.getChannels(
    filter: 'name LIKE "*Summer*"',
  );

  print('Found ${result.channels.length} channels');
}
// snippet.end

// snippet.get_channels_pagination
Future<void> getChannelsPagination() async {
  String? cursor;

  do {
    var result = await pubnub.dataSync.getChannels(limit: 50, cursor: cursor);

    for (var channel in result.channels) {
      print(channel.id);
    }

    cursor = result.hasNext ? result.nextCursor : null;
  } while (cursor != null);
}
// snippet.end

// snippet.create_membership_basic_usage
Future<void> createMembership() async {
  var result = await pubnub.dataSync.createMembership(MembershipInput(
    id: 'membership-alice-summer-sale',
    channelId: 'channel-summer-sale',
    userId: 'user-alice',
    classVersion: 1,
    payload: {'role': 'viewer'},
  ));

  print('Created ${result.membership.id} with eTag ${result.membership.eTag}');
}
// snippet.end

// snippet.get_membership_basic_usage
Future<void> getMembership() async {
  var result =
      await pubnub.dataSync.getMembership('membership-alice-summer-sale');

  print('Fetched ${result.membership.id}');
}
// snippet.end

// snippet.get_memberships_basic_usage
Future<void> getMemberships() async {
  var result = await pubnub.dataSync.getMemberships(userId: 'user-alice');

  print('Fetched ${result.memberships.length} memberships');
}
// snippet.end

// snippet.get_memberships_by_channel_id
Future<void> getMembershipsByChannelId() async {
  var result = await pubnub.dataSync.getMemberships(
    channelId: 'channel-summer-sale',
  );

  print('Found ${result.memberships.length} members');
}
// snippet.end

// snippet.set_membership_basic_usage
Future<void> setMembership() async {
  var result = await pubnub.dataSync.setMembership(
    'membership-alice-summer-sale',
    MembershipUpdate(
      classVersion: 1,
      payload: {'role': 'moderator'},
    ),
  );

  print('Replaced membership, new eTag ${result.membership.eTag}');
}
// snippet.end

// snippet.update_membership_basic_usage
Future<void> updateMembership() async {
  var result = await pubnub.dataSync.updateMembership(
    'membership-alice-summer-sale',
    replace: {'/payload/role': 'moderator'},
  );

  print('Patched membership, new eTag ${result.membership.eTag}');
}
// snippet.end

// snippet.remove_membership_basic_usage
Future<void> removeMembership() async {
  await pubnub.dataSync.removeMembership('membership-alice-summer-sale');

  print('Removed membership-alice-summer-sale');
}
// snippet.end

// snippet.get_memberships_filter_fast
Future<void> getMembershipsFilterFast() async {
  var result = await pubnub.dataSync.getMemberships(
    filterFast: 'role == "viewer"',
  );

  print('Found ${result.memberships.length} memberships');
}
// snippet.end

// snippet.get_memberships_filter
Future<void> getMembershipsFilter() async {
  var result = await pubnub.dataSync.getMemberships(
    filter: 'role LIKE "*mod*"',
  );

  print('Found ${result.memberships.length} memberships');
}
// snippet.end

// snippet.get_memberships_pagination
Future<void> getMembershipsPagination() async {
  String? cursor;

  do {
    var result = await pubnub.dataSync.getMemberships(
      userId: 'user-alice',
      limit: 50,
      cursor: cursor,
    );

    for (var membership in result.memberships) {
      print(membership.id);
    }

    cursor = result.hasNext ? result.nextCursor : null;
  } while (cursor != null);
}
// snippet.end

// snippet.create_entity_basic_usage
Future<void> createEntity() async {
  var result = await pubnub.dataSync.createEntity(EntityInput(
    id: 'product-sneaker-42',
    className: 'product',
    classVersion: 1,
    payload: {'name': 'Retro Sneaker', 'price': 89.99, 'stock': 12},
  ));

  print('Created ${result.entity.id} with eTag ${result.entity.eTag}');
}
// snippet.end

// snippet.get_entity_basic_usage
Future<void> getEntity() async {
  var result = await pubnub.dataSync.getEntity('product-sneaker-42');

  print('Fetched ${result.entity.id}');
}
// snippet.end

// snippet.get_entities_basic_usage
Future<void> getEntities() async {
  var result = await pubnub.dataSync.getEntities('product');

  print('Fetched ${result.entities.length} entities');
}
// snippet.end

// snippet.set_entity_basic_usage
Future<void> setEntity() async {
  var result = await pubnub.dataSync.setEntity(
    'product-sneaker-42',
    EntityUpdate(
      classVersion: 1,
      payload: {'name': 'Retro Sneaker', 'price': 79.99, 'stock': 8},
    ),
  );

  print('Replaced entity, new eTag ${result.entity.eTag}');
}
// snippet.end

// snippet.update_entity_basic_usage
Future<void> updateEntity() async {
  var result = await pubnub.dataSync.updateEntity(
    'product-sneaker-42',
    replace: {'/payload/price': 79.99},
  );

  print('Patched entity, new eTag ${result.entity.eTag}');
}
// snippet.end

// snippet.update_entity_multiple_operations
Future<void> updateEntityMultipleOperations() async {
  var current = await pubnub.dataSync.getEntity('product-sneaker-42');

  var result = await pubnub.dataSync.updateEntity(
    'product-sneaker-42',
    ifMatchesEtag: current.entity.eTag,
    test: {'/status': 'active'},
    add: {
      '/payload/tags': ['sale']
    },
    replace: {'/payload/price': 79.99},
    remove: ['/payload/tempFlag'],
    move: [JsonPointerPair(from: '/payload/oldTag', path: '/payload/tag')],
    copy: [JsonPointerPair(from: '/payload/price', path: '/payload/msrp')],
  );

  print('Patched entity, new eTag ${result.entity.eTag}');
}
// snippet.end

// snippet.remove_entity_basic_usage
Future<void> removeEntity() async {
  await pubnub.dataSync.removeEntity('product-sneaker-42');

  print('Removed product-sneaker-42');
}
// snippet.end

// snippet.get_entities_filter_fast
Future<void> getEntitiesFilterFast() async {
  var result = await pubnub.dataSync.getEntities(
    'product',
    filterFast: 'price < 100',
  );

  print('Found ${result.entities.length} entities');
}
// snippet.end

// snippet.get_entities_filter
Future<void> getEntitiesFilter() async {
  var result = await pubnub.dataSync.getEntities(
    'product',
    filter: 'name LIKE "*sneaker*"',
  );

  print('Found ${result.entities.length} entities');
}
// snippet.end

// snippet.get_entities_pagination
Future<void> getEntitiesPagination() async {
  String? cursor;

  do {
    var result = await pubnub.dataSync.getEntities(
      'product',
      limit: 50,
      cursor: cursor,
    );

    for (var entity in result.entities) {
      print(entity.id);
    }

    cursor = result.hasNext ? result.nextCursor : null;
  } while (cursor != null);
}
// snippet.end

// snippet.create_relationship_basic_usage
Future<void> createRelationship() async {
  var result = await pubnub.dataSync.createRelationship(RelationshipInput(
    id: 'rel-bob-owns-sneaker-42',
    entityAId: 'seller-bob',
    entityBId: 'product-sneaker-42',
    className: 'ProductOwner',
    classVersion: 1,
    payload: {'since': '2026-07-13'},
  ));

  print('Created ${result.relationship.id} '
      'with eTag ${result.relationship.eTag}');
}
// snippet.end

// snippet.get_relationship_basic_usage
Future<void> getRelationship() async {
  var result =
      await pubnub.dataSync.getRelationship('rel-bob-owns-sneaker-42');

  print('Fetched ${result.relationship.id}');
}
// snippet.end

// snippet.get_relationships_basic_usage
Future<void> getRelationships() async {
  var result = await pubnub.dataSync.getRelationships(
    'ProductOwner',
    entityAId: 'seller-bob',
  );

  print('Fetched ${result.relationships.length} relationships');
}
// snippet.end

// snippet.get_relationships_by_entity_b_id
Future<void> getRelationshipsByEntityBId() async {
  var result = await pubnub.dataSync.getRelationships(
    'ProductOwner',
    entityBId: 'product-sneaker-42',
  );

  print('Found ${result.relationships.length} relationships');
}
// snippet.end

// snippet.set_relationship_basic_usage
Future<void> setRelationship() async {
  var result = await pubnub.dataSync.setRelationship(
    'rel-bob-owns-sneaker-42',
    RelationshipUpdate(
      classVersion: 1,
      payload: {'since': '2026-07-13', 'tier': 'gold'},
    ),
  );

  print('Replaced relationship, new eTag ${result.relationship.eTag}');
}
// snippet.end

// snippet.update_relationship_basic_usage
Future<void> updateRelationship() async {
  var result = await pubnub.dataSync.updateRelationship(
    'rel-bob-owns-sneaker-42',
    replace: {'/payload/tier': 'platinum'},
  );

  print('Patched relationship, new eTag ${result.relationship.eTag}');
}
// snippet.end

// snippet.remove_relationship_basic_usage
Future<void> removeRelationship() async {
  await pubnub.dataSync.removeRelationship('rel-bob-owns-sneaker-42');

  print('Removed rel-bob-owns-sneaker-42');
}
// snippet.end

// snippet.get_relationships_filter_fast
Future<void> getRelationshipsFilterFast() async {
  var result = await pubnub.dataSync.getRelationships(
    'ProductOwner',
    filterFast: 'tier == "gold"',
  );

  print('Found ${result.relationships.length} relationships');
}
// snippet.end

// snippet.get_relationships_filter
Future<void> getRelationshipsFilter() async {
  var result = await pubnub.dataSync.getRelationships(
    'ProductOwner',
    filter: 'tier LIKE "*old"',
  );

  print('Found ${result.relationships.length} relationships');
}
// snippet.end

// snippet.get_relationships_pagination
Future<void> getRelationshipsPagination() async {
  String? cursor;

  do {
    var result = await pubnub.dataSync.getRelationships(
      'ProductOwner',
      limit: 50,
      cursor: cursor,
    );

    for (var relationship in result.relationships) {
      print(relationship.id);
    }

    cursor = result.hasNext ? result.nextCursor : null;
  } while (cursor != null);
}
// snippet.end

// snippet.data_sync_event_listener
Future<void> listenForDataSyncEvents() async {
  var subscription = pubnub.dataSyncEntity('product-sneaker-42').subscription();

  subscription.dataSync.listen((event) {
    print('${event.event.name} ${event.objectType.name} ${event.id} '
        '(class ${event.className})');
  });

  subscription.subscribe();
}
// snippet.end

// snippet.data_sync_event_switch
Future<void> listenForAllEvents() async {
  var subscription = pubnub.dataSyncUser('user-alice').subscription();

  subscription.events.listen((event) {
    switch (event) {
      case DataSyncEvent(:final event, :final objectType, :final id):
        print('${event.name} $objectType $id');
      case MessageEvent(:final message):
        print('message: $message');
      default:
    }
  });

  subscription.subscribe();
}
// snippet.end

// snippet.subscribe_to_projection_channels
Future<void> subscribeToProjectionChannels() async {
  var entity = pubnub.dataSyncEntity('product-sneaker-42');

  // Observes `product-sneaker-42`, the base projection.
  var base = entity.subscription();
  // Observes `__admin__product-sneaker-42`.
  var admin = entity.subscription(projection: 'admin');

  base.dataSync.listen((event) {
    print('base ${event.event.name} ${event.id} payload ${event.payload}');
  });
  admin.dataSync.listen((event) {
    print('admin ${event.event.name} ${event.id} payload ${event.payload}');
  });

  base.subscribe();
  admin.subscribe();
}
// snippet.end

// snippet.grant_token_data_sync
Future<void> grantTokenDataSync() async {
  var request = pubnub.requestToken(
    ttl: 60,
    authorizedUUID: 'my-authorized-uuid',
  );

  request.add(ResourceType.entity,
      name: 'product-sneaker-42',
      create: true,
      get: true,
      update: true,
      delete: true);
  request.add(ResourceType.membership,
      pattern: 'membership-.*',
      create: true,
      get: true,
      update: true,
      delete: true);
  request.add(ResourceType.user, name: 'user-bob', get: true);

  var token = await pubnub.grantToken(request);

  print('grant token = $token');
}
// snippet.end

// snippet.grant_token_data_sync_projection
Future<void> grantTokenDataSyncProjection() async {
  var request = pubnub.requestToken(
    ttl: 60,
    authorizedUUID: 'my-authorized-uuid',
  );

  request.add(ResourceType.entity,
      name: 'product-sneaker-42', create: true, get: true, update: true);
  request.addDataSyncProjection(ResourceType.entity,
      name: 'product-sneaker-42', projection: 'admin');

  var token = await pubnub.grantToken(request);

  print('grant token = $token');
}
// snippet.end

// snippet.parse_token_data_sync
void parseTokenDataSync(String tokenString) {
  var token = pubnub.parseToken(tokenString);

  for (var resource in token.resources) {
    print('${resource.type.name} ${resource.name ?? resource.pattern}: '
        'get=${resource.get} update=${resource.update}');
  }

  for (var projection in token.projections) {
    print('${projection.type.name} ${projection.name ?? projection.pattern}: '
        '${projection.projection}');
  }
}
// snippet.end
