TRAKTOR PERFORMANCE DISPLAY v0.18.23 — macOS DISTRIBUTABLE
==========================================================

TARGET
------
Traktor Pro 4.5.0.7 on macOS.

RECOMMENDED INSTALL
-------------------
1. Quit Traktor.
2. Duplicate your clean Traktor Pro 4.5.0.7 app yourself in Finder.
3. Rename that duplicate if desired.
4. Run:
     Install_Traktor_Performance_Display_v0_18_23.command
5. Drag the exact duplicate .app into the installer.
6. Type Y or YES when the installer shows the correct target.

THE INSTALLER DOES THE DIAGNOSTICS
----------------------------------
You do not need to run grep, hash, or Terminal diagnostic commands.

The installer automatically:
- verifies the selected D2.qml is the supported Traktor 4.5.0.7 file (or an existing v0.18.23-patched file);
- backs up current D2/performance-display files;
- installs all eight QML files;
- verifies the SHA-256 of every installed file;
- verifies the StandaloneDisplay4507 hook exists in D2.qml;
- verifies D2.qml references NativeDisplayWindow.qml;
- creates a local Finder-launchable wrapper app beside the modified Traktor;
- optionally launches the modified Traktor immediately.

WHY THE WRAPPER APP EXISTS
--------------------------
Changing QML inside Traktor changes Native Instruments' signed app bundle. Finder/Gatekeeper may
then reject direct launching of the modified Traktor .app.

The installer therefore creates a small local launcher app next to the modified copy. That wrapper
starts Traktor's executable directly. It is generated locally during installation, so recipients
do not need to run a Terminal launch command each time.

The installer does NOT recursively re-sign the Native Instruments Traktor bundle.

MAKE D2 WORK
------------
The standalone Performance Display is launched by Traktor's D2 mapping.

After installation:
1. Open the modified Traktor using the generated Performance Display Launcher app.
2. Go to Preferences > Controller Manager.
3. Confirm a Traktor Kontrol D2 mapping exists.
4. If D2 is missing, click Add... and add the Native Instruments / Traktor Kontrol D2 default mapping.
5. Quit and relaunch the modified Traktor using the generated launcher.

You do not need to own a physical D2 for the display itself.

FILES INSTALLED
---------------
Inside the selected Traktor app:
  Contents/Resources/qml/CSI/D2/

the installer installs:
  D2.qml
  NativeDisplayWindow.qml
  NativeDeckPanel.qml
  NativeOverviewStripe.qml
  NativeBeatGridOverlay.qml
  NativeStripeCueMarkers.qml
  NativeFxPanel.qml
  NativeCueMarkerOverlay.qml

ROLLBACK
--------
Run:
  Uninstall_Traktor_Performance_Display_v0_18_23.command

The rollback restores the latest backup and removes the generated launcher app if it was recorded.
