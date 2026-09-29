import 'package:pubnub/core.dart';

/// Level at which an entity class is defined.
///
/// {@category DataSync}
enum ClassLevel { global, subKey }

/// @nodoc
extension ClassLevelExtension on ClassLevel {
  String get value => this == ClassLevel.global ? 'Global' : 'SubKey';
}

/// Writable properties used to create a DataSync entity.
///
/// {@category DataSync}
class EntityInput {
  /// Entity identifier. When omitted, the server generates one.
  String? id;

  /// Name of the entity class.
  ///
  /// Stored on the entity as `entityClass` — the name carried by responses
  /// ([EntityRecord.entityClass]) and real-time events. Immutable once the
  /// entity is created, so it cannot be patched.
  String className;

  /// Version of the entity class.
  ///
  /// Stored on the entity as `entityClassVersion` — the name carried by
  /// responses ([EntityRecord.entityClassVersion]) and real-time events. To
  /// change it later, patch `/entityClassVersion`, *not* `classVersion`.
  int classVersion;

  /// Class hierarchy level, to disambiguate classes with the same name
  /// defined at different levels.
  ///
  /// Stored as `entityClassLevel`. Immutable, so it cannot be patched.
  ClassLevel? classLevel;

  /// Entity status.
  ///
  /// To change it later, patch `/status`.
  String? status;

  /// User defined properties of the entity.
  ///
  /// To change a payload field later, pass its JSON Pointer to
  /// `updateEntity`, for example `/payload/email` or
  /// `/payload/address/city`.
  Map<String, dynamic>? payload;

  EntityInput({
    required this.className,
    required this.classVersion,
    this.id,
    this.classLevel,
    this.status,
    this.payload,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (id != null) 'id': id,
        'entityClass': className,
        'entityClassVersion': classVersion,
        if (classLevel != null) 'entityClassLevel': classLevel!.value,
        if (status != null) 'status': status,
        if (payload != null) 'payload': payload,
      };
}

/// Properties that replace an existing entity in a `setEntity` call.
///
/// The entity class is immutable and is intentionally absent here.
///
/// {@category DataSync}
class EntityUpdate {
  /// Version of the entity class.
  ///
  /// Stored on the entity as `entityClassVersion`. With `updateEntity` the
  /// same value is addressed as `/entityClassVersion`.
  int classVersion;

  /// Entity status.
  String? status;

  /// User defined properties of the entity.
  Map<String, dynamic>? payload;

  EntityUpdate({required this.classVersion, this.status, this.payload});

  Map<String, dynamic> toJson() => <String, dynamic>{
        'entityClassVersion': classVersion,
        if (status != null) 'status': status,
        if (payload != null) 'payload': payload,
      };
}

/// Represents a DataSync entity as returned by the server.
///
/// {@category Results}
/// {@category DataSync}
class EntityRecord {
  final String _id;
  final String _entityClass;
  final int _entityClassVersion;
  final String? _entityClassLevel;
  final String? _status;
  final Map<String, dynamic>? _payload;
  final String? _createdAt;
  final String? _updatedAt;
  final String? _eTag;
  final String? _expiresAt;

  /// Entity identifier.
  String get id => _id;

  /// Name of the entity class.
  String get entityClass => _entityClass;

  /// Version of the entity class.
  int get entityClassVersion => _entityClassVersion;

  /// Level at which the entity class is defined.
  String? get entityClassLevel => _entityClassLevel;

  /// Entity status.
  String? get status => _status;

  /// User defined properties of the entity.
  Map<String, dynamic>? get payload => _payload;

  /// Date and time the entity was created.
  String? get createdAt => _createdAt;

  /// Date and time the entity was last updated.
  String? get updatedAt => _updatedAt;

  /// Content fingerprint of the entity.
  ///
  /// Pass it as `ifMatchesEtag` to make a subsequent write conditional.
  String? get eTag => _eTag;

  /// Date and time when the entity expires and is removed automatically.
  String? get expiresAt => _expiresAt;

