#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VM_DIR="${ROOT}/vm"

if [[ -f "${VM_DIR}/qemu.pid" ]]; then
  pid="$(cat "${VM_DIR}/qemu.pid")"
  if kill -0 "$pid" 2>/dev/null; then
    kill "$pid"
    echo "Stopped QEMU (PID $pid)."
  else
    echo "QEMU process was not running."
  fi
  rm -f "${VM_DIR}/qemu.pid"
else
  echo "No QEMU PID file found."
fi

if [[ -f "${VM_DIR}/websockify.pid" ]]; then
  pid="$(cat "${VM_DIR}/websockify.pid")"
  kill "$pid" 2>/dev/null || true
  rm -f "${VM_DIR}/websockify.pid"
fi
