<img width="1470" height="956" alt="Screenshot 2026-08-24 at 22 51 17" src="https://github.com/user-attachments/assets/17abdbda-b596-4bad-bf92-404752751227" />
# Traktor Performance Display

An unofficial standalone performance display for Traktor Pro 4, implemented as a QML patch with guided installers for macOS and Windows.

The latest release is **v0.18.24 for macOS**, targeting **Traktor Pro 4.5.0.7**. The v0.18.23 payload remains the current complete macOS/Windows base package; the v0.18.24 standalone macOS installer downloads that pinned payload and applies the newer UI and VU-meter updates.

> [!CAUTION]
> This modifies files inside a Traktor installation. Quit Traktor first and make a separate copy of the application/program folder before installing. The installers create a timestamped backup, but a clean duplicate is the safest rollback path.

## Status

- macOS: v0.18.24 standalone installer, based on the v0.18.23 payload for Traktor Pro 4.5.0.7.
- Windows: packaged for the standard `Resources64\\qml` layout, but not yet tested on physical Windows hardware.
- A Traktor Kontrol D2 mapping must be present in **Preferences > Controller Manager**. A physical D2 is not required for the display itself.

## Install on macOS

1. Quit Traktor.
2. Duplicate your clean Traktor Pro 4.5.0.7 app in Finder.
3. Open [`macOS`](macOS) and run `Install_Traktor_Performance_Display_v0_18_24.command`.
4. Drag the exact duplicate `.app` into the installer and confirm the displayed target.
5. Launch the modified copy with the locally generated **Performance Display Launcher** app.

The v0.18.24 installer is self-contained: if no local payload folder is beside it, it downloads the pinned v0.18.23 base payload from this repository, verifies it, and applies the v0.18.24 changes. The launcher is created because changing QML invalidates the original Native Instruments bundle signature. The installer does not recursively re-sign Traktor.

The existing v0.18.23 uninstaller can restore a backup created by the earlier full package. The v0.18.24 standalone installer creates a timestamped backup inside the selected Traktor app before changing files.

## Install on Windows

1. Quit Traktor.
2. If you want to protect the normal installation, copy the Traktor Pro 4 program folder yourself.
3. Open [`Windows`](Windows), right-click `Install_Traktor_Performance_Display_v0_18_23.bat`, and choose **Run as administrator**.
4. Enter the exact Traktor folder to patch and confirm the displayed target.

To roll back, run `Uninstall_Traktor_Performance_Display_v0_18_23.bat` as administrator.

## What is installed

Both platform packages install the same eight QML files into Traktor's `CSI/D2` directory:

- `D2.qml`
- `NativeDisplayWindow.qml`
- `NativeDeckPanel.qml`
- `NativeOverviewStripe.qml`
- `NativeBeatGridOverlay.qml`
- `NativeStripeCueMarkers.qml`
- `NativeFxPanel.qml`
- `NativeCueMarkerOverlay.qml`

The v0.18.23 base installers only accept the known Traktor Pro 4.5.0.7 `D2.qml`, back up the current files, copy the payload, verify every installed SHA-256 hash, and check the standalone-display hook. The v0.18.24 installer verifies those base hashes before applying its changes, then checks the new UI and VU-meter markers.

See [`CHANGELOG.md`](CHANGELOG.md) for the complete v0.18.24 changes and earlier release notes.

## Repository layout

```text
macOS/                 macOS installer, rollback tool, notes, and QML payload
Windows/               Windows installer, rollback tool, notes, and QML payload
CHANGELOG.md            release history
scripts/verify-release.sh
                       local release-integrity checks
```

There is no separate compile step: Traktor loads the QML payload directly. To verify a checkout before distribution, run:

```sh
./scripts/verify-release.sh
```

## Scope and provenance

This repository deliberately excludes Native Instruments application binaries, locally generated launcher apps, installer state files, backups, diagnostic probes, ZIP duplicates, and older workspace builds. It contains the v0.18.23 cross-platform base payload and installers, the v0.18.24 standalone macOS installer, documentation, and verification tooling.

Traktor and Native Instruments are trademarks of their respective owners. This project is unofficial and is not affiliated with or endorsed by Native Instruments. No project license was present in the source workspace, so no open-source license is asserted here.