  EntityRecord._(
      this._id,
      this._entityClass,
      this._entityClassVersion,
      this._entityClassLevel,
      this._status,
      this._payload,
      this._createdAt,
      this._updatedAt,
      this._eTag,
      this._expiresAt);

  factory EntityRecord.fromJson(dynamic json) => EntityRecord._(
        _required<String>(json, 'id'),
        _required<String>(json, 'entityClass'),
        _required<int>(json, 'entityClassVersion'),
        _optional<String>(json, 'entityClassLevel'),
        _optional<String>(json, 'status'),
        _readPayload(json),
        _optional<String>(json, 'createdAt'),
        _optional<String>(json, 'updatedAt'),
        _optional<String>(json, 'eTag'),
        _optional<String>(json, 'expiresAt'),
      );
}

/// Cursor based pagination metadata of a DataSync listing.
///
/// {@category Results}
/// {@category DataSync}
class DataSyncPage {
  final String? _nextCursor;
  final bool _hasNext;
  final int? _limit;

  /// Opaque cursor of the next page.
  ///
  /// Pass it as the `cursor` argument of the next listing call.
  /// It is `null` when there are no more results.
  String? get nextCursor => _nextCursor;

  /// Whether there are more results after this page.
  bool get hasNext => _hasNext;

  /// Limit applied to this page. It may differ from the requested one.
  int? get limit => _limit;

  DataSyncPage._(this._nextCursor, this._hasNext, this._limit);

  factory DataSyncPage.fromJson(dynamic json) => DataSyncPage._(
        _optional<String>(json, 'next_cursor'),
        _optional<bool>(json, 'has_next') ?? false,
        _optional<int>(json, 'limit'),
      );
}

/// Hypermedia links of a DataSync listing.
///
/// The server sends [self] and [next], and may add further links, which are
/// available through the `[]` operator and [all].
///
/// {@category Results}
/// {@category DataSync}
class DataSyncLinks {
  final Map<String, String?> _links;

  /// Link of the current page.
  String? get self => _links['self'];

  /// Link of the next page. It is `null` on the last page.
  String? get next => _links['next'];

  /// Link named [name], `null` when the server does not send it.
  String? operator [](String name) => _links[name];

  /// All links sent by the server, keyed by name.
  Map<String, String?> get all => Map.unmodifiable(_links);

  DataSyncLinks._(this._links);

  /// @nodoc
  factory DataSyncLinks.fromJson(dynamic json) => DataSyncLinks._({
        for (var entry in (json as Map).entries)
          '${entry.key}': entry.value is String ? entry.value as String : null
      });

  /// Parses [json] when it is a map, returns `null` otherwise.
  ///
  /// @nodoc
  static DataSyncLinks? maybeFromJson(dynamic json) =>
      json is Map ? DataSyncLinks.fromJson(json) : null;
}

/// Reads a required field of a server response, throwing
/// [MalformedResponseException] when it is missing or of another type.
T _required<T>(dynamic json, String key) {
  var value = json is Map ? json[key] : null;
  if (value is T) return value;
  throw MalformedResponseException();
}

/// Reads an optional field of a server response. A value of another type is
/// treated as absent.
T? _optional<T>(dynamic json, String key) {
  var value = json is Map ? json[key] : null;
  return value is T ? value : null;
}

Map<String, dynamic>? _readPayload(dynamic json) {
  var value = json is Map ? json['payload'] : null;
  return value is Map ? Map<String, dynamic>.from(value) : null;
}

/// Reads the `data` rows of a DataSync listing, throwing
/// [MalformedResponseException] when they are not a list.
///
/// @nodoc
List<dynamic> dataSyncRows(dynamic object) {
  var data = object is Map ? object['data'] : null;
  if (data == null) return const [];
  if (data is List) return data;
  throw MalformedResponseException();
}

/// Writable properties used to create a DataSync relationship.
///
/// {@category DataSync}
class RelationshipInput {
  /// Relationship identifier. When omitted, the server generates one.
  String? id;

  /// Identifier of the first entity of the relationship.
  String entityAId;

