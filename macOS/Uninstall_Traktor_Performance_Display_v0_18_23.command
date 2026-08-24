#!/bin/bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
TARGET=""
BACKUP=""

[ -f "$HERE/.last_target" ] && TARGET="$(cat "$HERE/.last_target")"
[ -f "$HERE/.last_backup" ] && BACKUP="$(cat "$HERE/.last_backup")"

if [ -z "$TARGET" ] || [ ! -d "$TARGET" ]; then
  read -r -p "Drag the modified Traktor Pro 4 .app here, then press RETURN: " TARGET
  TARGET="${TARGET#\'}"; TARGET="${TARGET%\'}"
  TARGET="${TARGET#\"}"; TARGET="${TARGET%\"}"
  TARGET="${TARGET//\\ / }"
fi

D2DIR="$TARGET/Contents/Resources/qml/CSI/D2"
[ -d "$D2DIR" ] || { echo "D2 folder not found."; exit 1; }

if [ -z "$BACKUP" ] || [ ! -d "$BACKUP" ]; then
  BACKUP="$(find "$D2DIR" -maxdepth 1 -type d -name 'PerformanceDisplay_BACKUP_v0_18_23_*' | sort | tail -1)"
fi

[ -d "$BACKUP" ] || { echo "Backup not found."; exit 1; }

cp "$BACKUP/D2.qml" "$D2DIR/D2.qml"

for F in NativeDisplayWindow.qml NativeDeckPanel.qml NativeOverviewStripe.qml NativeBeatGridOverlay.qml NativeStripeCueMarkers.qml NativeFxPanel.qml NativeCueMarkerOverlay.qml; do
  if [ -f "$BACKUP/$F" ]; then
    cp "$BACKUP/$F" "$D2DIR/$F"
  else
    rm -f "$D2DIR/$F"
  fi
done

echo "Rollback complete."

HERE="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$HERE/.last_launcher" ]; then
  LAUNCHER="$(cat "$HERE/.last_launcher")"
  if [ -d "$LAUNCHER" ]; then
    rm -rf "$LAUNCHER"
    echo "Removed launcher: $LAUNCHER"
  fi
fi
