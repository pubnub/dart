#!/bin/bash
#
# PostToolUse hook (Edit|Write): warns when a test file under pubnub/test/ will never run.
#
# package:test discovers only `*_test.dart` files, and the presets in pubnub/dart_test.yaml select by tag:
# `integration` runs only files tagged `integration`, `unit` excludes them. A misnamed or mistagged test still
# analyzes cleanly and passes CI, because it never runs.
#
# Stays silent unless Claude has to act:
#   - Prints one line per problem on stderr with exit 2.
#   - Skips `part of` fixture files and helpers without main().
#   - Never blocks on its own failures (missing jq, unreadable file).
#
# Claude Code runs it as a PostToolUse hook. Cursor has no per-edit feedback channel, so the Cursor stop hook
# (run-dart-analyze.sh) calls it once per changed test file and forwards its stderr.

INPUT=$(cat)

command -v jq >/dev/null 2>&1 || exit 0

# Claude Code nests the path under tool_input; Cursor and run-dart-analyze.sh send it at the top level
FILE_PATH=$(jq -r '.tool_input.file_path // .file_path // empty' <<<"$INPUT")

[[ "$FILE_PATH" == *.dart && -r "$FILE_PATH" ]] || exit 0

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
TEST_DIR="$ROOT/pubnub/test"

case "$FILE_PATH" in
  "$TEST_DIR"/*) ;;
  *) exit 0 ;;
esac

# Fixtures are pulled into a test library with `part`; they are not entry points
grep -qE '^[[:space:]]*part[[:space:]]+of[[:space:]]' "$FILE_PATH" && exit 0

REL=${FILE_PATH#"$ROOT"/}
NAME=$(basename "$FILE_PATH")
INTEGRATION_TAG="@Tags\\(\\[[^]]*['\"]integration['\"]"

HAS_MAIN=false
grep -qE '^[[:space:]]*(void[[:space:]]+|Future<void>[[:space:]]+)?main[[:space:]]*\(' "$FILE_PATH" && HAS_MAIN=true

PROBLEMS=()

if [[ "$NAME" != *_test.dart ]]; then
  # Helpers (`_helpers.dart`, `fake_net.dart`, ...) have no main(); only flag files that look like tests
  if $HAS_MAIN; then
    PROBLEMS+=("$REL defines main() but is not named *_test.dart, so the test runner never discovers it; rename it to ${NAME%.dart}_test.dart.")
  fi
else
  if ! $HAS_MAIN; then
    PROBLEMS+=("$REL has no top-level main(), so the test runner cannot load it.")
  fi

  case "$FILE_PATH" in
    "$TEST_DIR"/integration/*)
      if ! grep -qE "@TestOn\\(['\"]browser" "$FILE_PATH" && ! grep -qE "$INTEGRATION_TAG" "$FILE_PATH"; then
        PROBLEMS+=("$REL is missing @Tags(['integration']), so the integration preset skips it; add @TestOn('vm') and @Tags(['integration']) before the imports.")
      fi
      ;;
    "$TEST_DIR"/unit/*)
      if grep -qE "$INTEGRATION_TAG" "$FILE_PATH"; then
        PROBLEMS+=("$REL is tagged integration, so the unit preset excludes it; remove the tag or move the test to test/integration/.")
      fi
      ;;
  esac
fi

if ((${#PROBLEMS[@]} > 0)); then
  printf '%s\n' "${PROBLEMS[@]}" >&2
  exit 2
fi

exit 0
