import 'package:pubnub/core.dart';

import '../dx/_endpoints/message_action.dart' show MessageAction;
import '../dx/_endpoints/objects/channel_metadata.dart'
    show ChannelMetadataDetails;
import '../dx/_endpoints/objects/uuid_metadata.dart' show UuidMetadataDetails;
import '../dx/files/file_url.dart';
import '../dx/files/schema.dart' show FileInfo;
import 'envelope.dart';

const _presenceSuffix = '-pnpres';

String _stripPresenceSuffix(String name) => name.endsWith(_presenceSuffix)
    ? name.substring(0, name.length - _presenceSuffix.length)
    : name;

/// Represents an event received from a subscription.
///
/// Each kind of event has its own subtype, so the events can be handled with
/// an exhaustive `switch`:
///
/// ```dart
/// subscription.events.listen((event) {
///   switch (event) {
///     case MessageEvent():
///     case SignalEvent():
///     case MessageActionEvent():
///     case FileEvent():
///     case ObjectsEvent():
///     case DataSyncEvent():
///     case PresenceEvent():
///   }
/// });
/// ```
///
/// {@category Results}
/// {@category Basic Features}
sealed class SubscriptionEvent {
  /// Raw envelope this event has been created from.
  Envelope get envelope;

  /// Channel on which this event has been received.
  String get channel => envelope.channel;

  /// Wildcard channel or channel group through which this event has been
  /// received, if any.
  String? get subscription => envelope.subscriptionPattern;

  /// Timetoken at which the server accepted this event.
  Timetoken get timetoken => envelope.publishedAt;

  /// Creates a typed event from [envelope] received using [keyset].
  ///
  /// Returns `null` when the type of the event is not recognized by the SDK
  /// or its payload has an unexpected shape. Such events should be discarded.
  ///
  /// @nodoc
  static SubscriptionEvent? fromEnvelope(Envelope envelope, Keyset keyset,
      {Uri? origin}) {
    try {
      if (envelope.channel.endsWith(_presenceSuffix)) {
        return PresenceEvent.fromEnvelope(envelope);
      }

      switch (envelope.messageType) {
        case MessageType.normal:
          return MessageEvent._(envelope);
        case MessageType.signal:
          return SignalEvent._(envelope);
        case MessageType.objects:
          return ObjectsEvent._fromEnvelope(envelope);
        case MessageType.messageAction:
          return MessageActionEvent._fromEnvelope(envelope);
        case MessageType.file:
          return FileEvent._fromEnvelope(envelope, keyset, origin);
        case MessageType.dataSync:
          // A payload that is not marked as DataSync is an ordinary message.
          if (!DataSyncEvent._isDataSyncPayload(envelope.payload)) {
            return MessageEvent._(envelope);
          }
          return DataSyncEvent._fromEnvelope(envelope);
        case MessageType.unknown:
          return null;
      }
    } catch (_) {
      return null;
    }
  }
}

/// Represents a message published to a channel.
///
/// {@category Results}
/// {@category Basic Features}
final class MessageEvent extends SubscriptionEvent {
  @override
  final Envelope envelope;

  MessageEvent._(this.envelope);

  /// Content of the message.
  dynamic get message => envelope.payload;

  /// UUID of the publisher.
  UUID get publisher => envelope.uuid;

  /// Metadata attached to the message by the publisher.
  dynamic get userMeta => envelope.userMeta;

  /// Custom message type attached to the message by the publisher.
  String? get customMessageType => envelope.customMessageType;

  /// If message decryption failed, then contains the exception.
  PubNubException? get error => envelope.error;
}

/// Represents a signal sent to a channel.
///
/// {@category Results}
/// {@category Basic Features}
final class SignalEvent extends SubscriptionEvent {
  @override
  final Envelope envelope;

  SignalEvent._(this.envelope);

  /// Content of the signal.
  dynamic get message => envelope.payload;

  /// UUID of the sender.
  UUID get publisher => envelope.uuid;

  /// Custom message type attached to the signal by the sender.
  String? get customMessageType => envelope.customMessageType;
}

/// Represents the kind of change to a message action.
enum MessageActionEventType {
  added,
  removed,

  /// Represents a message action event that is unrecognized by the SDK
  unknown,
}

MessageActionEventType _messageActionEventTypeFromString(String? event) {
  switch (event) {
    case 'added':
      return MessageActionEventType.added;
    case 'removed':
      return MessageActionEventType.removed;
    default:
      return MessageActionEventType.unknown;
  }
}

/// Represents a message action being added to or removed from a message.
///
/// {@category Results}
/// {@category Basic Features}
final class MessageActionEvent extends SubscriptionEvent {
  @override
  final Envelope envelope;

  /// Whether the message action has been added or removed.
  final MessageActionEventType event;

