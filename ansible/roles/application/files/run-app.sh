#!/usr/bin/env bash
set -euo pipefail

APP=/opt/lab-app/bin/lab-app
PID_FILE=/opt/lab-app/app.pid
LOG_FILE=/opt/lab-app/app.log

is_running() {
  [[ -f "$PID_FILE" ]] || return 1
  local pid
  pid=$(cat "$PID_FILE")
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  kill -0 "$pid" 2>/dev/null || return 1
  [[ "$(readlink -f "/proc/$pid/exe" 2>/dev/null || true)" == "$APP" ]]
}

case "${1:-}" in
  start)
    if is_running; then echo 'already running'; exit 0; fi
    rm -f "$PID_FILE"
    [[ -x "$APP" ]] || { echo 'missing application binary' >&2; exit 1; }
    nohup "$APP" >> "$LOG_FILE" 2>&1 < /dev/null &
    echo "$!" > "$PID_FILE"
    sleep 0.2
    if ! is_running; then echo 'failed to start application' >&2; exit 1; fi
    echo "started PID $(cat "$PID_FILE")"
    ;;
  stop)
    if is_running; then
      pid=$(cat "$PID_FILE")
      kill "$pid"
      for _ in $(seq 1 30); do
        if ! kill -0 "$pid" 2>/dev/null; then break; fi
        sleep 0.1
      done
      echo 'stopped'
    else
      echo 'not running'
    fi
    rm -f "$PID_FILE"
    ;;
  status)
    if is_running; then echo "running PID $(cat "$PID_FILE")"; else echo 'not running'; exit 1; fi
    ;;
  *) echo 'Usage: run-app.sh {start|stop|status}' >&2; exit 2 ;;
esac
