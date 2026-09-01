#!/bin/bash
set -euo pipefail

VERSION="v0.18.24"
EXPECTED_CLEAN_D2="8bdfde9883f379796ddcc848eae78c39986bce15c9bdbb46620f3ab24388b838"
EXPECTED_PATCHED_D2="bbd8d2c351178c50f81651cfaf78c2e4c7fbba7a210b0e0640e7b05f33ae93cf"
HERE="$(cd "$(dirname "$0")" && pwd)"
PAYLOAD="$HERE/payload"
TEMP_PAYLOAD=""

cleanup() {
  [ -n "$TEMP_PAYLOAD" ] && rm -rf "$TEMP_PAYLOAD" || true
}
trap cleanup EXIT

prepare_payload() {
  if [ -d "$PAYLOAD" ]; then
    return
  fi
  echo "  Local payload folder not found; downloading the known v0.18.23 payload from GitHub..."
  TEMP_PAYLOAD="$(mktemp -d)"
  PAYLOAD="$TEMP_PAYLOAD/payload"
  mkdir -p "$PAYLOAD"
  local base="https://raw.githubusercontent.com/Nego-sound/Traktor-Performance-Display/e4d4f0c1e749b48f2a531e55a39fc284f377fd4d/macOS/payload"
  local files=(D2.qml NativeDisplayWindow.qml NativeDeckPanel.qml NativeOverviewStripe.qml NativeBeatGridOverlay.qml NativeStripeCueMarkers.qml NativeFxPanel.qml NativeCueMarkerOverlay.qml)
  for f in "${files[@]}"; do
    /usr/bin/curl -L --fail --silent --show-error "$base/$f" -o "$PAYLOAD/$f" || fail "Could not download $f from the GitHub payload."
  done
}

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
echo "[1/7] Checking Traktor target..."
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

prepare_payload
for F in "${FILES[@]}"; do
  [ -f "$PAYLOAD/$F" ] || fail "Payload missing: $F"
done

echo "[2/7] Backing up current files..."
STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$D2DIR/PerformanceDisplay_BACKUP_v0_18_24_$STAMP"
mkdir -p "$BACKUP"
for F in "${FILES[@]}"; do
  [ -f "$D2DIR/$F" ] && cp "$D2DIR/$F" "$BACKUP/$F" || true
done
printf "%s\n" "$TARGET" > "$HERE/.last_target"
printf "%s\n" "$BACKUP" > "$HERE/.last_backup"

echo "[3/7] Installing Performance Display QML..."
for F in "${FILES[@]}"; do
  cp "$PAYLOAD/$F" "$D2DIR/$F"
done

echo "[4/7] Verifying base payload..."
[ "$(sha256 "$D2DIR/NativeFxPanel.qml")" = "fc09f9cce27d6725af3da6cbde1652bcd680f5c40550258f358e6eeea5484afc" ] || fail "Verification failed for NativeFxPanel.qml"
[ "$(sha256 "$D2DIR/NativeCueMarkerOverlay.qml")" = "eb68d2cab82bfd36cacdabe6943071236cb1e1222ba2430349bc0143c20b7235" ] || fail "Verification failed for NativeCueMarkerOverlay.qml"
[ "$(sha256 "$D2DIR/NativeBeatGridOverlay.qml")" = "4e8104621097dd8322820f748c33536d70c6d6bc5d7ba25920ea654d94704eb4" ] || fail "Verification failed for NativeBeatGridOverlay.qml"
[ "$(sha256 "$D2DIR/NativeDeckPanel.qml")" = "2c84c8cc73b87fbd10e36366966b9de4a30e29fde894023d0cb8f53c4425d3eb" ] || fail "Verification failed for NativeDeckPanel.qml"
[ "$(sha256 "$D2DIR/NativeDisplayWindow.qml")" = "3a7f2512866e2df3a0cd723d0c7cde2b97f16e896a6325fee6edb435303a0d95" ] || fail "Verification failed for NativeDisplayWindow.qml"
[ "$(sha256 "$D2DIR/NativeOverviewStripe.qml")" = "28b24ff560f83c1f27fd98f905982bb3f6551cf632716471ada5ee5d191117a5" ] || fail "Verification failed for NativeOverviewStripe.qml"
[ "$(sha256 "$D2DIR/NativeStripeCueMarkers.qml")" = "5f54d153c06d9c3862d214189bc8c2cb028de8a6ca10ea713c914ed7673613c5" ] || fail "Verification failed for NativeStripeCueMarkers.qml"
[ "$(sha256 "$D2DIR/D2.qml")" = "$EXPECTED_PATCHED_D2" ] || fail "Verification failed for D2.qml"

