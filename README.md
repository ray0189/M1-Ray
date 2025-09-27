# Native Windows 11 ARM Boot on Apple Silicon (Minimal Chain)

Boot chain:
```
Apple ROM → iBoot → m1n1 → EDK2/Project-Mu (UEFI) → Windows Boot Manager → Windows 11 ARM
```

This repo contains:
- `install-winarm.sh` — installer to copy the UEFI payloads to the EFI System Partition (ESP). No placeholders inside; you pass `REPO_BASE` at runtime.
- `startup.nsh` — UEFI shell script to locate Windows Boot Manager or a USB installer.
- `.github/workflows/build-mu.yml` — builds `BOOTAA64.EFI` from AppleWOA's Project‑Mu and attaches it to **Latest Release** (optional CI).

## Requirements
- **m1n1** enrolled once (Asahi minimal): `curl https://alx.sh | sh` → choose **Minimal**.
- macOS Recovery (1TR) Terminal to run the installer.
- Windows 11 ARM installer (USB) or an already‑installed Windows partition.

## Quick start (1TR Terminal)
Replace the URL with your repo's raw main branch:
```bash
export REPO_BASE="https://raw.githubusercontent.com/<owner>/<repo>/main"
bash -c "$(curl -fsSL ${REPO_BASE}/install-winarm.sh)"
```

If your ESP is not `disk0s1`:
```bash
ESP_DEV_OVERRIDE=diskXs1 REPO_BASE="https://raw.githubusercontent.com/<owner>/<repo>/main" bash -c "$(curl -fsSL ${REPO_BASE}/install-winarm.sh)"
```

## ESP layout after install
```
/EFI
  /Boot
    BOOTAA64.EFI
    startup.nsh
  /Microsoft
    /Boot
      bootmgfw.efi
```

## Notes
- Framebuffer‑only graphics (no Apple GPU acceleration).
- Wi‑Fi/BT/Audio not available yet.
- Use USB HID keyboard/mouse; optional USB‑C Ethernet for network.
