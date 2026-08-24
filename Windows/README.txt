TRAKTOR PERFORMANCE DISPLAY v0.18.23 — WINDOWS DISTRIBUTABLE
============================================================

TARGET
------
Traktor Pro 4.5.0.7 on Windows.

WINDOWS STATUS
--------------
The QML payload is the same 4.5.0.7-compatible build that works on macOS.
The Windows installer structure is prepared for the standard Traktor Pro 4 Resources64\qml path,
but this package has NOT yet been tested on an actual Windows Traktor 4.5.0.7 machine.

INSTALLATION — MAKE/CHOOSE THE TARGET YOURSELF
----------------------------------------------
The installer does NOT copy Traktor automatically.

If you want to protect your normal installation, make your own separate copy of the Traktor
program folder first. Then run the installer and enter that exact copied folder.

The installer displays the target and accepts Y or YES before patching it; pressing Enter alone cancels safely.

MAKE D2 WORK / REQUIRED TRAKTOR SETUP
-------------------------------------
The standalone Performance Display is launched by Traktor's D2 mapping.

1. Open Traktor.
2. Go to Preferences > Controller Manager.
3. Open the Device drop-down.
4. Look for a Traktor Kontrol D2 mapping.
5. If a D2 mapping is already present, leave it in place.
6. If D2 is missing, click Add... and choose the Native Instruments / Traktor Kontrol D2
   default mapping. The exact wording can vary slightly by build.
7. Quit Traktor completely.
8. Launch the modified Traktor copy/installation.
9. The standalone Performance Display should open when the D2 mapping loads.

You do NOT need to own a physical D2 for the display code itself.

If you already use a real D2, keep the existing mapping.

Do not add multiple unnecessary D2 mappings.

WINDOWS QML LOCATION
--------------------
The installer expects:

  <Traktor folder>\Resources64\qml\CSI\D2

and installs:

  D2.qml
  NativeDisplayWindow.qml
  NativeDeckPanel.qml
  NativeOverviewStripe.qml
  NativeBeatGridOverlay.qml
  NativeStripeCueMarkers.qml
  NativeFxPanel.qml
  NativeCueMarkerOverlay.qml

VERSION SAFETY
--------------
The installer checks D2.qml before changing anything.

Expected clean D2 SHA-256:
  8bdfde9883f379796ddcc848eae78c39986bce15c9bdbb46620f3ab24388b838

Patched D2 SHA-256:
  bbd8d2c351178c50f81651cfaf78c2e4c7fbba7a210b0e0640e7b05f33ae93cf

If D2.qml does not match the supported clean Traktor Pro 4.5.0.7 file, installation stops.

INSTALL
-------
Right-click:

  Install_Traktor_Performance_Display_v0_18_23.bat

and choose:

  Run as administrator

Then choose:
  enter the exact Traktor program folder you want to patch;
  verify the displayed folder;
  type Y or YES to continue.

If you want a separate copy, make that copy yourself before running the installer.

ROLLBACK
--------
Right-click:

  Uninstall_Traktor_Performance_Display_v0_18_23.bat

and choose Run as administrator.

If you used the copied-folder option, you can also remove the copied Performance Display folder
and continue using the original Traktor installation.

DO NOT USE THE OLD 4.2 INSTALLER
--------------------------------
Do not use v0.17.81's Traktor 4.2.0 installer on Traktor 4.5.x.
The old CSI\D2\Api injection path is absent in 4.5.0.7.


BUILT-IN DIAGNOSTICS
--------------------
The Windows installer verifies every installed QML file by SHA-256 and confirms that D2.qml
contains both the StandaloneDisplay4507 hook marker and the NativeDisplayWindow.qml reference.
No manual grep/hash checks are required.