  /// The message action. [MessageAction.uuid] is the user who added or
  /// removed it.
  final MessageAction action;

  MessageActionEvent._(this.envelope, this.event, this.action);

  factory MessageActionEvent._fromEnvelope(Envelope envelope) {
    var payload = envelope.payload as Map<String, dynamic>;
    return MessageActionEvent._(
        envelope,
        _messageActionEventTypeFromString(payload['event'] as String?),
        MessageAction.fromJson(<String, dynamic>{
          ...payload['data'] as Map<String, dynamic>,
          'uuid': envelope.uuid.value,
        }));
  }

  /// Timetoken of the message the action belongs to.
  Timetoken get messageTimetoken =>
      Timetoken(BigInt.parse(action.messageTimetoken));

  /// Timetoken of the message action.
  Timetoken get actionTimetoken =>
      Timetoken(BigInt.parse(action.actionTimetoken));
}

/// Represents a file shared on a channel.
///
/// {@category Results}
/// {@category Files}
final class FileEvent extends SubscriptionEvent {
  @override
  final Envelope envelope;

  final Keyset _keyset;
  final Uri? _origin;

  /// Shared file. It is `null` only when [error] is not `null`.
  final FileInfo? file;

  /// Message published along with the file.
  final dynamic message;

  FileEvent._(
      this.envelope, this._keyset, this.file, this.message, this._origin);

  factory FileEvent._fromEnvelope(
      Envelope envelope, Keyset keyset, Uri? origin) {
    if (envelope.error != null) {
      return FileEvent._(envelope, keyset, null, null, origin);
    }

    var payload = envelope.payload as Map<String, dynamic>;
    var file = payload['file'] as Map<String, dynamic>;
    return FileEvent._(
        envelope,
        keyset,
        FileInfo(file['id'] as String, file['name'] as String),
        payload['message'],
        origin);
  }

  /// Uri to download the [file].
  ///
  /// It is computed on every access, so it is signed with a fresh timestamp
  /// when the keyset has a `secretKey`. The host is the subscription's
  /// networking origin, or `ps.pndsn.com` when none is set. Returns `null`
  /// when [file] is `null`.
  Uri? get url => file != null
      ? buildFileUrl(_keyset, channel, file!.id, file!.name, origin: _origin)
      : null;

  /// UUID of the publisher.
  UUID get publisher => envelope.uuid;

  /// Metadata attached to the file message by the publisher.
  dynamic get userMeta => envelope.userMeta;

  /// Custom message type attached to the file message by the publisher.
  String? get customMessageType => envelope.customMessageType;

  /// If file message decryption failed, then contains the exception.
  PubNubException? get error => envelope.error;
}

/// Represents the kind of change to an App Context object.
enum ObjectsEventType {
  set,
  delete,

  /// Represents an objects event that is unrecognized by the SDK
  unknown,
}

ObjectsEventType _objectsEventTypeFromString(String? event) {
  switch (event) {
    case 'set':
      return ObjectsEventType.set;
    case 'delete':
      return ObjectsEventType.delete;
    default:
      return ObjectsEventType.unknown;
  }
}

/// Represents a change to an App Context object.
///
/// {@category Results}
/// {@category Objects}
sealed class ObjectsEvent extends SubscriptionEvent {
  @override
  final Envelope envelope;

  /// Whether the object has been set or deleted.
  final ObjectsEventType event;

  ObjectsEvent._(this.envelope, this.event);

  static ObjectsEvent? _fromEnvelope(Envelope envelope) {
    var payload = envelope.payload as Map<String, dynamic>;
    var event = _objectsEventTypeFromString(payload['event'] as String?);
    var data = payload['data'] as Map<String, dynamic>;

    switch (payload['type']) {
      case 'uuid':
        return UuidMetadataEvent._(
            envelope, event, UuidMetadataDetails.fromJson(data));
      case 'channel':
        return ChannelMetadataEvent._(
            envelope, event, ChannelMetadataDetails.fromJson(data));
      case 'membership':
        return MembershipMetadataEvent._(envelope, event, data);
      default:
        return null;
    }
  }
}

/// Represents a change to UUID metadata.
///
/// {@category Results}
/// {@category Objects}
final class UuidMetadataEvent extends ObjectsEvent {
  /// UUID metadata. When [event] is [ObjectsEventType.delete], only
  /// [UuidMetadataDetails.id] is set.
  final UuidMetadataDetails metadata;

  UuidMetadataEvent._(Envelope envelope, ObjectsEventType event, this.metadata)
      : super._(envelope, event);
}

/// Represents a change to channel metadata.
///
/// {@category Results}
/// {@category Objects}
final class ChannelMetadataEvent extends ObjectsEvent {
  /// Channel metadata. When [event] is [ObjectsEventType.delete], only
  /// [ChannelMetadataDetails.id] is set.
  final ChannelMetadataDetails metadata;

