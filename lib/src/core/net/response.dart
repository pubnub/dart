/// @nodoc
abstract class IResponse {
  int get statusCode;
  Map<String, List<String>> get headers;

  String get text;
  List<int> get byteList;
}
