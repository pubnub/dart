/// Represents a resource type.
///
/// {@category Access Manager}
enum ResourceType { space, user, channel, channelGroup }

/// @nodoc
extension ResourceTypeExtension on ResourceType {
  String get value {
    switch (this) {
      case ResourceType.user:
        return 'users';
      case ResourceType.space:
        return 'spaces';
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
  ///
  /// It can either be a `String` or a `RegExp`.
  Pattern name;

  int _bit;

  /// Readonly bitfield. Contains permissions for this resource.
  ///
  /// This is a 5-bit field. No permissions is represented by `00000` binary or `0` in decimal.
  /// * 1st bit: create priviledge.
  /// * 2nd bit: delete priviledge.
  /// * 3rd bit: manage priviledge.
  /// * 4th bit: write priviledge.
  /// * 5th bit: read priviledge.
  int get bit => _bit;

  bool get create => _bit & 16 == 16;
  bool get delete => _bit & 8 == 8;
  bool get manage => _bit & 4 == 4;
  bool get write => _bit & 2 == 2;
  bool get read => _bit & 1 == 1;

  Resource(this.type, this.name,
      {bool create = false,
      bool delete = false,
      bool manage = false,
      bool read = false,
      bool write = false,
      int bit = 0}) {
    _bit = bit;
    if (create == true) _bit |= 16;
    if (delete == true) _bit |= 8;
    if (manage == true) _bit |= 4;
    if (write == true) _bit |= 2;
    if (read == true) _bit |= 1;
  }

  /// Returns a new `Resource` based on this one, but with some parts replaced.
  Resource replace(
          {ResourceType type,
          Pattern name,
          bool create,
          bool delete,
          bool manage,
          bool read,
          bool write}) =>
      Resource(type ?? this.type, name ?? this.name,
          create: create ?? this.create,
          delete: delete ?? this.delete,
          manage: manage ?? this.manage,
          read: read ?? this.read,
          write: write ?? this.write);
}