  ChannelMetadataEvent._(
      Envelope envelope, ObjectsEventType event, this.metadata)
      : super._(envelope, event);
}

/// Represents a change to a membership of a UUID in a channel.
///
/// {@category Results}
/// {@category Objects}
final class MembershipMetadataEvent extends ObjectsEvent {
  /// Id of the channel of the membership.
  final String channelId;

  /// UUID of the member.
  final String uuid;

  /// Custom data of the membership.
  final Map<String, dynamic>? custom;

  /// Status of the membership.
  final String? status;

  /// Type of the membership.
  final String? type;

  /// Date and time the membership was last updated.
  final String? updated;

  /// Content fingerprint of the membership.
  final String? eTag;

  MembershipMetadataEvent._(
      Envelope envelope, ObjectsEventType event, Map<String, dynamic> data)
      : channelId = data['channel']['id'] as String,
        uuid = data['uuid']['id'] as String,
        custom = data['custom'] as Map<String, dynamic>?,
        status = data['status'] as String?,
        type = data['type'] as String?,
        updated = data['updated'] as String?,
        eTag = data['eTag'] as String?,
        super._(envelope, event);
}

/// Represents the kind of change to a DataSync object.
enum DataSyncEventType {
  create,
  update,
  delete,

  /// Represents a DataSync event that is unrecognized by the SDK
  unknown,
}

DataSyncEventType _dataSyncEventTypeFromString(String? event) {
  switch (event) {
    case 'create':
      return DataSyncEventType.create;
    case 'update':
      return DataSyncEventType.update;
    case 'delete':
      return DataSyncEventType.delete;
    default:
      return DataSyncEventType.unknown;
  }
}

/// Represents the kind of DataSync object that has changed.
enum DataSyncObjectType { entity, relationship, user, channel, membership }

DataSyncObjectType? _dataSyncObjectTypeFromString(String? type) {
  switch (type) {
    case 'entity':
      return DataSyncObjectType.entity;
    case 'relationship':
      return DataSyncObjectType.relationship;
    case 'user':
      return DataSyncObjectType.user;
    case 'channel':
      return DataSyncObjectType.channel;
    case 'membership':
      return DataSyncObjectType.membership;
    default:
      return null;
  }
}

/// Represents a change to a DataSync entity, relationship, user, channel or
/// membership.
///
/// When [event] is [DataSyncEventType.delete], only [id] and [deletedAt] are
/// set on the object.
///
/// {@category Results}
/// {@category DataSync}
final class DataSyncEvent extends SubscriptionEvent {
  @override
  final Envelope envelope;

  /// Whether the object has been created, updated or deleted.
  final DataSyncEventType event;

  /// Kind of the object that has changed.
  final DataSyncObjectType objectType;

  /// Name of the class of the object.
  final String? className;

  /// Version of the class of the object.
  final int? classVersion;

  /// Level at which the class of the object is defined.
  final String? classLevel;

  /// Service that emitted the event.
  final String? source;

  /// Version of the event format.
  final String? version;

  /// Raw object data as received from the server.
  final Map<String, dynamic> data;

  DataSyncEvent._(this.envelope, this.event, this.objectType, this.className,
      this.classVersion, this.classLevel, this.source, this.version, this.data);

  /// Whether [payload] carries the DataSync event metadata.
  static bool _isDataSyncPayload(dynamic payload) {
    if (payload is! Map) return false;

    var metadata = payload['metadata'];
    if (metadata is! Map) return false;

    bool isSet(dynamic value) => value is String && value.isNotEmpty;

    return metadata['source'] == _dataSyncSource &&
        isSet(metadata['event']) &&
        isSet(metadata['type']);
  }

  static DataSyncEvent? _fromEnvelope(Envelope envelope) {
    var payload = envelope.payload as Map;
    var metadata = payload['metadata'] as Map;

    var data = payload['data'];
    if (data is! Map || data['id'] is! String) {
      return null;
    }

    var classLevel = _stringOrNull(metadata['classLevel']);

    // The retired positional form of the class name (`User::`, `::Lion`) is
    // still tolerated: the name is its last non-empty segment.
    var rawClassName = _stringOrNull(metadata['className']);
    var classSegments = rawClassName?.split(':') ?? const <String>[];
    var namedSegments = classSegments.where((segment) => segment.isNotEmpty);
    var className = namedSegments.isNotEmpty ? namedSegments.last : null;

    // Built-in classes are defined at the `Global` level. Without a level, the
    // first segment of the positional form names the built-in class.
    var systemClass = classLevel == null
        ? (classSegments.isNotEmpty ? classSegments.first : null)
        : classLevel == _globalClassLevel
            ? className
            : null;

    var type = _stringOrNull(metadata['type']);
    var objectType = _dataSyncObjectTypeFromString(type);
    if (objectType == null) {
      return null;
    }

    // The service may report a built-in class with the generic kind, for
    // example a `User` as an `entity`.
    if (objectType == DataSyncObjectType.entity ||
        objectType == DataSyncObjectType.relationship) {
      objectType =
          _reservedDataSyncClasses[systemClass?.toLowerCase()] ?? objectType;
    }

    return DataSyncEvent._(
        envelope,
        _dataSyncEventTypeFromString(_stringOrNull(metadata['event'])),
        objectType,
        className,
        _classVersionFromJson(metadata['classVersion']),
        classLevel,
        _stringOrNull(metadata['source']),
        _stringOrNull(payload['version']),
        Map<String, dynamic>.from(data));
  }

