import 'exceptions.dart';

class ParserException extends PubNubException {
  ParserException([String message]) : super(message);
}

abstract class ParserModule {
  Future<dynamic> decode(String input);
  Future<String> encode(dynamic input);
}
