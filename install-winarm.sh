diff --git a/install-winarm.sh b/install-winarm.sh
index e22724dad501b1f2a76d3781772a8869859d2302..c858f26443283af4864ed997a0f8f2b16302af09 100644
--- a/install-winarm.sh
+++ b/install-winarm.sh
@@ -1,54 +1,83 @@
 #!/bin/bash
 set -euo pipefail
 
 # This script installs the UEFI layer to the EFI System Partition (ESP).
-# No placeholders inside this file. You MUST provide REPO_BASE at runtime:
+# It prefers payloads stored next to this script, but you can also fetch
+# them remotely by providing REPO_BASE at runtime:
 #   REPO_BASE='https://raw.githubusercontent.com/<owner>/<repo>/main' bash install-winarm.sh
 #
-# REPO_BASE must host:
+# When using REPO_BASE the following files must exist at the URL:
 #   - BOOTAA64.EFI
 #   - startup.nsh
 #
 # Example:
 #   export REPO_BASE="https://raw.githubusercontent.com/winarm-native/winarm-native-boot/main"
 #   bash install-winarm.sh
 
-: "${REPO_BASE:?REPO_BASE not set. See header comments.}"
-
 ESP_DEV="${ESP_DEV_OVERRIDE:-disk0s1}"  # Override if your ESP is not disk0s1
 ESP_MNT="${ESP_MNT_OVERRIDE:-/Volumes/EFI}"
 BOOT_DIR="${ESP_MNT}/EFI/Boot"
 MS_DIR="${ESP_MNT}/EFI/Microsoft/Boot"
 
+SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
+if SCRIPT_DIR="$(cd "$(dirname "${SCRIPT_PATH}")" 2>/dev/null && pwd -P)"; then
+  :
+else
+  SCRIPT_DIR="$(pwd)"
+fi
+LOCAL_BOOTAA64="${SCRIPT_DIR}/BOOTAA64.EFI"
+LOCAL_STARTUP="${SCRIPT_DIR}/startup.nsh"
+USE_LOCAL_PAYLOAD=0
+
+if [[ -r "${LOCAL_BOOTAA64}" && -r "${LOCAL_STARTUP}" ]]; then
+  USE_LOCAL_PAYLOAD=1
+else
+  : "${REPO_BASE:?REPO_BASE not set and local payloads missing. See header comments.}"
+fi
+
 command -v diskutil >/dev/null || { echo "Run this from macOS Recovery (1TR). 'diskutil' not found."; exit 1; }
-command -v curl >/dev/null || { echo "'curl' not found."; exit 1; }
+if [[ "${USE_LOCAL_PAYLOAD}" -eq 0 ]]; then
+  command -v curl >/dev/null || { echo "'curl' not found."; exit 1; }
+fi
 
 echo "[*] Mounting ESP ${ESP_DEV} ..."
 diskutil mount "${ESP_DEV}" || { echo "Failed to mount ${ESP_DEV}. Use 'diskutil list' to locate the ESP."; exit 1; }
 
 mkdir -p "${BOOT_DIR}" "${MS_DIR}"
 
 echo "[*] Ensure m1n1 is enrolled (Asahi minimal). If not, run in 1TR: curl https://alx.sh | sh  (choose Minimal)"
 
 if [[ -n "${SKIP_ENROLLMENT_PROMPT:-}" ]]; then
   echo "[*] SKIP_ENROLLMENT_PROMPT set — continuing without waiting for confirmation."
 elif [[ -t 0 ]]; then
   read -r -p "Press [Enter] to continue if m1n1 is already enrolled (or after completing Asahi minimal)..."
 else
   echo "[*] No interactive TTY detected — continuing without waiting for confirmation."
 fi
 
-echo "[*] Downloading BOOTAA64.EFI from ${REPO_BASE} ..."
-curl -fsSL "${REPO_BASE}/BOOTAA64.EFI" -o "${BOOT_DIR}/BOOTAA64.EFI"
+if [[ "${USE_LOCAL_PAYLOAD}" -eq 1 ]]; then
+  echo "[*] Using bundled BOOTAA64.EFI payload ..."
+  cp "${LOCAL_BOOTAA64}" "${BOOT_DIR}/BOOTAA64.EFI"
+  echo "[*] Using bundled startup.nsh payload ..."
+  cp "${LOCAL_STARTUP}" "${BOOT_DIR}/startup.nsh"
+else
+  echo "[*] Downloading BOOTAA64.EFI from ${REPO_BASE} ..."
+  curl -fsSL "${REPO_BASE}/BOOTAA64.EFI" -o "${BOOT_DIR}/BOOTAA64.EFI"
+
+  echo "[*] Downloading startup.nsh from ${REPO_BASE} ..."
+  curl -fsSL "${REPO_BASE}/startup.nsh" -o "${BOOT_DIR}/startup.nsh"
+fi
 
-echo "[*] Downloading startup.nsh from ${REPO_BASE} ..."
-curl -fsSL "${REPO_BASE}/startup.nsh" -o "${BOOT_DIR}/startup.nsh"
+if [[ ! -s "${BOOT_DIR}/BOOTAA64.EFI" ]]; then
+  echo "[!] BOOTAA64.EFI is empty. Verify your payload source." >&2
+  exit 1
+fi
 
 echo
 echo "[*] If Windows Boot Manager already exists, it should be at:"
 echo "    ${MS_DIR}/bootmgfw.efi"
 echo "    Otherwise, plug a Windows 11 ARM USB installer; startup.nsh will try common FS mappings."
 
 echo
 echo "[+] Done. Reboot → hold Power → choose Asahi/m1n1 → UEFI → Windows."
 echo "    Expect framebuffer-only graphics; Wi‑Fi/BT/Audio not available yet."
