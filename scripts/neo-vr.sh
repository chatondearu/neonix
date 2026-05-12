#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/neo-vr"
WAYVR_PID_FILE="${STATE_DIR}/wayvr.pid"
WAYVR_LOG_FILE="${STATE_DIR}/wayvr.log"
WIVRN_SERVER_PID_FILE="${STATE_DIR}/wivrn-server.pid"
WIVRN_SERVER_LOG_FILE="${STATE_DIR}/wivrn-server.log"
WIVRN_DASHBOARD_PID_FILE="${STATE_DIR}/wivrn-dashboard.pid"
WIVRN_DASHBOARD_LOG_FILE="${STATE_DIR}/wivrn-dashboard.log"

mkdir -p "${STATE_DIR}"

print_help() {
  cat <<'EOF'
neo-vr - Manage WiVRn and WayVR quickly

Usage:
  neo-vr start          Start wivrn-server and WayVR
  neo-vr restart        Restart both
  neo-vr status         Show WiVRn/WayVR status
  neo-vr logs           Show latest WayVR and WiVRn logs
  neo-vr wayvr-start    Start WayVR only
  neo-vr wayvr-stop     Stop WayVR only
  neo-vr wivrn-start    Start wivrn-server only
  neo-vr wivrn-stop     Stop wivrn-server only
  neo-vr wivrn-gui      Start wivrn-dashboard
  neo-vr wivrn-gui-stop Stop wivrn-dashboard
  neo-vr stop           Stop WayVR + wivrn-server + wivrn-dashboard
  neo-vr help           Show this help
EOF
}

is_running_pid_file() {
  local pid_file="${1}"
  [[ -f "${pid_file}" ]] || return 1
  local pid
  pid="$(<"${pid_file}")"
  kill -0 "${pid}" 2>/dev/null
}

start_process() {
  local name="${1}"
  local command="${2}"
  local pid_file="${3}"
  local log_file="${4}"

  if is_running_pid_file "${pid_file}"; then
    echo "${name} is already running (pid $(<"${pid_file}"))."
    return 0
  fi

  echo "Starting ${name} (logs: ${log_file})..."
  nohup "${command}" >"${log_file}" 2>&1 &
  local pid=$!
  echo "${pid}" >"${pid_file}"
  sleep 1

  if kill -0 "${pid}" 2>/dev/null; then
    echo "${name} started (pid ${pid})."
  else
    echo "${name} failed to start. Check logs: ${log_file}" >&2
    rm -f "${pid_file}"
    return 1
  fi
}

stop_process() {
  local name="${1}"
  local pid_file="${2}"

  if ! is_running_pid_file "${pid_file}"; then
    rm -f "${pid_file}"
    echo "${name} is not running."
    return 0
  fi

  local pid
  pid="$(<"${pid_file}")"
  echo "Stopping ${name} (pid ${pid})..."
  kill "${pid}" 2>/dev/null || true
  sleep 1
  if kill -0 "${pid}" 2>/dev/null; then
    echo "${name} did not exit yet, forcing stop..."
    kill -9 "${pid}" 2>/dev/null || true
  fi
  rm -f "${pid_file}"
  echo "${name} stopped."
}

is_wayvr_running() {
  is_running_pid_file "${WAYVR_PID_FILE}"
}

start_wivrn() {
  start_process "wivrn-server" "wivrn-server" "${WIVRN_SERVER_PID_FILE}" "${WIVRN_SERVER_LOG_FILE}"
}

stop_wivrn() {
  stop_process "wivrn-server" "${WIVRN_SERVER_PID_FILE}"
}

start_wivrn_gui() {
  start_process "wivrn-dashboard" "wivrn-dashboard" "${WIVRN_DASHBOARD_PID_FILE}" "${WIVRN_DASHBOARD_LOG_FILE}"
}

stop_wivrn_gui() {
  stop_process "wivrn-dashboard" "${WIVRN_DASHBOARD_PID_FILE}"
}

start_wayvr() {
  if is_wayvr_running; then
    echo "WayVR is already running (pid $(<"${WAYVR_PID_FILE}"))."
    return 0
  fi

  start_process "wayvr" "wayvr" "${WAYVR_PID_FILE}" "${WAYVR_LOG_FILE}"
}

stop_wayvr() {
  stop_process "wayvr" "${WAYVR_PID_FILE}"
}

show_status() {
  echo "== WiVRn =="
  if is_running_pid_file "${WIVRN_SERVER_PID_FILE}"; then
    echo "wivrn-server: running (pid $(<"${WIVRN_SERVER_PID_FILE}"))"
  else
    echo "wivrn-server: not running"
  fi
  if is_running_pid_file "${WIVRN_DASHBOARD_PID_FILE}"; then
    echo "wivrn-dashboard: running (pid $(<"${WIVRN_DASHBOARD_PID_FILE}"))"
  else
    echo "wivrn-dashboard: not running"
  fi
  echo
  echo "== WayVR =="
  if is_wayvr_running; then
    echo "Running (pid $(<"${WAYVR_PID_FILE}"))"
  else
    echo "Not running"
  fi
}

show_logs() {
  echo "== WiVRn logs =="
  echo "-- wivrn-server --"
  if [[ -f "${WIVRN_SERVER_LOG_FILE}" ]]; then
    tail -n 60 "${WIVRN_SERVER_LOG_FILE}"
  else
    echo "No wivrn-server logs yet."
  fi
  echo
  echo "-- wivrn-dashboard --"
  if [[ -f "${WIVRN_DASHBOARD_LOG_FILE}" ]]; then
    tail -n 60 "${WIVRN_DASHBOARD_LOG_FILE}"
  else
    echo "No wivrn-dashboard logs yet."
  fi
  echo
  echo "== WayVR logs =="
  if [[ -f "${WAYVR_LOG_FILE}" ]]; then
    tail -n 60 "${WAYVR_LOG_FILE}"
  else
    echo "No WayVR logs yet."
  fi
}

cmd="${1:-help}"

case "${cmd}" in
  start)
    start_wivrn
    start_wayvr
    ;;
  stop)
    stop_wivrn_gui
    stop_wayvr
    stop_wivrn
    ;;
  restart)
    stop_wivrn_gui
    stop_wayvr
    stop_wivrn
    start_wivrn
    start_wayvr
    ;;
  status)
    show_status
    ;;
  logs)
    show_logs
    ;;
  wayvr-start)
    start_wayvr
    ;;
  wayvr-stop)
    stop_wayvr
    ;;
  wivrn-start)
    start_wivrn
    ;;
  wivrn-stop)
    stop_wivrn
    ;;
  wivrn-gui)
    start_wivrn_gui
    ;;
  wivrn-gui-stop)
    stop_wivrn_gui
    ;;
  help|-h|--help)
    print_help
    ;;
  *)
    echo "Unknown command: ${cmd}" >&2
    print_help
    exit 1
    ;;
esac
