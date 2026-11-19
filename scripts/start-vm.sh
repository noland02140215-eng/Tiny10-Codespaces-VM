#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VM_DIR="${ROOT}/vm"
ISO="${ISO:-${VM_DIR}/Tiny10.iso}"
DISK="${DISK:-${VM_DIR}/tiny10.qcow2}"
VARS="${VM_DIR}/OVMF_VARS.fd"
RAM="${RAM:-3G}"
CPUS="${CPUS:-2}"
DISK_SIZE="${DISK_SIZE:-40G}"
VNC_PORT="${VNC_PORT:-5900}"
WEB_PORT="${WEB_PORT:-6080}"
PIDFILE="${VM_DIR}/qemu.pid"
LOGFILE="${VM_DIR}/qemu.log"

mkdir -p "$VM_DIR"
if [[ ! -f "$ISO" ]]; then
  echo "Tiny10 ISO not found: $ISO"
  echo "Upload your own ISO to vm/Tiny10.iso, or set ISO=/path/to/file.iso"
  exit 1
fi

OVMF_CODE=""
for candidate in /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd /usr/share/ovmf/OVMF.fd; do
  if [[ -f "$candidate" ]]; then OVMF_CODE="$candidate"; break; fi
done
OVMF_VARS_TEMPLATE=""
for candidate in /usr/share/OVMF/OVMF_VARS_4M.fd /usr/share/OVMF/OVMF_VARS.fd; do
  if [[ -f "$candidate" ]]; then OVMF_VARS_TEMPLATE="$candidate"; break; fi
done
if [[ -z "$OVMF_CODE" || -z "$OVMF_VARS_TEMPLATE" ]]; then
  echo "Could not locate OVMF UEFI firmware. Check the ovmf package."
  exit 1
fi
if [[ ! -f "$VARS" ]]; then cp "$OVMF_VARS_TEMPLATE" "$VARS"; fi

if [[ ! -f "$DISK" ]]; then
  echo "Creating ${DISK_SIZE} virtual disk..."
  qemu-img create -f qcow2 "$DISK" "$DISK_SIZE"
fi

if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  echo "QEMU appears to be running (PID $(cat "$PIDFILE"))."
  exit 0
fi
rm -f "$PIDFILE"

# SATA emulation avoids requiring extra VirtIO storage drivers in Windows Setup.
SATA_ARGS=(
  -device ich9-ahci,id=sata
  -drive "file=${DISK},if=none,id=osdisk,format=qcow2"
  -device ide-hd,drive=osdisk,bus=sata.0
)
BOOT_ORDER="c"
if [[ "${BOOT_ISO:-1}" == "1" ]]; then
  SATA_ARGS+=(
    -drive "file=${ISO},media=cdrom,readonly=on,if=none,id=installmedia"
    -device ide-cd,drive=installmedia,bus=sata.1
  )
  BOOT_ORDER="d"
fi

ACCEL=( -accel tcg,thread=multi )
if [[ -c /dev/kvm && -r /dev/kvm && -w /dev/kvm ]]; then
  ACCEL=( -accel kvm )
  echo "KVM device detected; attempting KVM acceleration."
else
  echo "KVM unavailable; using TCG software emulation (may be slow)."
fi

echo "Starting Tiny10 VM. QEMU log: $LOGFILE"
qemu-system-x86_64 \
  -name "Tiny10-Codespaces" \
  -machine q35 \
  "${ACCEL[@]}" \
  -cpu max \
  -smp "$CPUS" \
  -m "$RAM" \
  -drive "if=pflash,format=raw,readonly=on,file=${OVMF_CODE}" \
  -drive "if=pflash,format=raw,file=${VARS}" \
  "${SATA_ARGS[@]}" \
  -boot "order=${BOOT_ORDER},menu=on" \
  -vga std \
  -display none \
  -vnc "0.0.0.0:${VNC_PORT#590}" \
  -pidfile "$PIDFILE" \
  -daemonize \
  -D "$LOGFILE"

if pgrep -af "websockify.*${WEB_PORT}" >/dev/null; then
  echo "A websockify process already appears to be listening on port ${WEB_PORT}."
else
  nohup websockify --web=/usr/share/novnc \
    "0.0.0.0:${WEB_PORT}" "127.0.0.1:${VNC_PORT}" \
    >"${VM_DIR}/websockify.log" 2>&1 &
  echo $! > "${VM_DIR}/websockify.pid"
fi

echo
echo "VM started. Open forwarded port ${WEB_PORT} in the Codespaces Ports tab."
echo "If the noVNC page does not auto-connect, click Connect."
