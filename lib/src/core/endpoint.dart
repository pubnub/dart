import 'net/net.dart';

/// Represents all the data necessary to make a request to the API.
///
/// @nodoc
abstract class Parameters {
  Request toRequest();
}

/// Represents the response from an API.
///
/// @nodoc
abstract class Result {}
