import 'core.dart';
import 'exceptions.dart';

class ParserException extends PubNubException {
  dynamic originalException;

  ParserException([String message, this.originalException]) : super(message);
}

abstract class IParserModule {
  void register(Core core);

  Future<T> decode<T>(String input, {String type});
  Future<String> encode<T>(T input, {String type});
}
