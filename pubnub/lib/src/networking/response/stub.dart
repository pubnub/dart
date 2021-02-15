import 'package:pubnub/core.dart';

class Response extends IResponse {
  Response(List<int> bytes, response);

  @override
  // TODO: implement byteList
  List<int> get byteList => throw UnimplementedError();

  @override
  // TODO: implement headers
  Map<String, List<String>> get headers => throw UnimplementedError();

  @override
  // TODO: implement statusCode
  int get statusCode => throw UnimplementedError();

  @override
  // TODO: implement text
  String get text => throw UnimplementedError();
}
