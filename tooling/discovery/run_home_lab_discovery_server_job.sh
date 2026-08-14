#!/usr/bin/env bash
set -Eeuo pipefail

MODE="${1:-prepare}"
ROLLBACK_ARG="${2:-}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEV="/opt/src/moonfin-dev"
LOG_DIR="$DEV/logs"
STATE_DIR="$DEV/state"
STAMP="$(date +%Y%m%d-%H%M%S)"
LOG="$LOG_DIR/discovery-server-${MODE}-${STAMP}.log"
CURRENT="$STATE_DIR/discovery-server-current.log"
PID_FILE="$STATE_DIR/discovery-server-current.pid"

case "$MODE" in
  prepare|apply|rollback) ;;
  *)
    echo "Usage: $0 [prepare|apply|rollback] [backup-dir]" >&2
    exit 2
    ;;
esac

mkdir -p "$LOG_DIR" "$STATE_DIR"

if [[ -f "$PID_FILE" ]]; then
  old_pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
    echo "ERROR: Discovery server job is already running as PID $old_pid." >&2
    echo "Reconnect: tail -n 180 -f \"\$(readlink -f $CURRENT)\"" >&2
    exit 1
  fi
fi

ln -sfn "$LOG" "$CURRENT"

nohup bash "$ROOT/tooling/discovery/home_lab_discovery_server_job.sh" \
  "$MODE" "$ROLLBACK_ARG" >"$LOG" 2>&1 < /dev/null &
pid=$!
printf '%s\n' "$pid" > "$PID_FILE"

cat <<EOF
Discovery server job started.
mode=$MODE
pid=$pid
log=$LOG

Reconnect/progress:
tail -n 180 -f "\$(readlink -f $CURRENT)"
EOF
