import CSI 1.0
import QtQuick 2.12
import QtQuick.Window 2.12

Window {
    id: win

    // Normal resizable window again so the macOS frame/corners can be grabbed.
    width: 1600
    height: 1000
    minimumWidth: 800
    minimumHeight: 520

    visible: true
    title: "Traktor Native Performance Display — A / B"
    color: "#05070a"

    // v0.18 display preferences. These are runtime-safe presentation options.
    property bool prefShowFxStates: true
    property bool prefShowStripes: true
    property bool prefShowStemVolumes: true
    property bool prefShowCueMarkers: true
    property bool prefShowBeatGrid: true
    property bool prefShowMasterHighlight: true
    property bool prefShowPhaseMeter: true
    property bool prefShowZoom: true
    property bool prefShowBrowserButton: true
    property int prefStripeSize: 2       // 0 thin, 1 normal, 2 thick
    property int prefFxPanelSize: 2      // 0 off, 1 normal, 2 tall
    property int prefFxStateSize: 1      // 0 normal, 1 large
    property bool settingsOpen: false

    function resetPreferences() {
        prefShowFxStates = true
        prefShowStripes = true
        prefShowStemVolumes = true
        prefShowCueMarkers = true
        prefShowBeatGrid = true
        prefShowMasterHighlight = true
        prefShowPhaseMeter = true
        prefShowZoom = true
        prefShowBrowserButton = true
        prefStripeSize = 2
        prefFxPanelSize = 2
        prefFxStateSize = 1
    }

    // Native Traktor browser hand-off.
    AppProperty { id: nativeBrowserFullScreen; path: "app.traktor.browser.full_screen" }
    AppProperty { id: deckALoadSignal; path: "app.traktor.decks.1.is_loaded_signal" }
    AppProperty { id: deckBLoadSignal; path: "app.traktor.decks.2.is_loaded_signal" }

    property bool nativeBrowserSession: false
    property int performanceSavedX: 0
    property int performanceSavedY: 0
    property int performanceSavedWidth: 1600
    property int performanceSavedHeight: 1000

    function openNativeBrowser() {
        if (nativeBrowserSession)
            return

        // Keep this SAME QML Window alive rather than creating/hiding another
        // Window. Save its geometry, collapse it to a tiny return control, and
        // leave the rest of Traktor exposed for browsing.
        performanceSavedX = win.x
        performanceSavedY = win.y
        performanceSavedWidth = win.width
        performanceSavedHeight = win.height
        nativeBrowserSession = true

        win.minimumWidth = 172
        win.minimumHeight = 54
        win.width = 172
        win.height = 54
        win.x = performanceSavedX + Math.max(0, performanceSavedWidth - 172)
        win.y = performanceSavedY
        win.show()
        win.raise()
        console.log("[StandaloneDisplay] Collapsed to browser return button")
    }

    function returnFromNativeBrowser() {
        if (!nativeBrowserSession)
            return

        nativeBrowserSession = false
        nativeBrowserFullScreen.value = false
        win.minimumWidth = 800
        win.minimumHeight = 520
        win.x = performanceSavedX
        win.y = performanceSavedY
        win.width = Math.max(800, performanceSavedWidth)
        win.height = Math.max(520, performanceSavedHeight)
        win.show()
        win.raise()
        win.requestActivate()
        console.log("[StandaloneDisplay] Returned to performance display")
    }

    onVisibleChanged: {
        // Do not hide the window while in our browser hand-off mode. The same
        // window becomes the compact PERFORMANCE return control.
    }

    // Responsive layout metrics.
    readonly property real scaleFactor: Math.max(0.55, Math.min(1.0, Math.min(width / 1920.0, height / 1280.0)))
    readonly property int outerMargin: Math.max(6, Math.round(12 * scaleFactor))
    readonly property int sectionGap: Math.max(4, Math.round(8 * scaleFactor))

    // Reserve a compact FX row and overview row, then split the rest between decks.
    readonly property int fxHeight: prefFxPanelSize === 0 ? 0 : (prefFxPanelSize === 1 ? Math.max(42, Math.round(64 * scaleFactor)) : Math.max(74, Math.round(112 * scaleFactor)))
    readonly property int overviewHeight: prefShowStripes ?
        (prefStripeSize === 0 ? Math.max(72, Math.round(100 * scaleFactor)) :
         prefStripeSize === 1 ? Math.max(100, Math.round(146 * scaleFactor)) :
                                Math.max(150, Math.round(230 * scaleFactor))) : 0
    readonly property int stripeHeight: prefShowStripes ? Math.floor(overviewHeight / 2) : 0
    readonly property int activeGaps: 2 + (prefFxPanelSize > 0 ? 1 : 0) + (prefShowStripes ? 2 : 0)
    readonly property int availableDeckSpace:
        Math.max(260, height - (outerMargin * 2) - fxHeight - overviewHeight - (sectionGap * activeGaps))
    readonly property int deckHeight: Math.floor(availableDeckSpace / 2)

    Rectangle {
        id: browserReturnLayer
        anchors.fill: parent
        visible: win.nativeBrowserSession
        color: "#0d1218"
        radius: 5
        border.color: "#627384"
        border.width: 1
        z: 1000

        Text {
            anchors.centerIn: parent
            text: "PERFORMANCE"
            color: "white"
            font.pixelSize: 12
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: win.returnFromNativeBrowser()
        }
    }

    Rectangle {
        id: performanceLayer
        anchors.fill: parent
        visible: !win.nativeBrowserSession
        color: "#05070a"

        Column {
            anchors.fill: parent
            anchors.margins: win.outerMargin
            spacing: win.sectionGap

            Row {
                width: parent.width
                height: win.fxHeight
                visible: win.prefFxPanelSize > 0
                spacing: win.sectionGap

                NativeFxPanel {
                    unit: 1
                    width: (parent.width - win.sectionGap) / 2
                    height: parent.height
                }

                NativeFxPanel {
                    unit: 2
                    width: (parent.width - win.sectionGap) / 2
                    height: parent.height
                }
            }

            NativeDeckPanel {
                deckId: 0
                width: parent.width
                height: win.deckHeight
                showFxStates: win.prefShowFxStates
                showStemVolumes: win.prefShowStemVolumes
                showCueMarkers: win.prefShowCueMarkers
                showBeatGrid: win.prefShowBeatGrid
                showMasterHighlight: win.prefShowMasterHighlight
                showPhaseMeter: win.prefShowPhaseMeter
                showZoomControl: win.prefShowZoom
                largeFxStates: win.prefFxStateSize === 1
            }

            Rectangle {
                width: parent.width
                height: win.stripeHeight
                visible: win.prefShowStripes
                radius: Math.max(5, Math.round(8 * win.scaleFactor))
                color: "#080b0f"
                border.color: "#252c34"
                border.width: 1
                NativeOverviewStripe {
                    deckId: 0
                    anchors.fill: parent
                    anchors.margins: Math.max(4, Math.round(7 * win.scaleFactor))
                }
            }

            NativeDeckPanel {
                deckId: 1
                width: parent.width
                height: win.deckHeight
                showFxStates: win.prefShowFxStates
                showStemVolumes: win.prefShowStemVolumes
                showCueMarkers: win.prefShowCueMarkers
                showBeatGrid: win.prefShowBeatGrid
                showMasterHighlight: win.prefShowMasterHighlight
                showPhaseMeter: win.prefShowPhaseMeter
                showZoomControl: win.prefShowZoom
                largeFxStates: win.prefFxStateSize === 1
            }

            Rectangle {
                width: parent.width
                height: win.stripeHeight
                visible: win.prefShowStripes
                radius: Math.max(5, Math.round(8 * win.scaleFactor))
                color: "#080b0f"
                border.color: "#252c34"
                border.width: 1
                NativeOverviewStripe {
                    deckId: 1
                    anchors.fill: parent
                    anchors.margins: Math.max(4, Math.round(7 * win.scaleFactor))
                }
            }
        }
    }


    Rectangle {
        width: 92; height: 34
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 10
        radius: 4
        visible: win.prefShowBrowserButton && !win.settingsOpen
        color: "#c0151b22"; border.color: "#46515c"; z: 200
        Text { anchors.centerIn: parent; text: "BROWSER"; color: "white"; font.pixelSize: 12; font.bold: true }
        MouseArea { anchors.fill: parent; onClicked: win.openNativeBrowser() }
    }



    Rectangle {
        width: 42; height: 34
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 10
        radius: 5
        color: "#d0151b22"
        border.color: settingsOpen ? "#20a9ff" : "#46515c"
        z: 301
        Text { anchors.centerIn: parent; text: "⚙"; color: "white"; font.pixelSize: 19 }
        MouseArea { anchors.fill: parent; onClicked: win.settingsOpen = !win.settingsOpen }
    }

    Rectangle {
        id: preferencesPanel
        width: Math.min(430, win.width - 28)
        height: Math.min(610, win.height - 28)
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 58
        anchors.bottomMargin: 10
        radius: 10
        color: "#f20a0e13"
        border.color: "#52606d"
        border.width: 1
        visible: win.settingsOpen
        z: 300

        function toggleRow(labelText, checked, action) { return null }

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8

            Row {
                width: parent.width; height: 34
                Text { width: parent.width - 46; text: "DISPLAY PREFERENCES"; color: "white"; font.pixelSize: 17; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                Rectangle { width: 36; height: 30; radius: 5; color: "#182028"; Text { anchors.centerIn: parent; text: "×"; color: "white"; font.pixelSize: 20 }
                    MouseArea { anchors.fill: parent; onClicked: win.settingsOpen = false } }
            }

            Rectangle { width: parent.width; height: 1; color: "#34404b" }

            Repeater {
                model: [
                    ["FX STATE BOXES", "prefShowFxStates"],
                    ["OVERVIEW STRIPES", "prefShowStripes"],
                    ["STEM VOLUMES", "prefShowStemVolumes"],
                    ["CUE / LOOP MARKERS", "prefShowCueMarkers"],
                    ["BEATGRID", "prefShowBeatGrid"],
                    ["MASTER BLUE HIGHLIGHT", "prefShowMasterHighlight"],
                    ["PHASE METER", "prefShowPhaseMeter"],
                    ["ZOOM CONTROL", "prefShowZoom"],
                    ["BROWSER BUTTON", "prefShowBrowserButton"]
                ]
                delegate: Rectangle {
                    width: parent.width; height: 34; radius: 5
                    color: "#111820"
                    property bool state: win[modelData[1]]
                    Text { anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter; text: modelData[0]; color: "white"; font.pixelSize: 12; font.bold: true }
                    Rectangle {
                        width: 50; height: 24; radius: 12; anchors.right: parent.right; anchors.rightMargin: 7; anchors.verticalCenter: parent.verticalCenter
                        color: parent.state ? "#126da8" : "#2a323a"
                        Rectangle { width: 18; height: 18; radius: 9; y: 3; x: parent.parent.state ? 29 : 3; color: "white" }
                    }
                    MouseArea { anchors.fill: parent; onClicked: win[modelData[1]] = !win[modelData[1]] }
                }
            }

            Row {
                width: parent.width; height: 38; spacing: 8
                Text { width: 132; text: "STRIPE SIZE"; color: "#c9d1d9"; font.pixelSize: 11; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                Repeater {
                    model: ["THIN","NORMAL","THICK"]
                    delegate: Rectangle {
                        width: 72; height: 30; radius: 5
                        color: win.prefStripeSize === index ? "#126da8" : "#182028"
                        border.color: win.prefStripeSize === index ? "#20a9ff" : "#39444e"
                        Text { anchors.centerIn: parent; text: modelData; color: "white"; font.pixelSize: 9; font.bold: true }
                        MouseArea { anchors.fill: parent; onClicked: win.prefStripeSize = index }
                    }
                }
            }

            Row {
                width: parent.width; height: 38; spacing: 8
                Text { width: 132; text: "FX PANEL SIZE"; color: "#c9d1d9"; font.pixelSize: 11; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                Repeater {
                    model: ["OFF","NORMAL","TALL"]
                    delegate: Rectangle {
                        width: 72; height: 30; radius: 5
                        color: win.prefFxPanelSize === index ? "#126da8" : "#182028"
                        border.color: win.prefFxPanelSize === index ? "#20a9ff" : "#39444e"
                        Text { anchors.centerIn: parent; text: modelData; color: "white"; font.pixelSize: 9; font.bold: true }
                        MouseArea { anchors.fill: parent; onClicked: win.prefFxPanelSize = index }
                    }
                }
            }

            Row {
                width: parent.width; height: 38; spacing: 8
                Text { width: 132; text: "FX BOX SIZE"; color: "#c9d1d9"; font.pixelSize: 11; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                Repeater {
                    model: ["NORMAL","LARGE"]
                    delegate: Rectangle {
                        width: 88; height: 30; radius: 5
                        color: win.prefFxStateSize === index ? "#126da8" : "#182028"
                        border.color: win.prefFxStateSize === index ? "#20a9ff" : "#39444e"
                        Text { anchors.centerIn: parent; text: modelData; color: "white"; font.pixelSize: 9; font.bold: true }
                        MouseArea { anchors.fill: parent; onClicked: win.prefFxStateSize = index }
                    }
                }
            }

            Rectangle {
                width: 120; height: 30; radius: 5; color: "#182028"; border.color: "#46515c"
                Text { anchors.centerIn: parent; text: "RESET DEFAULTS"; color: "white"; font.pixelSize: 9; font.bold: true }
                MouseArea { anchors.fill: parent; onClicked: win.resetPreferences() }
            }

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: "v0.17.55: settings are live for this Traktor session. Persistent save is deliberately not enabled until we verify a safe storage method."
                color: "#7f8b96"; font.pixelSize: 9
            }
        }
    }

    // Follow native browser state even when it is triggered by a MIDI mapping
    // or by Traktor itself.
    Connections {
        target: nativeBrowserFullScreen
        function onValueChanged() {
            if (nativeBrowserFullScreen.value) {
                if (!nativeBrowserSession)
                    win.openNativeBrowser()
            } else if (nativeBrowserSession) {
                win.returnFromNativeBrowser()
            }
        }
    }

    // A successful deck load while browsing is our cue to close Browser
    // and immediately restore the performance display.
    Connections {
        target: deckALoadSignal
        function onValueChanged() {
            if (nativeBrowserSession)
                win.returnFromNativeBrowser()
        }
    }

    Connections {
        target: deckBLoadSignal
        function onValueChanged() {
            if (nativeBrowserSession)
                win.returnFromNativeBrowser()
        }
    }
}
