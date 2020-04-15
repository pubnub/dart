class UserDetails {
  String id;
  String name;
  String email;
  dynamic custom;
  String externalId;
  String profileUrl;

  UserDetails(this.id, this.name,
      {this.email, this.externalId, this.profileUrl, this.custom});

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'email': email,
        'custom': custom,
        'externalId': externalId,
        'profileUrl': profileUrl,
      };
}

class SpaceDetails {
  String id;
  String name;
  String description;
  dynamic custom;

  SpaceDetails(this.id, this.name, {this.description, this.custom});

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'description': description,
        'custom': custom,
      };
}

class UpdateInfo {
  String id;
  dynamic custom;

  UpdateInfo(this.id, this.custom);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'custom': custom,
      };
}

class IdInfo {
  String id;

  IdInfo(this.id);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
      };
}