  /// Identifier of the second entity of the relationship.
  String entityBId;

  /// Name of the relationship class.
  ///
  /// Stored on the relationship as `relationshipClass` — the name carried by
  /// responses ([RelationshipRecord.relationshipClass]) and real-time events.
  /// Immutable once the relationship is created, so it cannot be patched.
  String className;

  /// Version of the relationship class.
  ///
  /// Stored on the relationship as `relationshipClassVersion` — the name
  /// carried by responses ([RelationshipRecord.relationshipClassVersion]) and
  /// real-time events. To change it later, patch
  /// `/relationshipClassVersion`, *not* `classVersion`.
  int classVersion;

  /// Relationship status.
  ///
  /// To change it later, patch `/status`.
  String? status;

  /// User defined properties of the relationship.
  ///
  /// To change a payload field later, pass its JSON Pointer to
  /// `updateRelationship`, for example `/payload/email` or
  /// `/payload/address/city`.
  Map<String, dynamic>? payload;

  RelationshipInput({
    required this.entityAId,
    required this.entityBId,
    required this.className,
    required this.classVersion,
    this.id,
    this.status,
    this.payload,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (id != null) 'id': id,
        'entityAId': entityAId,
        'entityBId': entityBId,
        'relationshipClass': className,
        'relationshipClassVersion': classVersion,
        if (status != null) 'status': status,
        if (payload != null) 'payload': payload,
      };
}

/// Properties that replace an existing relationship in a `setRelationship`
/// call.
///
/// The two related entities and the relationship class are immutable and
/// cannot be changed.
///
/// {@category DataSync}
class RelationshipUpdate {
  /// Version of the relationship class.
  ///
  /// Stored on the relationship as `relationshipClassVersion`. With
  /// `updateRelationship` the same value is addressed as
  /// `/relationshipClassVersion`.
  int classVersion;

  /// Relationship status.
  String? status;

  /// User defined properties of the relationship.
  Map<String, dynamic>? payload;

  RelationshipUpdate({required this.classVersion, this.status, this.payload});

  Map<String, dynamic> toJson() => <String, dynamic>{
        'relationshipClassVersion': classVersion,
        if (status != null) 'status': status,
        if (payload != null) 'payload': payload,
      };
}

/// Represents a DataSync relationship as returned by the server.
///
/// {@category Results}
/// {@category DataSync}
class RelationshipRecord {
  final String _id;
  final String _entityAId;
  final String _entityBId;
  final String _relationshipClass;
  final int _relationshipClassVersion;
  final String? _status;
  final Map<String, dynamic>? _payload;
  final String? _createdAt;
  final String? _updatedAt;
  final String? _eTag;
  final String? _expiresAt;

  /// Relationship identifier.
  String get id => _id;

  /// Identifier of the first entity of the relationship.
  String get entityAId => _entityAId;

  /// Identifier of the second entity of the relationship.
  String get entityBId => _entityBId;

  /// Name of the relationship class.
  String get relationshipClass => _relationshipClass;

  /// Version of the relationship class.
  int get relationshipClassVersion => _relationshipClassVersion;

  /// Relationship status.
  String? get status => _status;

  /// User defined properties of the relationship.
  Map<String, dynamic>? get payload => _payload;

  /// Date and time the relationship was created.
  String? get createdAt => _createdAt;

  /// Date and time the relationship was last updated.
  String? get updatedAt => _updatedAt;

  /// Content fingerprint of the relationship.
  ///
  /// Pass it as `ifMatchesEtag` to make a subsequent write conditional.
  String? get eTag => _eTag;

  /// Date and time when the relationship expires and is removed automatically.
  String? get expiresAt => _expiresAt;

  RelationshipRecord._(
      this._id,
      this._entityAId,
      this._entityBId,
      this._relationshipClass,
      this._relationshipClassVersion,
      this._status,
      this._payload,
      this._createdAt,
      this._updatedAt,
      this._eTag,
      this._expiresAt);

