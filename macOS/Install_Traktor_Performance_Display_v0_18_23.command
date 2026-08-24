#!/bin/bash
set -euo pipefail

VERSION="v0.18.23"
EXPECTED_CLEAN_D2="8bdfde9883f379796ddcc848eae78c39986bce15c9bdbb46620f3ab24388b838"
EXPECTED_PATCHED_D2="bbd8d2c351178c50f81651cfaf78c2e4c7fbba7a210b0e0640e7b05f33ae93cf"
HERE="$(cd "$(dirname "$0")" && pwd)"
PAYLOAD="$HERE/payload"

fail() {
  echo
  echo "ERROR: $*"
  echo "Nothing further was changed."
  exit 1
}

clean_drag_path() {
  local p="$1"
  p="${p#\'}"; p="${p%\'}"
  p="${p#\"}"; p="${p%\"}"
  p="${p//\\ / }"
  printf "%s" "$p"
}

sha256() {
  shasum -a 256 "$1" | awk '{print $1}'
}

echo "Traktor Performance Display $VERSION — macOS"
echo "================================================"
echo
echo "This installer patches EXACTLY the Traktor .app you drag in."
echo
echo "RECOMMENDED:"
echo "  1. Quit Traktor."
echo "  2. Duplicate your clean Traktor Pro 4.5.0.7 app in Finder yourself."
echo "  3. Rename the duplicate if you want."
echo "  4. Drag THAT DUPLICATE into this installer."
echo
read -r -p "Drag the exact Traktor Pro 4.5.0.7 .app you want to patch here, then press RETURN: " TARGET_RAW
TARGET="$(clean_drag_path "$TARGET_RAW")"
[ -d "$TARGET" ] || fail "App not found: $TARGET"

echo
echo "ABOUT TO PATCH:"
echo "  $TARGET"
echo
read -r -p "Type Y or YES to continue (RETURN alone cancels): " CONFIRM
case "$(printf "%s" "$CONFIRM" | tr '[:lower:]' '[:upper:]')" in
  Y|YES) ;;
  *) fail "Installation cancelled." ;;
esac

D2DIR="$TARGET/Contents/Resources/qml/CSI/D2"
D2="$D2DIR/D2.qml"
[ -f "$D2" ] || fail "D2.qml not found at $D2"

echo
echo "[1/6] Checking Traktor target..."
CURRENT="$(sha256 "$D2")"
if [ "$CURRENT" = "$EXPECTED_PATCHED_D2" ]; then
  echo "  Existing Performance Display D2 detected."
  echo "  Installer will repair/refresh the payload."
elif [ "$CURRENT" = "$EXPECTED_CLEAN_D2" ]; then
  echo "  Clean Traktor 4.5.0.7 D2.qml verified."
else
  fail "Unsupported D2.qml. This installer is locked to the known Traktor Pro 4.5.0.7 D2 file."
fi

FILES=(
  D2.qml
  NativeDisplayWindow.qml
  NativeDeckPanel.qml
  NativeOverviewStripe.qml
  NativeBeatGridOverlay.qml
  NativeStripeCueMarkers.qml
  NativeFxPanel.qml
  NativeCueMarkerOverlay.qml
)

for F in "${FILES[@]}"; do
  [ -f "$PAYLOAD/$F" ] || fail "Payload missing: $F"
done

echo "[2/6] Backing up current files..."
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$D2DIR/PerformanceDisplay_BACKUP_v0_18_23_$STAMP"
mkdir -p "$BACKUP"
for F in "${FILES[@]}"; do
  [ -f "$D2DIR/$F" ] && cp "$D2DIR/$F" "$BACKUP/$F" || true
done
printf "%s\n" "$TARGET" > "$HERE/.last_target"
printf "%s\n" "$BACKUP" > "$HERE/.last_backup"

echo "[3/6] Installing Performance Display QML..."
for F in "${FILES[@]}"; do
  cp "$PAYLOAD/$F" "$D2DIR/$F"
done

echo "[4/6] Verifying installed payload..."

if [ "$(sha256 "$D2DIR/NativeFxPanel.qml")" != "fc09f9cce27d6725af3da6cbde1652bcd680f5c40550258f358e6eeea5484afc" ]; then
  fail "Verification failed for NativeFxPanel.qml"
fi
echo "  OK: NativeFxPanel.qml"

if [ "$(sha256 "$D2DIR/NativeCueMarkerOverlay.qml")" != "eb68d2cab82bfd36cacdabe6943071236cb1e1222ba2430349bc0143c20b7235" ]; then
  fail "Verification failed for NativeCueMarkerOverlay.qml"
fi
echo "  OK: NativeCueMarkerOverlay.qml"

if [ "$(sha256 "$D2DIR/NativeBeatGridOverlay.qml")" != "4e8104621097dd8322820f748c33536d70c6d6bc5d7ba25920ea654d94704eb4" ]; then
  fail "Verification failed for NativeBeatGridOverlay.qml"
