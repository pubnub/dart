#!/bin/bash
#
# Cursor beforeShellExecution hook: stops the agent from starting slow, live, or nonexistent tooling unasked.
# Claude Code gets the same guard from the permission rules in .claude/settings.json instead.
#
# Verdicts (JSON on stdout, as Cursor requires):
#   deny   `build_runner` (the package has no build_runner dependency; the README step is stale)
#   ask    `dart test -P integration`, bare `dart test`, a test/integration directory sweep, `derry test` (any script but unit)
#   allow  `dart test -P unit`, `dart test` on paths under test/unit, `dart test` on exactly one *_test.dart file,
#          `derry test unit`, and every other command
#
# Fails open: anything it cannot parse is allowed. It always prints valid JSON, because Cursor blocks the command
# when a hook returns invalid output.

allow() {
  printf '{"permission":"allow"}\n'
  exit 0
}

respond() { # permission message
  jq -n --arg p "$1" --arg m "$2" '{permission: $p, user_message: $m, agent_message: $m}' 2>/dev/null || allow
  exit 0
}

command -v jq >/dev/null 2>&1 || allow

COMMAND=$(jq -r '.command // empty' 2>/dev/null) || allow
[[ -n "$COMMAND" ]] || allow

UNIT_HINT='From pubnub/, run `dart test -P unit`, or `dart test` on one test file.'
VALUE_FLAGS=' -n --name -N --plain-name -t --tags -x --exclude-tags -p --platform -c --compiler -P --preset -j --concurrency --total-shards --shard-index --timeout -r --reporter --file-reporter --coverage '

tool_name() { # basename of a token, lowercased
  local name=${1##*/}
  echo "$name" | tr '[:upper:]' '[:lower:]'
}

is_unit_path() {
  local p=${1#./}
  p=${p%/}
  [[ "$p" == test/unit || "$p" == test/unit/* || "$p" == */test/unit || "$p" == */test/unit/* ]]
}

# Returns 0 when the `dart test` arguments are narrow enough to run unasked
narrow_test_args() {
  local presets=() paths=() skip=false prev='' arg
  for arg in "$@"; do
    if $skip; then
      [[ "$prev" == -P || "$prev" == --preset ]] && presets+=("$arg")
      skip=false
      continue
    fi
    case "$arg" in
      # Shell redirections are not test arguments; a bare operator takes the next token as its target
      '>' | '>>' | '<' | '2>' | '&>') skip=true && prev=$arg ;;
      *'>'* | *'<'*) ;;
      -h | --help | --version) return 0 ;;
      -P?*) presets+=("${arg#-P}") ;;
      --preset=*) presets+=("${arg#--preset=}") ;;
      -*=*) ;;
      -*) [[ "$VALUE_FLAGS" == *" $arg "* ]] && skip=true && prev=$arg ;;
      *) paths+=("$arg") ;;
    esac
  done

  local preset
  for preset in "${presets[@]}"; do
    [[ "$preset" == unit ]] || return 1
  done

  local files=0 dirs=0 path
  for path in "${paths[@]}"; do
    if [[ "$path" == *.dart ]]; then files=$((files + 1)); else dirs=$((dirs + 1)); fi
  done
  ((files == 1 && dirs == 0)) && return 0
  if ((${#paths[@]} == 0)); then
    ((${#presets[@]} > 0))
    return
  fi
  for path in "${paths[@]}"; do
    is_unit_path "$path" || return 1
  done
  return 0
}

check_segment() {
  local tokens i name next
  read -ra tokens <<<"$(tr -d "\"'" <<<"$1")"

  for ((i = 0; i < ${#tokens[@]}; i++)); do
    name=$(tool_name "${tokens[i]}")

    if [[ "$name" == build_runner ]]; then
      respond deny 'This package has no build_runner dependency; the build_runner step in pubnub/README.md is stale.'
    fi

    if [[ "$name" == derry || "$name" == derry.bat || "$name" == derry.cmd ]] &&
      [[ "$(tool_name "${tokens[i + 1]}")" == test ]]; then
      next=${tokens[i + 2]}
      if [[ "$next" != unit ]]; then
        respond ask "\`derry test${next:+ $next}\` runs the live integration suite. $UNIT_HINT"
      fi
    fi

    if [[ "$name" == dart || "$name" == dart.exe || "$name" == dart.bat ]]; then
      local j=$((i + 1))
      [[ "${tokens[j]}" == pub ]] && j=$((j + 1))
      [[ "${tokens[j]}" == run ]] && j=$((j + 1))
      [[ "${tokens[j]}" == test ]] || continue
      if ! narrow_test_args "${tokens[@]:j+1}"; then
        respond ask "This command may run the live integration tests, which need keys and network (DataSync tests fail without DS_* keys). $UNIT_HINT"
      fi
    fi
  done
}

while IFS= read -r segment; do
  [[ -n "${segment// /}" ]] && check_segment "$segment"
done < <(awk '{ gsub(/&&|\|\||;|\|/, "\n"); print }' <<<"$COMMAND")

allow