  factory RelationshipRecord.fromJson(dynamic json) => RelationshipRecord._(
        _required<String>(json, 'id'),
        _required<String>(json, 'entityAId'),
        _required<String>(json, 'entityBId'),
        _required<String>(json, 'relationshipClass'),
        _required<int>(json, 'relationshipClassVersion'),
        _optional<String>(json, 'status'),
        _readPayload(json),
        _optional<String>(json, 'createdAt'),
        _optional<String>(json, 'updatedAt'),
        _optional<String>(json, 'eTag'),
        _optional<String>(json, 'expiresAt'),
      );
}

/// Writable properties used to create a DataSync user.
///
/// A user is a specialized entity of the `User` class or one of its
/// subclasses.
///
/// {@category DataSync}
class UserInput {
  /// User identifier. When omitted, the server generates one.
  String? id;

  /// Version of the entity class.
  ///
  /// Stored on the user as `entityClassVersion` — the name carried by
  /// responses ([UserRecord.entityClassVersion]) and real-time events. To
  /// change it later, patch `/entityClassVersion`, *not* `classVersion`.
  int classVersion;

  /// Name of the entity class. When omitted, the server uses `User`.
  ///
  /// It has to be `User` or one of its subclasses. Stored on the user as
  /// `entityClass` — the name carried by responses ([UserRecord.entityClass])
  /// and real-time events. Immutable once the user is created, so it cannot
  /// be patched.
  String? className;

  /// Class hierarchy level, to disambiguate classes with the same name
  /// defined at different levels.
  ///
  /// Stored as `entityClassLevel`. Immutable, so it cannot be patched.
  ClassLevel? classLevel;

  /// User status.
  ///
  /// To change it later, patch `/status`.
  String? status;

  /// User defined properties of the user.
  ///
  /// To change a payload field later, pass its JSON Pointer to
  /// `updateUser`, for example `/payload/email` or
  /// `/payload/address/city`.
  Map<String, dynamic>? payload;

  UserInput({
    required this.classVersion,
    this.id,
    this.className,
    this.classLevel,
    this.status,
    this.payload,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (id != null) 'id': id,
        if (className != null) 'entityClass': className,
        'entityClassVersion': classVersion,
        if (classLevel != null) 'entityClassLevel': classLevel!.value,
        if (status != null) 'status': status,
        if (payload != null) 'payload': payload,
      };
}

/// Properties that replace an existing user in a `setUser` call.
///
/// The entity class is immutable and is intentionally absent here.
///
/// {@category DataSync}
class UserUpdate {
  /// Version of the entity class.
  ///
  /// Stored on the user as `entityClassVersion`. With `updateUser` the same
  /// value is addressed as `/entityClassVersion`.
  int classVersion;

  /// User status.
  String? status;

  /// User defined properties of the user.
  Map<String, dynamic>? payload;

  UserUpdate({required this.classVersion, this.status, this.payload});

  Map<String, dynamic> toJson() => <String, dynamic>{
        'entityClassVersion': classVersion,
        if (status != null) 'status': status,
        if (payload != null) 'payload': payload,
      };
}

/// Represents a DataSync user as returned by the server.
///
/// {@category Results}
/// {@category DataSync}
class UserRecord {
  final String _id;
  final String _entityClass;
  final int _entityClassVersion;
  final String? _entityClassLevel;
  final String? _status;
  final Map<String, dynamic>? _payload;
  final String? _createdAt;
  final String? _updatedAt;
  final String? _eTag;
  final String? _expiresAt;

  /// User identifier.
  String get id => _id;

  /// Name of the entity class.
  String get entityClass => _entityClass;

  /// Version of the entity class.
  int get entityClassVersion => _entityClassVersion;

  /// Level at which the entity class is defined.
  String? get entityClassLevel => _entityClassLevel;

  /// User status.
  String? get status => _status;

  /// User defined properties of the user.
  Map<String, dynamic>? get payload => _payload;

  /// Date and time the user was created.
  String? get createdAt => _createdAt;

  /// Date and time the user was last updated.
  String? get updatedAt => _updatedAt;

