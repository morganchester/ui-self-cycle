#!/usr/bin/env bash
set -euo pipefail

# Example orchestration entrypoint for one ui-self-cycle run.
# This script is intentionally conservative:
# - it installs dependencies only when obviously missing
# - it prefers attaching to an existing app if BASE_URL is healthy
# - it starts one local app instance if needed
# - it writes state into ./.ralph/ui-self-cycle by default

PROJECT_ROOT="${PROJECT_ROOT:-$(pwd)}"
STATE_DIR="${STATE_DIR:-$PROJECT_ROOT/.ralph/ui-self-cycle}"
EVIDENCE_DIR="$STATE_DIR/evidence"
BASE_URL="${BASE_URL:-}"
ENTRY_PAGES="${ENTRY_PAGES:-/}"
READINESS_TIMEOUT="${READINESS_TIMEOUT:-120}"
SAFE_MODE="${SAFE_MODE:-true}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$STATE_DIR" "$EVIDENCE_DIR"

timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

log() {
  printf '[%s] %s\n' "$(timestamp)" "$*" | tee -a "$STATE_DIR/run-cycle.log" >&2
}

fail() {
  log "ERROR: $*"
  exit 1
}

detect_pkg_manager() {
  if [[ -f "$PROJECT_ROOT/pnpm-lock.yaml" ]]; then echo "pnpm"; return; fi
  if [[ -f "$PROJECT_ROOT/package-lock.json" ]]; then echo "npm"; return; fi
  if [[ -f "$PROJECT_ROOT/yarn.lock" ]]; then echo "yarn"; return; fi
  if [[ -f "$PROJECT_ROOT/bun.lockb" || -f "$PROJECT_ROOT/bun.lock" ]]; then echo "bun"; return; fi
  echo ""
}

detect_node_script() {
  local name="$1"
  if [[ ! -f "$PROJECT_ROOT/package.json" ]]; then
    return 1
  fi
  node -e "const p=require('$PROJECT_ROOT/package.json'); process.exit(p.scripts&&p.scripts['$name']?0:1)"
}

install_deps_if_missing() {
  local pm="$1"
  [[ -d "$PROJECT_ROOT/node_modules" ]] && return 0
  [[ -z "$pm" ]] && return 0
  log "node_modules missing; installing dependencies with $pm"
  case "$pm" in
    pnpm) (cd "$PROJECT_ROOT" && pnpm install --frozen-lockfile) ;;
    npm)  (cd "$PROJECT_ROOT" && npm ci) ;;
    yarn) (cd "$PROJECT_ROOT" && yarn install --frozen-lockfile) ;;
    bun)  (cd "$PROJECT_ROOT" && bun install --frozen-lockfile) ;;
    *) fail "Unsupported package manager: $pm" ;;
  esac
}

wait_for_url() {
  local url="$1"
  local timeout="$2"
  local started_at
  started_at="$(date +%s)"
  while true; do
    if curl -fsS "$url" >/dev/null 2>&1; then
      return 0
    fi
    if (( "$(date +%s)" - started_at > timeout )); then
      return 1
    fi
    sleep 2
  done
}

choose_start_command() {
  if detect_node_script dev; then echo "dev"; return; fi
  if detect_node_script start; then echo "start"; return; fi
  if [[ -f "$PROJECT_ROOT/vite.config.js" || -f "$PROJECT_ROOT/vite.config.ts" ]]; then echo "__npx_vite"; return; fi
  if [[ -f "$PROJECT_ROOT/next.config.js" || -f "$PROJECT_ROOT/next.config.mjs" || -f "$PROJECT_ROOT/next.config.ts" ]]; then echo "__npx_next_dev"; return; fi
  echo ""
}

start_app() {
  local pm="$1"
  local start_kind="$2"
  local logfile="$STATE_DIR/app-start.log"
  : >"$logfile"
  log "Starting app using strategy: $start_kind"
  case "$start_kind" in
    dev|start)
      case "$pm" in
        pnpm) (cd "$PROJECT_ROOT" && nohup pnpm run "$start_kind" >"$logfile" 2>&1 & echo $! >"$STATE_DIR/app.pid") ;;
        npm)  (cd "$PROJECT_ROOT" && nohup npm run "$start_kind" >"$logfile" 2>&1 & echo $! >"$STATE_DIR/app.pid") ;;
        yarn) (cd "$PROJECT_ROOT" && nohup yarn "$start_kind" >"$logfile" 2>&1 & echo $! >"$STATE_DIR/app.pid") ;;
        bun)  (cd "$PROJECT_ROOT" && nohup bun run "$start_kind" >"$logfile" 2>&1 & echo $! >"$STATE_DIR/app.pid") ;;
        *) fail "Cannot run package script without a supported package manager" ;;
      esac
      ;;
    __npx_vite)
      (cd "$PROJECT_ROOT" && nohup npx vite >"$logfile" 2>&1 & echo $! >"$STATE_DIR/app.pid")
      ;;
    __npx_next_dev)
      (cd "$PROJECT_ROOT" && nohup npx next dev >"$logfile" 2>&1 & echo $! >"$STATE_DIR/app.pid")
      ;;
    *)
      fail "No safe start command found"
      ;;
  esac
}

infer_base_url() {
  local logfile="$STATE_DIR/app-start.log"
  local url
  url="$(grep -Eo 'https?://(127\.0\.0\.1|localhost|0\.0\.0\.0):[0-9]+' "$logfile" | tail -n1 || true)"
  if [[ -n "$url" ]]; then
    url="${url/0.0.0.0/127.0.0.1}"
    echo "$url"
    return 0
  fi
  for port in 3000 3001 4173 4174 5173 5174 8000 8080; do
    if curl -fsS "http://127.0.0.1:$port" >/dev/null 2>&1; then
      echo "http://127.0.0.1:$port"
      return 0
    fi
  done
  return 1
}

write_progress() {
  cat >"$STATE_DIR/progress.txt" <<EOF
status=continue
project_root=$PROJECT_ROOT
base_url=$BASE_URL
last_run_timestamp=$(timestamp)
last_step=runtime_ready
next_action=collect_ui_evidence
EOF
}

main() {
  log "ui-self-cycle run starting"
  log "project root: $PROJECT_ROOT"

  if [[ -n "$BASE_URL" ]]; then
    log "BASE_URL provided: $BASE_URL"
    if wait_for_url "$BASE_URL" 10; then
      log "Attach mode succeeded"
      write_progress
    else
      fail "Provided BASE_URL is not reachable: $BASE_URL"
    fi
  else
    local pm start_kind
    pm="$(detect_pkg_manager)"
    install_deps_if_missing "$pm"
    start_kind="$(choose_start_command)"
    [[ -n "$start_kind" ]] || fail "Could not detect a safe app start command"
    start_app "$pm" "$start_kind"
    sleep 5
    BASE_URL="$(infer_base_url)" || fail "App started but no base URL could be inferred; check $STATE_DIR/app-start.log"
    wait_for_url "$BASE_URL" "$READINESS_TIMEOUT" || fail "App did not become ready at $BASE_URL within ${READINESS_TIMEOUT}s"
    log "App ready at $BASE_URL"
    write_progress
  fi

  "$SCRIPT_DIR/collect-ui-evidence.example.sh" >/dev/null 2>&1 || true

  log "Run bootstrap complete"
  printf '%s\n' "$BASE_URL" >"$STATE_DIR/base-url.txt"
}

main "$@"
