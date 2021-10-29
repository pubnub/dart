import 'package:gherkin/gherkin.dart';
import 'package:pubnub/pubnub.dart';

class PushGatewayParameter extends CustomParameter<PushGateway> {
  PushGatewayParameter()
      : super('gateway', RegExp(r'(GCM|FCM|APNS2)', caseSensitive: false), (c) {
          switch (c.toLowerCase()) {
            case 'gcm':
              return PushGateway.gcm;
            case 'apns2':
              return PushGateway.apns2;
            case 'fcm':
              return PushGateway.fcm;
            default:
              throw Exception('Unreachable state');
          }
        });
}
