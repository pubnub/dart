import 'package:pubnub/src/core/core.dart';

/// Exception thrown when one of the invariants of a method
/// is broken.
class InvariantException extends PubNubException {
  String message;

  InvariantException([this.message]);
}

class Ensure {
  dynamic value;

  Ensure(this.value);

  void isNotEmpty([String message]) {
    if (value is String && value.length != 0) {
      return;
    }

    throw InvariantException(message);
  }

  void isNotNull([String message]) {
    if (value != null) {
      return;
    }

    throw InvariantException(message);
  }
}
