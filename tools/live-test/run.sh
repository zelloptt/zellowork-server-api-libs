#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LIVE="$ROOT/tools/live-test"
COMPOSE_FILE="$LIVE/docker-compose.yml"

ALL_LANGS=(php python java csharp swift objc)
ALL_SCENARIOS=(auth-new auth-legacy session-get-users auth-bad-password auth-bad-api-key)
DOCKER_LANGS=" php java csharp "

HOST=""
USERNAME=""
LANGS=""
SCENARIOS=""

usage() {
  cat <<'EOF'
Usage:
  export ZW_API_KEY='...'
  export ZW_PASSWORD='...'
  ./tools/live-test/run.sh --host HOST --username USER [--langs L] [--scenarios S]

Options:
  --host        Network host, e.g. https://network.zellowork.com
  --username    Admin username
  --langs       Comma list (default: all). php,python,java,csharp,swift,objc
  --scenarios   Comma list (default: all five auth scenarios)
  -h, --help    Show this help

Secrets (required env):
  ZW_API_KEY
  ZW_PASSWORD

Docker langs: php, java, csharp
Host langs:   python, swift, objc
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host) HOST="${2:-}"; shift 2 ;;
    --username) USERNAME="${2:-}"; shift 2 ;;
    --langs) LANGS="${2:-}"; shift 2 ;;
    --scenarios) SCENARIOS="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z "$HOST" || -z "$USERNAME" ]]; then
  echo "error: --host and --username are required" >&2
  usage >&2
  exit 2
fi
if [[ -z "${ZW_API_KEY:-}" || -z "${ZW_PASSWORD:-}" ]]; then
  echo "error: ZW_API_KEY and ZW_PASSWORD must be set in the environment" >&2
  exit 2
fi

if [[ -z "$LANGS" ]]; then
  SELECTED_LANGS=("${ALL_LANGS[@]}")
else
  IFS=',' read -r -a SELECTED_LANGS <<< "$LANGS"
fi

if [[ -z "$SCENARIOS" ]]; then
  SELECTED_SCENARIOS=("${ALL_SCENARIOS[@]}")
else
  IFS=',' read -r -a SELECTED_SCENARIOS <<< "$SCENARIOS"
fi

export ZW_HOST="$HOST"
export ZW_USERNAME="$USERNAME"

is_docker_lang() {
  [[ "$DOCKER_LANGS" == *" $1 "* ]]
}

ensure_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    return 1
  fi
  if ! docker compose version >/dev/null 2>&1 && ! docker-compose version >/dev/null 2>&1; then
    return 1
  fi
  return 0
}

compose() {
  if docker compose version >/dev/null 2>&1; then
    docker compose -f "$COMPOSE_FILE" "$@"
  else
    docker-compose -f "$COMPOSE_FILE" "$@"
  fi
}

scenario_host_path() {
  echo "$LIVE/scenarios/$1.json"
}

scenario_container_path() {
  echo "/workspace/tools/live-test/scenarios/$1.json"
}

PASS=0
FAIL=0
SKIP=0

run_one() {
  local lang="$1"
  local scenario="$2"
  local host_scenario
  host_scenario="$(scenario_host_path "$scenario")"
  if [[ ! -f "$host_scenario" ]]; then
    echo "FAIL  $lang / $scenario  (missing $host_scenario)"
    FAIL=$((FAIL + 1))
    return
  fi

  local out ec=0
  if is_docker_lang "$lang"; then
    if ! ensure_docker; then
      echo "SKIP  $lang / $scenario  (docker not available)"
      SKIP=$((SKIP + 1))
      return
    fi
    export ZW_SCENARIO
    ZW_SCENARIO="$(scenario_container_path "$scenario")"
    compose build --quiet "$lang" >/dev/null 2>&1
    set +e
    out="$(compose run --rm -T \
      -e ZW_HOST -e ZW_USERNAME -e ZW_API_KEY -e ZW_PASSWORD -e ZW_SCENARIO \
      "$lang" 2>&1)"
    ec=$?
    set -e
  else
    case "$lang" in
      python)
        if ! command -v python3 >/dev/null 2>&1; then
          echo "SKIP  $lang / $scenario  (python3 missing)"
          SKIP=$((SKIP + 1))
          return
        fi
        local venv="$LIVE/.venv"
        if [[ ! -x "$venv/bin/python" ]]; then
          python3 -m venv "$venv"
          "$venv/bin/pip" install -q requests
        fi
        export ZW_SCENARIO="$host_scenario"
        set +e
        out="$("$venv/bin/python" "$LIVE/runners/python/run.py" 2>&1)"
        ec=$?
        set -e
        ;;
      swift)
        if ! command -v swiftc >/dev/null 2>&1; then
          echo "SKIP  $lang / $scenario  (swiftc missing)"
          SKIP=$((SKIP + 1))
          return
        fi
        export ZW_SCENARIO="$host_scenario"
        set +e
        out="$(bash "$LIVE/runners/swift/run.sh" 2>&1)"
        ec=$?
        set -e
        ;;
      objc)
        if ! command -v clang >/dev/null 2>&1; then
          echo "SKIP  $lang / $scenario  (clang missing)"
          SKIP=$((SKIP + 1))
          return
        fi
        export ZW_SCENARIO="$host_scenario"
        set +e
        out="$(bash "$LIVE/runners/objc/run.sh" 2>&1)"
        ec=$?
        set -e
        ;;
      *)
        echo "SKIP  $lang / $scenario  (unknown language)"
        SKIP=$((SKIP + 1))
        return
        ;;
    esac
  fi

  local json_line
  json_line="$(printf '%s\n' "$out" | grep -E '^\{' | tail -n 1 || true)"
  if [[ -n "$json_line" ]]; then
    local ok
    ok="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1]).get("ok"))' "$json_line" 2>/dev/null || echo "")"
    if [[ "$ok" == "True" || "$ok" == "true" ]]; then
      echo "PASS  $lang / $scenario"
      PASS=$((PASS + 1))
      return
    fi
    local err
    err="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1]).get("error") or "")' "$json_line" 2>/dev/null || echo "")"
    echo "FAIL  $lang / $scenario  ${err}"
    FAIL=$((FAIL + 1))
    return
  fi

  echo "FAIL  $lang / $scenario  (no JSON result; exit=$ec)"
  printf '%s\n' "$out" | tail -n 20 | sed 's/^/      /'
  FAIL=$((FAIL + 1))
}

for lang in "${SELECTED_LANGS[@]}"; do
  lang="$(echo "$lang" | tr -d '[:space:]')"
  [[ -z "$lang" ]] && continue
  for scenario in "${SELECTED_SCENARIOS[@]}"; do
    scenario="$(echo "$scenario" | tr -d '[:space:]')"
    [[ -z "$scenario" ]] && continue
    run_one "$lang" "$scenario"
  done
done

echo
echo "Summary: PASS=$PASS FAIL=$FAIL SKIP=$SKIP"
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
