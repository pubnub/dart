import 'package:pubnub/src/core/core.dart';

final _invariantMessages = {
  'not-null': (String that, _) => '${that} cannot be null',
  'not-empty': (String that, _) => '${that} cannot be empty',
  'default': (_, __) => 'invariant has been broken',
  'is-equal': (String that, List<String> what) =>
      '${that} has to equal ${what[0]}'
};

/// Exception thrown when one of the invariants of a method
/// is broken.
class InvariantException extends PubNubException {
  InvariantException(String messageId,
      [String what, List<String> args = const []])
      : super((_invariantMessages[messageId] ?? _invariantMessages['default'])(
            what, args));
}

class Ensure {
  dynamic value;

  Ensure(this.value);

  void isNotEmpty([String what]) {
    if (value != null && value is List && value.length != 0) {
      return;
    }

    if (value != null && value is String && value.length != 0) {
      return;
    }

    throw InvariantException('not-empty', what);
  }

  void isNotNull([String what]) {
    if (value != null) {
      return;
    }

    throw InvariantException('not-null', what);
  }

  void isEqual(dynamic otherValue, [String what]) {
    if (value == otherValue) {
      return;
    }

    throw InvariantException('is-equal', what, ['$otherValue']);
  }
}