  static const _dataSyncSource = 'data-sync';
  static const _globalClassLevel = 'Global';
  static const _reservedDataSyncClasses = {
    'user': DataSyncObjectType.user,
    'channel': DataSyncObjectType.channel,
    'membership': DataSyncObjectType.membership,
  };

  static String? _stringOrNull(dynamic value) => value is String ? value : null;

  /// Parses the class version, which is `null` when it is not a number.
  static int? _classVersionFromJson(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  /// Identifier of the object.
  String get id => data['id'] as String;

  /// Status of the object.
  String? get status => data['status'] as String?;

  /// User defined properties of the object.
  Map<String, dynamic>? get payload => data['payload'] as Map<String, dynamic>?;

  /// Content fingerprint of the object.
  String? get eTag => data['eTag'] as String?;

  /// Date and time the object was created.
  String? get createdAt => data['createdAt'] as String?;

  /// Date and time the object was last updated.
  String? get updatedAt => data['updatedAt'] as String?;

  /// Date and time when the object expires and is removed automatically.
  String? get expiresAt => data['expiresAt'] as String?;

  /// Date and time the object was deleted.
  String? get deletedAt => data['deletedAt'] as String?;

  /// Identifier of the channel of a membership.
  String? get channelId => data['channelId'] as String?;

  /// Identifier of the user of a membership.
  String? get userId => data['userId'] as String?;

  /// Identifier of the first entity of a relationship.
  String? get entityAId => data['entityAId'] as String?;

  /// Identifier of the second entity of a relationship.
  String? get entityBId => data['entityBId'] as String?;
}

/// Represents a presence action.
enum PresenceAction {
  join,
  leave,
  timeout,
  stateChange,
  interval,

  /// Represents a presence action that is unrecognized by the SDK
  unknown,
}

/// @nodoc
extension PresenceActionExtension on PresenceAction {
  static PresenceAction fromString(String? action) {
    switch (action) {
      case 'join':
        return PresenceAction.join;
      case 'leave':
        return PresenceAction.leave;
      case 'timeout':
        return PresenceAction.timeout;
      case 'state-change':
        return PresenceAction.stateChange;
      case 'interval':
        return PresenceAction.interval;
      default:
        return PresenceAction.unknown;
    }
  }
}

List<UUID> _uuids(dynamic list) => (list as List<dynamic>? ?? [])
    .cast<String>()
    .map((uuid) => UUID(uuid))
    .toList();

/// Represents an event in presence.
///
/// {@category Results}
final class PresenceEvent extends SubscriptionEvent {
  @override
  Envelope envelope;

  PresenceAction action;
  UUID? uuid;
  int occupancy;

  /// Channel on which the presence event happened.
  @override
  String get channel => _stripPresenceSuffix(envelope.channel);

  /// Wildcard channel or channel group through which this event has been
  /// received, if any.
  @override
  String? get subscription => envelope.subscriptionPattern != null
      ? _stripPresenceSuffix(envelope.subscriptionPattern!)
      : null;

  /// UUIDs that joined since the previous interval event.
  List<UUID> get join => _uuids(envelope.payload['join']);

  /// UUIDs that left since the previous interval event.
  List<UUID> get leave => _uuids(envelope.payload['leave']);

  /// UUIDs that timed out since the previous interval event.
  List<UUID> get timeout => _uuids(envelope.payload['timeout']);

  /// Whether the interval event is too large to list the changes and a here
  /// now call should be made instead.
  bool get hereNowRefresh => envelope.payload['here_now_refresh'] == true;

  /// State of the [uuid] for [PresenceAction.stateChange] events.
  dynamic get state => envelope.payload['data'];

  PresenceEvent.fromEnvelope(this.envelope)
      : action = PresenceActionExtension.fromString(
            envelope.payload['action'] as String),
        uuid = envelope.payload['uuid'] != null
            ? UUID(envelope.payload['uuid'])
            : null,
        occupancy = envelope.payload['occupancy'] as int;
}
