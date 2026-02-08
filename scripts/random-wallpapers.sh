#!/bin/bash
set -euo pipefail

# Per-monitor wallpapers via Plasma's DBus scripting API (plasma-apply-wallpaperimage
# has no per-output support). Desktops are indexed left-to-right by screen position;
# adjust LEFT_INDEX/RIGHT_INDEX if your vertical/ultrawide are the other way around.
LEFT_INDEX=0   # leftmost monitor (vertical in typical setup)
RIGHT_INDEX=1  # second monitor (ultrawide)

VERTICAL_DIR="/mnt/qnap/HDD/AI Wallpapers/Realistic werewolf/vertical"
ULTRAWIDE_DIR="/mnt/qnap/HDD/AI Wallpapers/Realistic werewolf/ultrawide"

# Pick a random .webp from each folder
VERT_IMG=$(find "$VERTICAL_DIR" -type f -iname "*.webp" | shuf -n 1)
WIDE_IMG=$(find "$ULTRAWIDE_DIR" -type f -iname "*.webp" | shuf -n 1)

if [[ -z "${VERT_IMG:-}" ]]; then
  echo "No .webp files found in: $VERTICAL_DIR" >&2
  exit 1
fi

if [[ -z "${WIDE_IMG:-}" ]]; then
  echo "No .webp files found in: $ULTRAWIDE_DIR" >&2
  exit 1
fi

# When run from a terminal, show what we're setting (so you see activity and can debug)
if [[ -t 1 ]]; then
  echo "Left (vertical):  $VERT_IMG"
  echo "Right (ultrawide): $WIDE_IMG"
fi

# Plasma expects file:// URLs for wallpaper Image config; then escape for JS string
path_to_file_url() {
  printf 'file://%s' "$(printf '%s' "$1" | sed 's/ /%20/g; s/\[/%5B/g; s/\]/%5D/g; s/#/%23/g; s/?/%3F/g; s/&/%26/g')"
}
escape_js() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/'"'"'/\\'"'"'/g'
}
VERT_URL=$(path_to_file_url "$VERT_IMG")
WIDE_URL=$(path_to_file_url "$WIDE_IMG")
VERT_ESC=$(escape_js "$VERT_URL")
WIDE_ESC=$(escape_js "$WIDE_URL")

# Screen 0 = ultrawide image, screen 1 = vertical image (Plasma's screen order was opposite physical left/right)
# Use desktopForScreen(screen, 0). reloadConfig() applies; sleep(300) lets it take effect.
# Build script with placeholders then substitute so paths are never literal/unexpanded.
SCRIPT_TEMPLATE='function setW(screen,path){var d=desktopForScreen(screen,0); if(!d){return;} d.wallpaperPlugin="org.kde.image"; d.currentConfigGroup=Array("Wallpaper","org.kde.image","General"); d.writeConfig("Image",path); d.reloadConfig();} setW(LEFTID, '\''WIDEPATH'\''); setW(RIGHTID, '\''VERTPATH'\''); sleep(300);'
SCRIPT="${SCRIPT_TEMPLATE/LEFTID/$LEFT_INDEX}"
SCRIPT="${SCRIPT/RIGHTID/$RIGHT_INDEX}"
SCRIPT="${SCRIPT/VERTPATH/$VERT_ESC}"
SCRIPT="${SCRIPT/WIDEPATH/$WIDE_ESC}"

# Plasma 6 typically has qdbus6 (Arch/CachyOS); fallbacks: qdbus-qt6, qdbus
if command -v qdbus6 &>/dev/null; then
  qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$SCRIPT"
elif command -v qdbus-qt6 &>/dev/null; then
  qdbus-qt6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$SCRIPT"
else
  qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$SCRIPT"
fi

if [[ -t 1 ]]; then
  echo "Done."
fi
