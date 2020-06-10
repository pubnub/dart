class UuidMetadataInput {
  String name;
  String email;
  dynamic custom;
  String externalId;
  String profileUrl;

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

class ChannelMetadataInput {
  String name;
  String description;
  dynamic custom;

  ChannelMetadataInput({this.name, this.description, this.custom});

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        'description': description,
        'custom': custom,
      };
}

class ChannelMemberMetadataInput {
  String uuid;
  Map<String, dynamic> custom;

  ChannelMemberMetadataInput(this.uuid, {this.custom});

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uuid': {'id': uuid},
        'custom': custom,
      };
}

class MembershipMetadataInput {
  String channelId;
  Map<String, dynamic> custom;

  MembershipMetadataInput(this.channelId, {this.custom});

  Map<String, dynamic> toJson() => <String, dynamic>{
        'channel': {'id': channelId},
        'custom': custom,
      };
}

class UuIdInfo {
  String uuid;

  UuIdInfo(this.uuid);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uuid': {'id': uuid},
      };
}

class ChannelIdInfo {
  String channelId;

  ChannelIdInfo(this.channelId);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'channel': {'id': channelId},
      };
}