echo "[5/7] Applying v0.18.24 UI + VU changes..."
python3 - "$D2DIR" <<'PY'
from pathlib import Path
import sys

root = Path(sys.argv[1])

def patch_file(name, replacements):
    p = root / name
    text = p.read_text()
    for old, new in replacements:
        if old not in text:
            raise SystemExit(f"Patch marker not found in {name}: {old[:70]!r}")
        text = text.replace(old, new, 1)
    p.write_text(text)

patch_file("NativeDeckPanel.qml", [
    ("property int zoomIndex: 10", "property int zoomIndex: 9"),
    (
'''    AppProperty { id: channelFilter;     path: "app.traktor.mixer.channels." + root.appDeck + ".fx.adjust" }
''',
'''    AppProperty { id: channelFilter;     path: "app.traktor.mixer.channels." + root.appDeck + ".fx.adjust" }
    AppProperty { id: channelLevel;      path: "app.traktor.mixer.channels." + root.appDeck + ".level.prefader.linear.meter" }
'''
    ),
    (
'''    readonly property int stemPanelWidth: 70
    readonly property int stemPanelGap: 8
    readonly property int mixerPanelBaseX: 0
    readonly property int mixerPanelStemX: stemPanelWidth + stemPanelGap + 8
    readonly property int mixerPanelX: isStemDeck && showStemVolumes ? mixerPanelStemX : mixerPanelBaseX
    readonly property int zoomBaseX: 186
    readonly property int zoomStemX: mixerPanelStemX + 186
''',
'''    readonly property int channelVuWidth: 14
    readonly property int channelVuGap: 6
    readonly property int stemPanelWidth: 70
    readonly property int stemPanelGap: 8
    readonly property int mixerPanelBaseX: channelVuWidth + channelVuGap
    readonly property int mixerPanelStemX: mixerPanelBaseX + stemPanelWidth + stemPanelGap + 8
    readonly property int mixerPanelX: isStemDeck && showStemVolumes ? mixerPanelStemX : mixerPanelBaseX
    readonly property int zoomBaseX: mixerPanelBaseX + 186
    readonly property int zoomStemX: mixerPanelStemX + 186
'''
    ),
    (
'''    function stemName(i) {
''',
'''    function channelMeterValue() {
        var v = Number(channelLevel.value)
        if (!isFinite(v)) return 0
        return Math.max(0, Math.min(1, v))
    }

    function stemName(i) {
'''
    ),
    (
'''                        text: artistProp.value || ""
                        color: "#b6bec7"
                        font.pixelSize: 15
''',
'''                        text: artistProp.value || ""
                        color: "#b6bec7"
                        font.pixelSize: 17
'''
    ),
    (
'''                            text: "LOOP"
                            color: loopActive.value ? "#c8ffdc" : "#7fad90"
                            font.pixelSize: 8
''',
'''                            text: "LOOP"
                            color: loopActive.value ? "#c8ffdc" : "#7fad90"
                            font.pixelSize: 11
'''
    ),
    (
'''                    x: 8
                    y: Math.round((parent.height - height) / 2)
''',
'''                    x: root.mixerPanelBaseX + 8
                    y: Math.round((parent.height - height) / 2)
'''
    ),
    (
'''                // Floating zoom on left (moves beside Stem volumes on Stem Decks).
''',
'''                Rectangle {
                    id: channelVu
                    width: root.channelVuWidth
                    height: parent.height - 16
                    x: 2
                    y: 8
                    radius: 4
                    color: "#070a0e"
                    border.color: "#46515c"
                    border.width: 1
                    z: 34

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 2
                        height: Math.max(0, (parent.height - 4) * root.channelMeterValue())
                        radius: 2
                        color: root.channelMeterValue() >= 0.93 ? "#ff4949"
                             : root.channelMeterValue() >= 0.78 ? "#ffae32"
                                                               : "#36d477"
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.leftMargin: 1
                        anchors.rightMargin: 1
                        height: 2
                        color: "#ff8b27"
                        opacity: 0.95
                    }
                }

                // Floating zoom on left (moves beside Stem volumes on Stem Decks).
'''
    ),
])

