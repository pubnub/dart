#!/bin/bash
#
# PostToolUse hook (Edit|Write): formats a Dart file under pubnub/ with `dart format` and analyzes it after every edit.
#
# It only speaks up when Claude needs to do something, so the context stays clean:
#   - Formatting is applied quietly (the harness already reports the file change).
#   - Remaining analyzer diagnostics are printed on stderr with exit 2, so Claude can fix them by hand:
#       lib/            every diagnostic (lib/ is analyzer-clean and CI-gated)
#       test/, example/ errors and warnings only (both carry pre-existing infos that CI does not gate)
#   - Never blocks on its own failures (missing dart/jq, packages not fetched).
#
# Shared by Claude Code (PostToolUse) and Cursor (afterFileEdit). Cursor sets CURSOR_VERSION; there the hook only
# formats, because Cursor documents no way for afterFileEdit output to reach the agent. Cursor gets the analyzer
# findings from the stop hook (run-dart-analyze.sh) instead.

INPUT=$(cat)

command -v jq >/dev/null 2>&1 || exit 0
command -v dart >/dev/null 2>&1 || exit 0

# Claude Code nests the path under tool_input; Cursor sends it at the top level
FILE_PATH=$(jq -r '.tool_input.file_path // .file_path // empty' <<<"$INPUT")

[[ "$FILE_PATH" == *.dart && -f "$FILE_PATH" ]] || exit 0

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
PKG="$ROOT/pubnub"

case "$FILE_PATH" in
  "$PKG"/lib/*) SEVERITIES='ERROR|WARNING|INFO' ;;
  "$PKG"/test/* | "$PKG"/example/*) SEVERITIES='ERROR|WARNING' ;;
  *) exit 0 ;;
esac

# Without resolved packages every import is an error; that is a setup problem, not something to fix in the file
[[ -f "$PKG/.dart_tool/package_config.json" ]] || exit 0

cd "$PKG" || exit 0

dart format "$FILE_PATH" >/dev/null 2>&1

[[ -n "$CURSOR_VERSION" ]] && exit 0

# --format=machine prints one `SEVERITY|TYPE|CODE|FILE|LINE|COLUMN|LENGTH|MESSAGE` line per diagnostic (on stderr)
DIAGNOSTICS=$(dart analyze --format=machine "$FILE_PATH" 2>&1 | grep -E "^($SEVERITIES)\|")

if [[ -n "$DIAGNOSTICS" ]]; then
  {
    echo "dart analyze diagnostics remain; fix them:"
    awk -F'|' '{
      msg = $8
      for (i = 9; i <= NF; i++) msg = msg "|" $i
      printf "%s:%s:%s: %s: %s (%s)\n", $4, $5, $6, tolower($1), msg, tolower($3)
    }' <<<"$DIAGNOSTICS" | sed "s|$ROOT/||"
  } >&2
  exit 2
fi

exit 0
