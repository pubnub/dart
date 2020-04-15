import 'exceptions.dart';

class ParserException extends PubNubException {
  String message;

  ParserException([this.message]);
}

abstract class ParserModule {
  Future<dynamic> decode(String input);
  Future<String> encode(dynamic input);
}
