#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LATEST_VERSION="v0.18.24"
BASE_PAYLOAD_VERSION="v0.18.23"

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

hash_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    sha256sum "$1" | awk '{print $1}'
  fi
}

expected_hash() {
  case "$1" in
    D2.qml) echo "bbd8d2c351178c50f81651cfaf78c2e4c7fbba7a210b0e0640e7b05f33ae93cf" ;;
    NativeDisplayWindow.qml) echo "3a7f2512866e2df3a0cd723d0c7cde2b97f16e896a6325fee6edb435303a0d95" ;;
    NativeDeckPanel.qml) echo "2c84c8cc73b87fbd10e36366966b9de4a30e29fde894023d0cb8f53c4425d3eb" ;;
    NativeOverviewStripe.qml) echo "28b24ff560f83c1f27fd98f905982bb3f6551cf632716471ada5ee5d191117a5" ;;
    NativeBeatGridOverlay.qml) echo "4e8104621097dd8322820f748c33536d70c6d6bc5d7ba25920ea654d94704eb4" ;;
    NativeStripeCueMarkers.qml) echo "5f54d153c06d9c3862d214189bc8c2cb028de8a6ca10ea713c914ed7673613c5" ;;
    NativeFxPanel.qml) echo "fc09f9cce27d6725af3da6cbde1652bcd680f5c40550258f358e6eeea5484afc" ;;
    NativeCueMarkerOverlay.qml) echo "eb68d2cab82bfd36cacdabe6943071236cb1e1222ba2430349bc0143c20b7235" ;;
  esac
}

for file in "${FILES[@]}"; do
  mac="$ROOT/macOS/payload/$file"
  win="$ROOT/Windows/payload/$file"
  [[ -f "$mac" && -f "$win" ]] || {
    echo "Missing payload file: $file" >&2
    exit 1
  }
  cmp -s "$mac" "$win" || {
    echo "Platform payload mismatch: $file" >&2
    exit 1
  }
  actual="$(hash_file "$mac")"
  [[ "$actual" == "$(expected_hash "$file")" ]] || {
    echo "SHA-256 mismatch: $file" >&2
    exit 1
  }
done

bash -n \
  "$ROOT/macOS/Install_Traktor_Performance_Display_v0_18_24.command" \
  "$ROOT/macOS/Install_Traktor_Performance_Display_v0_18_23.command" \
  "$ROOT/macOS/Uninstall_Traktor_Performance_Display_v0_18_23.command"

grep -q 'VERSION="v0.18.24"' "$ROOT/macOS/Install_Traktor_Performance_Display_v0_18_24.command"
grep -q 'id: channelVu' "$ROOT/macOS/Install_Traktor_Performance_Display_v0_18_24.command"
grep -q 'id: masterVu' "$ROOT/macOS/Install_Traktor_Performance_Display_v0_18_24.command"
grep -q 'property var barMarkers' "$ROOT/macOS/Install_Traktor_Performance_Display_v0_18_24.command"
grep -q 'e4d4f0c1e749b48f2a531e55a39fc284f377fd4d' "$ROOT/macOS/Install_Traktor_Performance_Display_v0_18_24.command"

if find "$ROOT" -type f \( -name '.DS_Store' -o -name '.last_*' \) -print -quit | grep -q .; then
  echo "Local state or metadata is present in the release tree." >&2
  exit 1
fi

grep -q 'StandaloneDisplay4507' "$ROOT/macOS/payload/D2.qml"
grep -q 'NativeDisplayWindow.qml' "$ROOT/macOS/payload/D2.qml"

echo "Traktor Performance Display $LATEST_VERSION release checks passed (base payload $BASE_PAYLOAD_VERSION)."