patch_file("NativeFxPanel.qml", [
    (
'''            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "FX " + root.unit
''',
'''            Text {
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: "FX " + root.unit
'''
    ),
])

(root / "NativeBeatGridOverlay.qml").write_text('''import CSI 1.0
import QtQuick 2.12
import Traktor.Gui 1.0 as Traktor

Traktor.Beatgrid {
    id: grid
    property var waveformPosition
    property var barMarkers: []

    function updateBarMarkers() {
        if (!grid.beatMarkers || grid.beatMarkers.length === 0 ||
            !grid.gridMarkers || grid.gridMarkers.length === 0) {
            barMarkers = []
            return
        }

        var firstGrid = grid.gridMarkers[0]
        for (var g = 1; g < grid.gridMarkers.length; ++g) {
            if (grid.gridMarkers[g] < firstGrid)
                firstGrid = grid.gridMarkers[g]
        }

        var start = 0
        while (start < grid.beatMarkers.length && grid.beatMarkers[start] < firstGrid)
            ++start

        if (start >= grid.beatMarkers.length) {
            barMarkers = []
            return
        }

        var out = []
        for (var i = start; i < grid.beatMarkers.length; i += 4)
            out.push(grid.beatMarkers[i])
        barMarkers = out
    }

    onBeatMarkersChanged: updateBarMarkers()
    onGridMarkersChanged: updateBarMarkers()
    Component.onCompleted: updateBarMarkers()

    Traktor.WaveformTranslator {
        anchors.fill: parent
        followTarget: grid.waveformPosition
        pos: 0
        useScaling: true
        visible: grid.beatMarkers && grid.beatMarkers.length > 0

        Traktor.BeatgridLines {
            anchors.fill: parent
            beatMarkerList: grid.beatMarkers
            color: Qt.rgba(1, 1, 1, 0.25)
        }

        Traktor.BeatgridLines {
            anchors.fill: parent
            beatMarkerList: grid.barMarkers
            color: Qt.rgba(1, 1, 1, 0.68)
        }
    }
}
''')

patch_file("NativeDisplayWindow.qml", [
    (
'''    AppProperty { id: deckALoadSignal; path: "app.traktor.decks.1.is_loaded_signal" }
    AppProperty { id: deckBLoadSignal; path: "app.traktor.decks.2.is_loaded_signal" }
''',
'''    AppProperty { id: deckALoadSignal; path: "app.traktor.decks.1.is_loaded_signal" }
    AppProperty { id: deckBLoadSignal; path: "app.traktor.decks.2.is_loaded_signal" }
    AppProperty { id: masterLevelLeft;  path: "app.traktor.mixer.master.level.left" }
    AppProperty { id: masterLevelRight; path: "app.traktor.mixer.master.level.right" }
    AppProperty { id: masterClipLeft;   path: "app.traktor.mixer.master.level.clip.left" }
    AppProperty { id: masterClipRight;  path: "app.traktor.mixer.master.level.clip.right" }

    function meterValue(v) {
        var n = Number(v)
        if (!isFinite(n)) return 0
        return Math.max(0, Math.min(1, n))
    }
'''
    ),
    (
'''    readonly property int sectionGap: Math.max(4, Math.round(8 * scaleFactor))
''',
'''    readonly property int sectionGap: Math.max(4, Math.round(8 * scaleFactor))
    readonly property int masterMeterWidth: Math.max(48, Math.round(56 * scaleFactor))
'''
    ),
    (
'''        Column {
            anchors.fill: parent
            anchors.margins: win.outerMargin
            spacing: win.sectionGap
''',
'''        Rectangle {
            id: masterVu
            width: win.masterMeterWidth
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.topMargin: win.outerMargin
            anchors.bottomMargin: win.outerMargin
            anchors.rightMargin: win.outerMargin
            radius: 6
            color: "#0a0e13"
            border.color: "#34404b"
            border.width: 1
            z: 35

            Text {
                anchors.top: parent.top
                anchors.topMargin: 7
                anchors.horizontalCenter: parent.horizontalCenter
                text: "MASTER"
                color: "#c9d1d9"
                font.pixelSize: 8
                font.bold: true
            }

            Text {
                anchors.top: parent.top
                anchors.topMargin: 21
                anchors.horizontalCenter: parent.horizontalCenter
                text: "0 dB"
                color: "#ff9a22"
                font.pixelSize: 8
                font.bold: true
            }

            Item {
                id: masterBars
                anchors.top: parent.top
                anchors.topMargin: 38
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 18
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 8
                anchors.rightMargin: 8

                Rectangle {
                    width: 2
                    height: parent.height
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "#252d35"
                }

                Repeater {
                    model: 2
                    delegate: Item {
                        width: (masterBars.width - 6) / 2
                        height: masterBars.height
                        x: index === 0 ? 0 : masterBars.width - width

                        Rectangle {
                            anchors.fill: parent
                            radius: 3
                            color: "#050709"
                            border.color: "#29333d"
                            border.width: 1
                        }

                        readonly property real level: index === 0 ? win.meterValue(masterLevelLeft.value)
                                                                  : win.meterValue(masterLevelRight.value)
                        readonly property bool clipped: index === 0 ? !!masterClipLeft.value
                                                                    : !!masterClipRight.value

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 2
                            height: Math.max(0, (parent.height - 6) * parent.level)
                            radius: 2
                            color: parent.level >= 0.93 ? "#ff4949"
                                 : parent.level >= 0.78 ? "#ffae32"
                                                        : "#36d477"
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.leftMargin: 1
                            anchors.rightMargin: 1
                            height: 3
                            color: parent.clipped ? "#ff3535" : "#ff941c"
                        }
                    }
                }
            }

            Text {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 5
                anchors.horizontalCenter: parent.horizontalCenter
                text: "L   R"
                color: "#8f9aa5"
                font.pixelSize: 8
                font.bold: true
            }
        }

        Column {
            anchors.fill: parent
            anchors.leftMargin: win.outerMargin
            anchors.topMargin: win.outerMargin
            anchors.bottomMargin: win.outerMargin
            anchors.rightMargin: win.outerMargin + win.masterMeterWidth + win.sectionGap
            spacing: win.sectionGap
'''
    ),
])