  /// Content fingerprint of the user.
  ///
  /// Pass it as `ifMatchesEtag` to make a subsequent write conditional.
  String? get eTag => _eTag;

  /// Date and time when the user expires and is removed automatically.
  String? get expiresAt => _expiresAt;

  UserRecord._(
      this._id,
      this._entityClass,
      this._entityClassVersion,
      this._entityClassLevel,
      this._status,
      this._payload,
      this._createdAt,
      this._updatedAt,
      this._eTag,
      this._expiresAt);

  factory UserRecord.fromJson(dynamic json) => UserRecord._(
        _required<String>(json, 'id'),
        _required<String>(json, 'entityClass'),
        _required<int>(json, 'entityClassVersion'),
        _optional<String>(json, 'entityClassLevel'),
        _optional<String>(json, 'status'),
        _readPayload(json),
        _optional<String>(json, 'createdAt'),
        _optional<String>(json, 'updatedAt'),
        _optional<String>(json, 'eTag'),
        _optional<String>(json, 'expiresAt'),
      );
}

/// Writable properties used to create a DataSync channel.
///
/// A channel is a specialized entity of the `Channel` class or one of its
/// subclasses.
///
/// {@category DataSync}
class ChannelInput {
  /// Channel identifier. When omitted, the server generates one.
  String? id;

  /// Version of the entity class.
  ///
  /// Stored on the channel as `entityClassVersion` — the name carried by
  /// responses ([ChannelRecord.entityClassVersion]) and real-time events. To
  /// change it later, patch `/entityClassVersion`, *not* `classVersion`.
  int classVersion;

  /// Name of the entity class. When omitted, the server uses `Channel`.
  ///
  /// It has to be `Channel` or one of its subclasses. Stored on the channel
  /// as `entityClass` — the name carried by responses
  /// ([ChannelRecord.entityClass]) and real-time events. Immutable once the
  /// channel is created, so it cannot be patched.
  String? className;

  /// Class hierarchy level, to disambiguate classes with the same name
  /// defined at different levels.
  ///
  /// Stored as `entityClassLevel`. Immutable, so it cannot be patched.
  ClassLevel? classLevel;

  /// Channel status.
  ///
  /// To change it later, patch `/status`.
  String? status;

  /// User defined properties of the channel.
  ///
  /// To change a payload field later, pass its JSON Pointer to
  /// `updateChannel`, for example `/payload/email` or
  /// `/payload/address/city`.
  Map<String, dynamic>? payload;

  ChannelInput({
    required this.classVersion,
    this.id,
    this.className,
    this.classLevel,
    this.status,
    this.payload,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (id != null) 'id': id,
        if (className != null) 'entityClass': className,
        'entityClassVersion': classVersion,
        if (classLevel != null) 'entityClassLevel': classLevel!.value,
        if (status != null) 'status': status,
        if (payload != null) 'payload': payload,
      };
}

/// Properties that replace an existing channel in a `setChannel` call.
///
/// The entity class is immutable and is intentionally absent here.
///
/// {@category DataSync}
class ChannelUpdate {
  /// Version of the entity class.
  ///
  /// Stored on the channel as `entityClassVersion`. With `updateChannel` the
  /// same value is addressed as `/entityClassVersion`.
  int classVersion;

  /// Channel status.
  String? status;

  /// User defined properties of the channel.
  Map<String, dynamic>? payload;

  ChannelUpdate({required this.classVersion, this.status, this.payload});

  Map<String, dynamic> toJson() => <String, dynamic>{
        'entityClassVersion': classVersion,
        if (status != null) 'status': status,
        if (payload != null) 'payload': payload,
      };
}

/// Represents a DataSync channel as returned by the server.
///
/// {@category Results}
/// {@category DataSync}
class ChannelRecord {
  final String _id;
  final String _entityClass;
  final int _entityClassVersion;
  final String? _entityClassLevel;
  final String? _status;
  final Map<String, dynamic>? _payload;
  final String? _createdAt;
  final String? _updatedAt;
  final String? _eTag;
  final String? _expiresAt;

  /// Channel identifier.
  String get id => _id;

