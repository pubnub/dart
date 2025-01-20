/// Represents UUID metadata operations input.
///
/// {@category Objects}
class UuidMetadataInput {
  String? name;
  String? email;
  dynamic custom;
  String? externalId;
  String? profileUrl;
  String? status;
  String? type;

  UuidMetadataInput(
      {this.name,
      this.email,
      this.externalId,
      this.profileUrl,
      this.custom,
      this.status,
      this.type});

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (name != null) 'name': name,
        if (email != null) 'email': email,
        if (custom != null) 'custom': custom,
        if (externalId != null) 'externalId': externalId,
        if (profileUrl != null) 'profileUrl': profileUrl,
        if (status != null) 'status': status,
        if (type != null) 'type': type,
      };
}

/// Represents channel metadata operations input.
///
/// {@category Objects}
class ChannelMetadataInput {
  String? name;
  String? description;
  dynamic custom;
  String? status;
  String? type;

  ChannelMetadataInput(
      {this.name, this.description, this.custom, this.status, this.type});

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (custom != null) 'custom': custom,
        if (status != null) 'status': status,
        if (type != null) 'type': type,
      };
}

/// Represents channel member metadata operations input.
///
/// {@category Objects}
class ChannelMemberMetadataInput {
  String uuid;
  Map<String, dynamic>? custom;
  String? status;
  String? type;

  ChannelMemberMetadataInput(this.uuid, {this.custom, this.status, this.type});

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uuid': {'id': uuid},
        if (custom != null) 'custom': custom,
        if (status != null) 'status': status,
        if (type != null) 'type': type,
      };
}

/// Represents membership metadata operations input.
///
/// {@category Objects}
class MembershipMetadataInput {
  String channelId;
  Map<String, dynamic>? custom;
  String? status;
  String? type;

  MembershipMetadataInput(this.channelId,
      {this.custom, this.status, this.type});

  Map<String, dynamic> toJson() => <String, dynamic>{
        'channel': {'id': channelId},
        if (custom != null) 'custom': custom,
        if (status != null) 'status': status,
        if (type != null) 'type': type,
      };
}

/// Represents UUID input.
///
/// {@category Objects}
class UuIdInfo {
  String uuid;

  UuIdInfo(this.uuid);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uuid': {'id': uuid},
      };
}

/// Represents channel id input.
///
/// {@category Objects}
class ChannelIdInfo {
  String channelId;

  ChannelIdInfo(this.channelId);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'channel': {'id': channelId},
      };
}
