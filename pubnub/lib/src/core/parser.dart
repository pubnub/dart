import 'core.dart';
import 'exceptions.dart';

/// Exception thrown when parsing fails.
///
/// {@category Exceptions}
class ParserException extends PubNubException {
  dynamic originalException;

  ParserException(String message, [this.originalException]) : super(message);
}

/// @nodoc
abstract class IParserModule {
  void register(Core core);

  Future<T> decode<T>(String input, {String type});
  Future<String> encode<T>(T input, {String type});
}