  /// Name of the entity class.
  String get entityClass => _entityClass;

  /// Version of the entity class.
  int get entityClassVersion => _entityClassVersion;

  /// Level at which the entity class is defined.
  String? get entityClassLevel => _entityClassLevel;

  /// Channel status.
  String? get status => _status;

  /// User defined properties of the channel.
  Map<String, dynamic>? get payload => _payload;

  /// Date and time the channel was created.
  String? get createdAt => _createdAt;

  /// Date and time the channel was last updated.
  String? get updatedAt => _updatedAt;

  /// Content fingerprint of the channel.
  ///
  /// Pass it as `ifMatchesEtag` to make a subsequent write conditional.
  String? get eTag => _eTag;

  /// Date and time when the channel expires and is removed automatically.
  String? get expiresAt => _expiresAt;

  ChannelRecord._(
      this._id,
      this._entityClass,
      this._entityClassVersion,
      this._entityClassLevel,
      this._status,
      this._payload,
      this._createdAt,
      this._updatedAt,
      this._eTag,
      this._expiresAt);

  factory ChannelRecord.fromJson(dynamic json) => ChannelRecord._(
        _required<String>(json, 'id'),
        _required<String>(json, 'entityClass'),
        _required<int>(json, 'entityClassVersion'),
        _optional<String>(json, 'entityClassLevel'),
        _optional<String>(json, 'status'),
        _readPayload(json),
        _optional<String>(json, 'createdAt'),
        _optional<String>(json, 'updatedAt'),
        _optional<String>(json, 'eTag'),
        _optional<String>(json, 'expiresAt'),
      );
}

/// Writable properties used to create a DataSync membership.
///
/// A membership is a specialized relationship of the `Membership` class
/// between a channel and a user.
///
/// {@category DataSync}
class MembershipInput {
  /// Membership identifier. When omitted, the server generates one.
  String? id;

  /// Identifier of the channel of the membership.
  ///
  /// The channel has to exist already. Immutable once the membership is
  /// created, so it cannot be patched.
  String channelId;

  /// Identifier of the user of the membership.
  ///
  /// The user has to exist already. Immutable once the membership is created,
  /// so it cannot be patched.
  String userId;

  /// Version of the `Membership` relationship class.
  ///
  /// Stored on the membership as `relationshipClassVersion` — the name
  /// carried by responses ([MembershipRecord.relationshipClassVersion]) and
  /// real-time events. To change it later, patch
  /// `/relationshipClassVersion`, *not* `classVersion`.
  int classVersion;

  /// Membership status.
  ///
  /// To change it later, patch `/status`.
  String? status;

  /// User defined properties of the membership.
  ///
  /// To change a payload field later, pass its JSON Pointer to
  /// `updateMembership`, for example `/payload/email` or
  /// `/payload/address/city`.
  Map<String, dynamic>? payload;

  MembershipInput({
    required this.channelId,
    required this.userId,
    required this.classVersion,
    this.id,
    this.status,
    this.payload,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (id != null) 'id': id,
        'channelId': channelId,
        'userId': userId,
        'relationshipClassVersion': classVersion,
        if (status != null) 'status': status,
        if (payload != null) 'payload': payload,
      };
}

/// Properties that replace an existing membership in a `setMembership` call.
///
/// The channel, the user and the relationship class are immutable and cannot
/// be changed.
///
/// {@category DataSync}
class MembershipUpdate {
  /// Version of the `Membership` relationship class.
  ///
  /// Stored on the membership as `relationshipClassVersion`. With
  /// `updateMembership` the same value is addressed as
  /// `/relationshipClassVersion`.
  int classVersion;

  /// Membership status.
  String? status;

  /// User defined properties of the membership.
  Map<String, dynamic>? payload;

  MembershipUpdate({required this.classVersion, this.status, this.payload});

