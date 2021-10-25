import 'package:pubnub/pubnub.dart' show ResourceType;

class ResourceDetails {
  String? name;
  String? pattern;
  final ResourceType resourceType;
  Map<String, bool> permissions = {};

  ResourceDetails(this.resourceType, {this.name, this.pattern});
}
