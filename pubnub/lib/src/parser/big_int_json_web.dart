/// Matches JSON string literals, or bare integer literals with 16+ digits.
///
/// Group 1 is set only for the bare integer alternative. On the web compile
/// target, [int]/[num] are IEEE-754 doubles and cannot represent PubNub
/// timetokens (17 digits) exactly, so those literals are quoted as strings
/// before [json.decode].
final _bigIntegerPattern =
    RegExp(r'"(?:\\.|[^"\\])*"|(-?\d{16,})(?=\s*[,}\]])');

/// @nodoc
/// Quote bare 16+ digit JSON integers so they decode as exact [String]s.
String quoteBigIntegers(String input) {
  return input.replaceAllMapped(_bigIntegerPattern, (match) {
    final number = match.group(1);
    return number == null ? match.group(0)! : '"$number"';
  });
}
