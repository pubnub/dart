/// Represents a resource type.
///
/// {@category Access Manager}
enum ResourceType {
  channel,
  uuid,
  channelGroup,
  user,
  space,
  entity,
  relationship,
  membership
}

/// @nodoc
extension ResourceTypeExtension on ResourceType {
  String get value {
    switch (this) {
      case ResourceType.user:
        return 'users';
      case ResourceType.space:
        return 'channels';
      case ResourceType.uuid:
        return 'uuids';
      case ResourceType.channel:
        return 'channels';
      case ResourceType.channelGroup:
        return 'groups';
      case ResourceType.entity:
        return 'datasync:entities';
      case ResourceType.relationship:
        return 'datasync:relationships';
      case ResourceType.membership:
        return 'datasync:memberships';
    }
  }

  /// Whether this resource type is one of the DataSync scopes.
  ///
  /// DataSync scopes only support the CRUD permissions
  /// ([Resource.create], [Resource.get], [Resource.update] and
  /// [Resource.delete]).
  bool get isDataSync =>
      this == ResourceType.entity ||
      this == ResourceType.relationship ||
      this == ResourceType.membership;

  /// Key identifying this type within the DataSync projections payload.
  ///
  /// Projections are keyed by a `datasync:`-prefixed scope for every DataSync
  /// resource kind, including users and channels — unlike their *permissions*,
  /// which reuse the un-prefixed `users` and `channels` grant scopes.
  ///
  /// `null` for types that cannot carry a projection.
  String? get projectionScope {
    switch (this) {
      case ResourceType.entity:
        return 'datasync:entities';
      case ResourceType.relationship:
        return 'datasync:relationships';
      case ResourceType.membership:
        return 'datasync:memberships';
      case ResourceType.user:
        return 'datasync:users';
      case ResourceType.channel:
        return 'datasync:channels';
      case ResourceType.uuid:
      case ResourceType.channelGroup:
      case ResourceType.space:
        return null;
    }
  }

  /// Whether a projection can be assigned to this resource type.
  bool get supportsProjection => projectionScope != null;

  /// Key identifying this type within the grant `categories` payload.
  ///
  /// Category-level permissions apply to a resource type as a whole. Only
  /// channel and uuid metadata support them.
  ///
  /// `null` for types that cannot carry a category permission.
  String? get categoryScope {
    switch (this) {
      case ResourceType.channel:
        return 'channels';
      case ResourceType.uuid:
        return 'uuids';
      case ResourceType.channelGroup:
      case ResourceType.user:
      case ResourceType.space:
      case ResourceType.entity:
      case ResourceType.relationship:
      case ResourceType.membership:
        return null;
    }
  }

  /// Whether a category-level permission can be granted on this resource type.
  bool get supportsCategory => categoryScope != null;
}

/// Name of the base DataSync projection.
///
/// {@category Access Manager}
const String defaultProjection = '__default__';

/// @nodoc
///
/// Maps a resource type key found in a parsed token to a [ResourceType].
///
/// Returns `null` for unrecognized keys so that scopes introduced by the
/// server in the future are skipped instead of failing the whole token parse.
ResourceType? getResourceTypeFromString(String type) {
  switch (type) {
    case 'chan':
      return ResourceType.channel;
    case 'grp':
      return ResourceType.channelGroup;
    case 'uuid':
      return ResourceType.uuid;
    case 'usr':
      return ResourceType.user;
    case 'spc':
      return ResourceType.space;
    case 'datasync:entities':
      return ResourceType.entity;
    case 'datasync:relationships':
      return ResourceType.relationship;
    case 'datasync:memberships':
      return ResourceType.membership;
    default:
      return null;
  }
}

/// Represents a resource in PAM.
///
/// A resource decoded from the category-level permissions of a token
/// (`Token.categories`) has neither a [name] nor a [pattern].
///
/// {@category Access Manager}
class Resource {
  /// Type of the resource.
  ResourceType type;

  /// Name of the resource.
  String? name;

  /// Pattern to specify matching resource names
  String? pattern;

  int _bit;

  /// Readonly bitfield. Contains permissions for this resource.
  ///
  /// This is an 8-bit field. No permissions is represented by `0`.
  /// * `1`: read priviledge.
  /// * `2`: write priviledge.
  /// * `4`: manage priviledge.
  /// * `8`: delete priviledge.
  /// * `16`: create priviledge.
  /// * `32`: get priviledge.
  /// * `64`: update priviledge.
  /// * `128`: join priviledge.
  int get bit => _bit;

  bool get join => _bit & 128 == 128;
  bool get update => _bit & 64 == 64;
  bool get get => _bit & 32 == 32;
  bool get create => _bit & 16 == 16;
  bool get delete => _bit & 8 == 8;
  bool get manage => _bit & 4 == 4;
  bool get write => _bit & 2 == 2;
  bool get read => _bit & 1 == 1;

  Resource(this.type,
      {this.name,
      this.pattern,
      bool? create = false,
      bool? delete = false,
      bool? manage = false,
      bool? read = false,
      bool? write = false,
      bool? get = false,
      bool? update = false,
      bool? join = false,
      int bit = 0})
      : _bit = bit {
    if (join == true) _bit |= 128;
    if (update == true) _bit |= 64;
    if (get == true) _bit |= 32;
    if (create == true) _bit |= 16;
    if (delete == true) _bit |= 8;
    if (manage == true) _bit |= 4;
    if (write == true) _bit |= 2;
    if (read == true) _bit |= 1;
  }

  /// Returns a new `Resource` based on this one, but with some parts replaced.
  Resource replace(
          {ResourceType? type,
          String? name,
          String? pattern,
          bool? create,
          bool? delete,
          bool? manage,
          bool? read,
          bool? write,
          bool? get,
          bool? update,
          bool? join}) =>
      Resource(type ?? this.type,
          name: name ?? this.name,
          pattern: pattern ?? this.pattern,
          create: create ?? this.create,
          delete: delete ?? this.delete,
          manage: manage ?? this.manage,
          read: read ?? this.read,
          write: write ?? this.write,
          get: get ?? this.get,
          update: update ?? this.update,
          join: join ?? this.join);
}

/// Represents a DataSync projection assignment.
///
/// A projection restricts which fields of a DataSync resource are visible.
/// Projections can only be assigned to resource types that have a
/// [ResourceTypeExtension.projectionScope] — the three DataSync scopes plus
/// [ResourceType.user] and [ResourceType.channel].
///
/// Exactly one of [name] or [pattern] is set: [name] for an exact-match
/// assignment, [pattern] for one matching resources by pattern. When a resource
/// matches both, the exact-match assignment takes priority.
///
/// {@category Access Manager}
class Projection {
  /// DataSync type this projection applies to.
  final ResourceType type;

  /// Name of the resource this projection applies to.
  final String? name;

  /// Pattern matching the resources this projection applies to.
  final String? pattern;

  /// Name of the projection. [defaultProjection] refers to the base projection.
  final String projection;

  const Projection(this.type,
      {this.name, this.pattern, required this.projection});
}
