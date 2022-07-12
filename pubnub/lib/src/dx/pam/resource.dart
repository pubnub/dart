/// Represents a resource type.
///
/// {@category Access Manager}
enum ResourceType { channel, uuid, channelGroup, user, space }

/// @nodoc
extension ResourceTypeExtension on ResourceType {
  String get value {
    switch (this) {
      case ResourceType.user:
        return 'uuids';
      case ResourceType.space:
        return 'channels';
      case ResourceType.uuid:
        return 'uuids';
      case ResourceType.channel:
        return 'channels';
      case ResourceType.channelGroup:
        return 'groups';
      default:
        throw Exception('invalid state');
    }
  }
}

/// @nodoc
ResourceType getResourceTypeFromString(String type) {
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
    default:
      throw Exception('invalid resource type');
  }
}

/// Represents a resource in PAM.
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
  /// This is a 5-bit field. No permissions is represented by `00000` binary or `0` in decimal.
  /// * 1st bit: join priviledge.
  /// * 2nd bit: update priviledge.
  /// * 3rd bit: get priviledge.
  /// * 4th bit: create priviledge.
  /// * 5th bit: delete priviledge.
  /// * 6th bit: manage priviledge.
  /// * 7th bit: write priviledge.
  /// * 8th bit: read priviledge.
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