fi
echo "  OK: NativeBeatGridOverlay.qml"

if [ "$(sha256 "$D2DIR/NativeDeckPanel.qml")" != "2c84c8cc73b87fbd10e36366966b9de4a30e29fde894023d0cb8f53c4425d3eb" ]; then
  fail "Verification failed for NativeDeckPanel.qml"
fi
echo "  OK: NativeDeckPanel.qml"

if [ "$(sha256 "$D2DIR/NativeDisplayWindow.qml")" != "3a7f2512866e2df3a0cd723d0c7cde2b97f16e896a6325fee6edb435303a0d95" ]; then
  fail "Verification failed for NativeDisplayWindow.qml"
fi
echo "  OK: NativeDisplayWindow.qml"

if [ "$(sha256 "$D2DIR/NativeOverviewStripe.qml")" != "28b24ff560f83c1f27fd98f905982bb3f6551cf632716471ada5ee5d191117a5" ]; then
  fail "Verification failed for NativeOverviewStripe.qml"
fi
echo "  OK: NativeOverviewStripe.qml"

if [ "$(sha256 "$D2DIR/NativeStripeCueMarkers.qml")" != "5f54d153c06d9c3862d214189bc8c2cb028de8a6ca10ea713c914ed7673613c5" ]; then
  fail "Verification failed for NativeStripeCueMarkers.qml"
fi
echo "  OK: NativeStripeCueMarkers.qml"

if [ "$(sha256 "$D2DIR/D2.qml")" != "bbd8d2c351178c50f81651cfaf78c2e4c7fbba7a210b0e0640e7b05f33ae93cf" ]; then
  fail "Verification failed for D2.qml"
fi
echo "  OK: D2.qml"

if ! grep -q "StandaloneDisplay4507" "$D2"; then
  fail "D2 hook verification failed: StandaloneDisplay4507 marker missing."
fi
if ! grep -q 'NativeDisplayWindow.qml' "$D2"; then
  fail "D2 hook verification failed: NativeDisplayWindow.qml reference missing."
fi
echo "  D2 standalone-display hook verified."

echo "[5/6] Creating Finder launcher..."
PARENT="$(dirname "$TARGET")"
BASENAME="$(basename "$TARGET" .app)"
LAUNCHER="$PARENT/${BASENAME} Performance Display Launcher.app"
COUNTER=2
while [ -e "$LAUNCHER" ]; do
  LAUNCHER="$PARENT/${BASENAME} Performance Display Launcher $COUNTER.app"
  COUNTER=$((COUNTER+1))
done

mkdir -p "$LAUNCHER/Contents/MacOS"
cat > "$LAUNCHER/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>Traktor Performance Display Launcher</string>
  <key>CFBundleDisplayName</key>
  <string>Traktor Performance Display Launcher</string>
  <key>CFBundleIdentifier</key>
  <string>local.traktor.performance.display.launcher</string>
  <key>CFBundleVersion</key>
  <string>0.18.23</string>
  <key>CFBundleShortVersionString</key>
  <string>0.18.23</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleExecutable</key>
  <string>launch</string>
</dict>
</plist>
EOF

TARGET_ESCAPED="$(printf '%q' "$TARGET")"
cat > "$LAUNCHER/Contents/MacOS/launch" <<EOF
#!/bin/bash
TARGET=$TARGET_ESCAPED
EXE=\$(plutil -extract CFBundleExecutable raw "\$TARGET/Contents/Info.plist")
exec "\$TARGET/Contents/MacOS/\$EXE"
EOF
chmod +x "$LAUNCHER/Contents/MacOS/launch"

# Locally generated wrapper: ad-hoc sign only the wrapper itself, not Traktor.
codesign --force --sign - "$LAUNCHER" >/dev/null 2>&1 || true
printf "%s\n" "$LAUNCHER" > "$HERE/.last_launcher"

echo "  Launcher created:"
echo "  $LAUNCHER"

echo "[6/6] Installation complete."
echo
echo "SUCCESS"
echo "======="
echo "Modified Traktor:"
echo "  $TARGET"
echo
echo "Finder launcher:"
echo "  $LAUNCHER"
echo
echo "The installer verified:"
echo "  - the supported D2 target"
echo "  - all 8 installed QML files"
echo "  - the D2 standalone-display hook"
echo "  - the NativeDisplayWindow reference"
echo
echo "D2 REQUIREMENT:"
echo "  A Traktor Kontrol D2 mapping must exist in"
echo "  Preferences > Controller Manager."
echo
read -r -p "Launch the modified Traktor now? [Y/n]: " RUNNOW
case "$(printf "%s" "$RUNNOW" | tr '[:lower:]' '[:upper:]')" in
  N|NO) ;;
  *) open "$LAUNCHER" ;;
esac