  Map<String, dynamic> toJson() => <String, dynamic>{
        'relationshipClassVersion': classVersion,
        if (status != null) 'status': status,
        if (payload != null) 'payload': payload,
      };
}

/// Represents a DataSync membership as returned by the server.
///
/// {@category Results}
/// {@category DataSync}
class MembershipRecord {
  final String _id;
  final String _channelId;
  final String _userId;
  final String _relationshipClass;
  final int _relationshipClassVersion;
  final String? _status;
  final Map<String, dynamic>? _payload;
  final String? _createdAt;
  final String? _updatedAt;
  final String? _eTag;
  final String? _expiresAt;

  /// Membership identifier.
  String get id => _id;

  /// Identifier of the channel of the membership.
  String get channelId => _channelId;

  /// Identifier of the user of the membership.
  String get userId => _userId;

  /// Name of the relationship class.
  String get relationshipClass => _relationshipClass;

  /// Version of the relationship class.
  int get relationshipClassVersion => _relationshipClassVersion;

  /// Membership status.
  String? get status => _status;

  /// User defined properties of the membership.
  Map<String, dynamic>? get payload => _payload;

  /// Date and time the membership was created.
  String? get createdAt => _createdAt;

  /// Date and time the membership was last updated.
  String? get updatedAt => _updatedAt;

  /// Content fingerprint of the membership.
  ///
  /// Pass it as `ifMatchesEtag` to make a subsequent write conditional.
  String? get eTag => _eTag;

  /// Date and time when the membership expires and is removed automatically.
  String? get expiresAt => _expiresAt;

  MembershipRecord._(
      this._id,
      this._channelId,
      this._userId,
      this._relationshipClass,
      this._relationshipClassVersion,
      this._status,
      this._payload,
      this._createdAt,
      this._updatedAt,
      this._eTag,
      this._expiresAt);

  factory MembershipRecord.fromJson(dynamic json) => MembershipRecord._(
        _required<String>(json, 'id'),
        _required<String>(json, 'channelId'),
        _required<String>(json, 'userId'),
        _required<String>(json, 'relationshipClass'),
        _required<int>(json, 'relationshipClassVersion'),
        _optional<String>(json, 'status'),
        _readPayload(json),
        _optional<String>(json, 'createdAt'),
        _optional<String>(json, 'updatedAt'),
        _optional<String>(json, 'eTag'),
        _optional<String>(json, 'expiresAt'),
      );
}

/// A pair of RFC 6901 JSON Pointers used by the `move` and `copy` operations
/// of a DataSync update.
///
/// Both pointers start with `/` and are sent verbatim, for example
/// `JsonPointerPair(from: '/payload/legacyName', path: '/payload/name')`.
///
/// {@category DataSync}
class JsonPointerPair {
  /// Pointer of the property to move or copy.
  final String from;

  /// Pointer of the destination property.
  final String path;

  const JsonPointerPair({required this.from, required this.path});
}

/// Builds an RFC 6902 JSON Patch document out of the `add` / `replace` /
/// `remove` / `move` / `copy` / `test` arguments of the update methods.
///
/// Operations are emitted in that fixed order, and in insertion order within
/// each group. Paths are RFC 6901 JSON Pointers and are passed through
/// verbatim.
///
/// @nodoc
List<Map<String, dynamic>> buildJsonPatch({
  Map<String, dynamic>? add,
  Map<String, dynamic>? replace,
  List<String>? remove,
  List<JsonPointerPair>? move,
  List<JsonPointerPair>? copy,
  Map<String, dynamic>? test,
}) =>
    [
      ...?add?.entries.map(
          (entry) => {'op': 'add', 'path': entry.key, 'value': entry.value}),
      ...?replace?.entries.map((entry) =>
          {'op': 'replace', 'path': entry.key, 'value': entry.value}),
      ...?remove?.map((path) => {'op': 'remove', 'path': path}),
      ...?move
          ?.map((pair) => {'op': 'move', 'from': pair.from, 'path': pair.path}),
      ...?copy
          ?.map((pair) => {'op': 'copy', 'from': pair.from, 'path': pair.path}),
      ...?test?.entries.map(
          (entry) => {'op': 'test', 'path': entry.key, 'value': entry.value}),
    ];
