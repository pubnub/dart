/// Represents UUID metadata operations input.
///
/// {@category Objects}
class UuidMetadataInput {
  String? name;
  String? email;
  dynamic? custom;
  String? externalId;
  String? profileUrl;

  UuidMetadataInput(
      {this.name, this.email, this.externalId, this.profileUrl, this.custom});

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'email': email,
        'custom': custom,
        'externalId': externalId,
        'profileUrl': profileUrl,
      };
}

/// Represents channel metadata operations input.
///
/// {@category Objects}
class ChannelMetadataInput {
  String? name;
  String? description;
  dynamic? custom;

  ChannelMetadataInput({this.name, this.description, this.custom});

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'description': description,
        'custom': custom,
      };
}

/// Represents channel member metadata operations input.
///
/// {@category Objects}
class ChannelMemberMetadataInput {
  String uuid;
  Map<String, dynamic>? custom;

  ChannelMemberMetadataInput(this.uuid, {this.custom});

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uuid': {'id': uuid},
        'custom': custom,
      };
}

/// Represents membership metadata operations input.
///
/// {@category Objects}
class MembershipMetadataInput {
  String channelId;
  Map<String, dynamic>? custom;

  MembershipMetadataInput(this.channelId, {this.custom});

  Map<String, dynamic> toJson() => <String, dynamic>{
        'channel': {'id': channelId},
        'custom': custom,
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
