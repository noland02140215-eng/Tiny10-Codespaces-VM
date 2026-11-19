# Tiny10 VM in GitHub Codespaces

This project runs a **QEMU x86-64 virtual machine** inside a GitHub Codespace and exposes its display through noVNC in your browser.

You must provide your own Tiny10 x64 ISO. This repository does not include Windows/Tiny10 installation media or product keys.

## Important performance and compatibility notes

- A Codespace is a container, not a full hypervisor host.
- `/dev/kvm` is often unavailable. The launcher automatically uses QEMU TCG software emulation when KVM cannot be opened.
- TCG can be very slow for Windows. A larger Codespace improves available RAM and CPU resources but does not guarantee hardware virtualization.
- This is a best-effort hobby/lab setup, not a supported production VM host.
- The VM disk is stored in the Codespace workspace under `vm/`. Keep the Codespace and workspace; deleting them can delete the virtual disk.
- The web console port is configured as **private**. Do not make it public.

## Start a Codespace

1. In GitHub, choose **Code → Codespaces → Create codespace on main**.
2. Wait for the devcontainer to finish building.
3. Upload your own Tiny10 x64 ISO into the `vm/` directory. Name it `Tiny10.iso` (or use the `ISO` environment variable). Use the VS Code Explorer upload action.
4. In the Codespace terminal, run:

   ```bash
   chmod +x scripts/*.sh
   ./scripts/start-vm.sh
   ```

5. Open forwarded port **6080**. The noVNC page should appear. Click **Connect** to view the VM.

## First boot / Windows installation

The launcher creates a 40 GiB qcow2 virtual disk on first run and attaches the ISO as a virtual DVD. Follow Windows Setup in the browser console. When setup reboots, QEMU may boot from the ISO again; use the VM boot menu or stop the VM and restart without the ISO:

```bash
BOOT_ISO=0 ./scripts/start-vm.sh
```

After Windows is installed, use `BOOT_ISO=0` for normal boots.

## Useful commands

Stop QEMU:

```bash
./scripts/stop-vm.sh
```

Start from the installed virtual disk:

```bash
BOOT_ISO=0 ./scripts/start-vm.sh
```

Choose a larger virtual disk on first creation:

```bash
DISK_SIZE=64G ./scripts/start-vm.sh
```

Choose RAM and CPU count:

```bash
RAM=3G CPUS=2 ./scripts/start-vm.sh
```

Override the ISO path:

```bash
ISO="$PWD/vm/my-tiny10.iso" ./scripts/start-vm.sh
```

## UEFI

The launcher uses OVMF UEFI firmware from the Ubuntu `ovmf` package. It creates a writable `OVMF_VARS.fd` copy in `vm/` and uses the package's read-only code firmware. Secure Boot is not enabled by this default OVMF configuration.

## Troubleshooting

- **No ISO found:** Put `Tiny10.iso` in `vm/` or set `ISO=/path/to/file.iso`.
- **KVM permission/device error:** The script falls back to TCG. Performance will be slower.
- **Black screen:** Wait a minute, refresh noVNC, and confirm QEMU is running with `pgrep -af qemu-system`.
- **Port not opening:** In the Codespaces Ports tab, make sure port 6080 is forwarded and remains private.
- **Out of memory:** Stop the VM and restart with a smaller `RAM` value.
- **Disk full:** The qcow2 disk grows as Windows uses it; check Codespace storage limits.
- **No audio / USB passthrough:** Not configured in this minimal template.

This project is an educational VM launcher. It does not bypass Windows activation, licensing, or hardware requirements.
