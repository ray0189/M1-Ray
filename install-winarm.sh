#!/bin/bash
set -euo pipefail

# This script installs the UEFI layer to the EFI System Partition (ESP).
# No placeholders inside this file. You MUST provide REPO_BASE at runtime:
#   REPO_BASE='https://raw.githubusercontent.com/<owner>/<repo>/main' bash install-winarm.sh
#
# REPO_BASE must host:
#   - BOOTAA64.EFI
#   - startup.nsh
#
# Example:
#   export REPO_BASE="https://raw.githubusercontent.com/winarm-native/winarm-native-boot/main"
#   bash install-winarm.sh

: "${REPO_BASE:?REPO_BASE not set. See header comments.}"

ESP_DEV="${ESP_DEV_OVERRIDE:-disk0s1}"  # Override if your ESP is not disk0s1
ESP_MNT="/Volumes/EFI"
BOOT_DIR="${ESP_MNT}/EFI/Boot"
MS_DIR="${ESP_MNT}/EFI/Microsoft/Boot"

command -v diskutil >/dev/null || { echo "Run this from macOS Recovery (1TR). 'diskutil' not found."; exit 1; }
command -v curl >/dev/null || { echo "'curl' not found."; exit 1; }

echo "[*] Mounting ESP ${ESP_DEV} ..."
diskutil mount "${ESP_DEV}" || { echo "Failed to mount ${ESP_DEV}. Use 'diskutil list' to locate the ESP."; exit 1; }

mkdir -p "${BOOT_DIR}" "${MS_DIR}"

echo "[*] Ensure m1n1 is enrolled (Asahi minimal). If not, run in 1TR: curl https://alx.sh | sh  (choose Minimal)"
read -p "Press [Enter] to continue if m1n1 is already enrolled (or after completing Asahi minimal)..."

echo "[*] Downloading BOOTAA64.EFI from ${REPO_BASE} ..."
curl -fsSL "${REPO_BASE}/BOOTAA64.EFI" -o "${BOOT_DIR}/BOOTAA64.EFI"

echo "[*] Downloading startup.nsh from ${REPO_BASE} ..."
curl -fsSL "${REPO_BASE}/startup.nsh" -o "${BOOT_DIR}/startup.nsh"

echo
echo "[*] If Windows Boot Manager already exists, it should be at:"
echo "    ${MS_DIR}/bootmgfw.efi"
echo "    Otherwise, plug a Windows 11 ARM USB installer; startup.nsh will try common FS mappings."

echo
echo "[+] Done. Reboot → hold Power → choose Asahi/m1n1 → UEFI → Windows."
echo "    Expect framebuffer-only graphics; Wi‑Fi/BT/Audio not available yet."
