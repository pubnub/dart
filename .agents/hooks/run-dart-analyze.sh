#!/bin/bash
#
# Stop hook: runs the CI analysis and formatting gates when the agent finishes a turn, so problems that the
# per-file hook cannot see (a lib/ API change that breaks a test, an example, or another lib/ file) are fixed
# before control is handed back.
#
# Checks, from pubnub/:
#   - `dart analyze` on lib/, test/ and example/ in one run:
#       lib/            errors and warnings (the CI gate: `dart analyze --fatal-warnings lib`)
#       test/, example/ errors only (both carry pre-existing warnings that CI does not gate)
#   - `dart format -o none --set-exit-if-changed lib` (the CI gate)
#   - Cursor only: check-test-conventions.sh on every changed test file, since Cursor has no per-edit feedback
#
# Shared by Claude Code (Stop) and Cursor (stop). Cursor sets CURSOR_VERSION.
#   - Claude Code: findings go to stderr with exit 2, which keeps the turn going.
#   - Cursor: findings go to stdout as {"followup_message": ...} with exit 0, which Cursor submits as the next message.
#
# Stays silent unless the agent has to act:
#   - No-op unless .dart files under pubnub/lib, pubnub/test or pubnub/example have changed (per git status).
#   - On failure the full log is saved to /tmp; only deduplicated, capped findings and the log path are reported.
#
# Never blocks on its own failures:
#   - Loop guard: Claude Code stop_hook_active=true, or Cursor loop_count > 0 or status != completed: exit 0 at once.
#   - Missing dart/jq, unfetched packages, or a run exceeding CHECK_TIMEOUT: exit 0 with a one-line note on stderr.
#
# Limitation: it does not run tests; run the smallest relevant `dart test` from AGENTS.md.

MAX_FINDINGS=15
CHECK_TIMEOUT=240 # must stay below the timeout in .claude/settings.json and .cursor/hooks.json

INPUT=$(cat)
HOOK_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CURSOR_MODE=false
[[ -n "$CURSOR_VERSION" ]] && CURSOR_MODE=true

command -v jq >/dev/null 2>&1 || exit 0

if ! command -v dart >/dev/null 2>&1; then
  echo "dart not found; skipping dart analyze." >&2
  exit 0
fi

if $CURSOR_MODE; then
  [[ "$(jq -r '.status // "completed"' <<<"$INPUT")" == "completed" ]] || exit 0
  [[ "$(jq -r '.loop_count // 0' <<<"$INPUT")" == "0" ]] || exit 0
else
  [[ "$(jq -r '.stop_hook_active // false' <<<"$INPUT")" == "true" ]] && exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-${CURSOR_PROJECT_DIR:-$PWD}}" || exit 0
ROOT=$PWD
PKG="$ROOT/pubnub"

CHANGED=$(git status --porcelain --untracked-files=all -- \
  'pubnub/lib/*.dart' 'pubnub/test/*.dart' 'pubnub/example/*.dart' 2>/dev/null)
[[ -n "$CHANGED" ]] || exit 0

if [[ ! -f "$PKG/.dart_tool/package_config.json" ]]; then
  echo "pubnub/.dart_tool/package_config.json not found; run 'dart pub get' in pubnub/. Skipping dart analyze." >&2
  exit 0
fi

LOG=$(mktemp /tmp/dart-analyze.XXXXXX) || exit 0
FORMAT_LOG="$LOG.format"

# `timeout` is not available on stock macOS, so use a watchdog
(
  cd "$PKG" || exit 1
  dart analyze --format=machine lib test example >"$LOG" 2>&1
  dart format -o none --set-exit-if-changed lib >"$FORMAT_LOG" 2>&1
) &
CHECK_PID=$!
(
  sleep "$CHECK_TIMEOUT"
  pkill -TERM -P "$CHECK_PID" 2>/dev/null
  kill -TERM "$CHECK_PID" 2>/dev/null
) >/dev/null 2>&1 &
WATCHDOG_PID=$!

wait "$CHECK_PID"

if kill -0 "$WATCHDOG_PID" 2>/dev/null; then
  kill "$WATCHDOG_PID" 2>/dev/null
  wait "$WATCHDOG_PID" 2>/dev/null
else
  echo "dart analyze timed out after ${CHECK_TIMEOUT}s; skipping (log: $LOG)." >&2
  exit 0
fi

# Changed test files, for the Cursor-only conventions check. Porcelain lines are `XY path` or `XY old -> new`.
conventions_findings() {
  awk '{print $NF}' <<<"$CHANGED" | grep '^pubnub/test/.*\.dart$' | while read -r rel; do
    [[ -f "$ROOT/$rel" ]] || continue
    jq -n --arg p "$ROOT/$rel" '{file_path: $p}' | "$HOOK_DIR/check-test-conventions.sh" 2>&1 >/dev/null
  done
}

# Machine format: SEVERITY|TYPE|CODE|FILE|LINE|COLUMN|LENGTH|MESSAGE, with absolute file paths
FINDINGS=$(
  awk -F'|' -v pkg="$PKG/" '
    $1 != "ERROR" && $1 != "WARNING" { next }
    index($4, pkg "lib/") == 1 || ($1 == "ERROR" && (index($4, pkg "test/") == 1 || index($4, pkg "example/") == 1)) {
      msg = $8
      for (i = 9; i <= NF; i++) msg = msg "|" $i
      printf "%s:%s:%s: %s: %s (%s)\n", $4, $5, $6, tolower($1), msg, tolower($3)
    }
  ' "$LOG" | sed "s|$ROOT/||g"
  sed -n 's|^Changed \(.*\)$|pubnub/\1: not formatted; run dart format on it.|p' "$FORMAT_LOG" 2>/dev/null
  $CURSOR_MODE && conventions_findings
)
FINDINGS=$(awk 'NF && !seen[$0]++' <<<"$FINDINGS")

if [[ -z "$FINDINGS" ]]; then
  rm -f "$LOG" "$FORMAT_LOG"
  exit 0
fi

TOTAL=$(grep -c . <<<"$FINDINGS")
REPORT=$(
  echo "dart analyze/format checks failed; fix them (full log: $LOG):"
  head -n "$MAX_FINDINGS" <<<"$FINDINGS"
  ((TOTAL > MAX_FINDINGS)) && echo "... $((TOTAL - MAX_FINDINGS)) more omitted"
)

if $CURSOR_MODE; then
  jq -n --arg m "$REPORT" '{followup_message: $m}'
  exit 0
fi

echo "$REPORT" >&2
exit 2