checks = {
    "NativeDeckPanel.qml": ["property int zoomIndex: 9", "id: channelVu", "font.pixelSize: 17"],
    "NativeFxPanel.qml": ["anchors.centerIn: parent", 'text: "FX " + root.unit'],
    "NativeBeatGridOverlay.qml": ["property var barMarkers", "beatMarkerList: grid.barMarkers"],
    "NativeDisplayWindow.qml": ["id: masterVu", "app.traktor.mixer.master.level.left", 'text: "0 dB"'],
}
for name, needles in checks.items():
    text = (root / name).read_text()
    for needle in needles:
        if needle not in text:
            raise SystemExit(f"Verification marker missing in {name}: {needle}")

print("  v0.18.24 QML tweaks applied and verified.")
PY

if ! grep -q "StandaloneDisplay4507" "$D2"; then
  fail "D2 hook verification failed: StandaloneDisplay4507 marker missing."
fi
if ! grep -q 'NativeDisplayWindow.qml' "$D2"; then
  fail "D2 hook verification failed: NativeDisplayWindow.qml reference missing."
fi
echo "  D2 standalone-display hook verified."

echo "[6/7] Creating Finder launcher..."
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
  <string>0.18.24</string>
  <key>CFBundleShortVersionString</key>
  <string>0.18.24</string>
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

codesign --force --sign - "$LAUNCHER" >/dev/null 2>&1 || true
printf "%s\n" "$LAUNCHER" > "$HERE/.last_launcher"

echo "  Launcher created:"
echo "  $LAUNCHER"

echo "[7/7] Installation complete."
echo
echo "SUCCESS"
echo "======="
echo "Modified Traktor:"
echo "  $TARGET"
echo
echo "Finder launcher:"
echo "  $LAUNCHER"
echo
echo "v0.18.24 changes:"
echo "  - default waveform zoom is 10/11"
echo "  - FX 1 / FX 2 labels centered"
echo "  - LOOP label typography matches BEATJUMP"
echo "  - every fourth Traktor beat-grid line highlighted"
echo "  - artist name enlarged slightly"
echo "  - native channel VU meters added to Deck A / B"
echo "  - native stereo master VU added at right with 0 dB limiter marker"
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

