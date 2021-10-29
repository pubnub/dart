import 'package:pubnub/pubnub.dart';

ResourceType getResourceType(String resourceType) {
  switch (resourceType) {
    case 'CHANNEL':
      return ResourceType.channel;
    case 'CHANNEL_GROUP':
      return ResourceType.channelGroup;
    case 'UUID':
      return ResourceType.uuid;
    default:
      throw Exception('Invalid Resource Type');
  }
}

int getBitValue(String accessType) {
  switch (accessType) {
    case 'READ':
      return 1;
    case 'WRITE':
      return 2;
    case 'MANAGE':
      return 4;
    case 'DELETE':
      return 8;
    case 'CREATE':
      return 16;
    case 'GET':
      return 32;
    case 'UPDATE':
      return 64;
    case 'JOIN':
      return 128;
    default:
      throw Exception('Invalid access permission type');
  }
}
