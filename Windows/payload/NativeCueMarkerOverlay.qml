import CSI 1.0
import QtQuick 2.12
import Traktor.Gui 1.0 as Traktor

Item {
    id: root
    property int deckId: 0
    property string pathPrefix: ""
    property var waveformPosition
    property real sampleRate: 44100
    property real waveformSampleWidth: 1966080
    property real viewWidth: width
    property var trackKey: 0
    property real trackLength: 0
    property int trackGeneration: 0
    property bool markersReady: false
    clip: false

    onTrackKeyChanged: {
        trackGeneration++
        markersReady = false
        markerRefreshTimer.restart()
    }

    Timer {
        id: markerRefreshTimer
        interval: 180
        repeat: false
        onTriggered: root.markersReady = true
    }

    function markerColor(isLoop) {
        return isLoop ? "#38e681" : "#4ab5ff"
    }

    function cleanName(v) {
        var s = String(v === undefined || v === null ? "" : v).trim()
        var lower = s.toLowerCase()
        if (!s || lower === "n.n." || lower === "nan" || lower === "n/a" || lower === "none")
            return ""
        return s
    }

    Repeater {
        model: 8

        delegate: Item {
            id: cue
            property int cueIndex: index + 1

            AppProperty { id: startProp;  path: root.pathPrefix + "track.cue.hotcues." + cue.cueIndex + ".start_pos" }
            AppProperty { id: typeProp;   path: root.pathPrefix + "track.cue.hotcues." + cue.cueIndex + ".type" }
            AppProperty { id: lengthProp; path: root.pathPrefix + "track.cue.hotcues." + cue.cueIndex + ".length" }
            AppProperty { id: nameProp;   path: root.pathPrefix + "track.cue.hotcues." + cue.cueIndex + ".name" }

            readonly property real startSeconds: Number(startProp.value)
            readonly property real lengthSeconds: Number(lengthProp.value)
            readonly property int cueType: Number(typeProp.value)
            readonly property bool isLoop: cueType === 5 || lengthSeconds > 0
            readonly property string cleanCueName: root.cleanName(nameProp.value)
            readonly property bool validPosition:
                isFinite(startSeconds) &&
                startSeconds >= 0 &&
                (!isFinite(root.trackLength) || root.trackLength <= 0 || startSeconds <= root.trackLength + 0.25)
            readonly property bool validType:
                isFinite(cueType) && cueType >= 0
            readonly property bool exists:
                root.markersReady &&
                Number(root.trackKey) > 0 &&
                validPosition &&
                validType &&
                (
                    startSeconds > 0.00001 ||
                    lengthSeconds > 0 ||
                    cleanCueName.length > 0
                )

            // START / CUE line — full height across the moving waveform.
            Traktor.WaveformTranslator {
                followTarget: root.waveformPosition
                pos: cue.startSeconds * root.sampleRate
                anchors.fill: root
                visible: cue.exists
                z: 20

                Rectangle {
                    x: -2
                    y: 0
                    width: 5
                    height: root.height
                    color: root.markerColor(cue.isLoop)
                    opacity: 0.98
                }

                // Small tab only; the full-height line is the primary marker.
                Rectangle {
                    x: 4
                    y: 4
                    width: Math.min(112, Math.max(24, markerText.implicitWidth + 10))
                    height: 20
                    radius: 3
                    color: root.markerColor(cue.isLoop)
                    opacity: 0.96

                    Text {
                        id: markerText
                        anchors.centerIn: parent
                        text: {
                            var n = cue.cleanCueName
                            if (n.length > 0) return cue.cueIndex + " " + n
                            return cue.isLoop ? ("L" + cue.cueIndex) : String(cue.cueIndex)
                        }
                        color: "#05070a"
                        font.pixelSize: 10
                        font.bold: true
                        elide: Text.ElideRight
                    }
                }
            }

            // Saved-loop END line — full height across the moving waveform.
            Traktor.WaveformTranslator {
                followTarget: root.waveformPosition
                pos: (cue.startSeconds + cue.lengthSeconds) * root.sampleRate
                anchors.fill: root
                visible: cue.exists && cue.isLoop && cue.lengthSeconds > 0
                z: 20

                Rectangle {
                    x: -2
                    y: 0
                    width: 5
                    height: root.height
                    color: "#38e681"
                    opacity: 0.98
                }

                Rectangle {
                    x: -22
                    y: 4
                    width: 44
                    height: 20
                    radius: 3
                    color: "#38e681"
                    opacity: 0.96

                    Text {
                        anchors.centerIn: parent
                        text: "OUT"
                        color: "#05070a"
                        font.pixelSize: 9
                        font.bold: true
                    }
                }
            }
        }
    }
}
