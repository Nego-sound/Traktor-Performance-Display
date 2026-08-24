import CSI 1.0
import QtQuick 2.12

Item {
    id: root
    property string pathPrefix: ""
    property real trackLength: 0
    property var trackKey: 0
    property bool markersReady: false

    onTrackKeyChanged: {
        markersReady = false
        markerRefreshTimer.restart()
    }

    Timer {
        id: markerRefreshTimer
        interval: 180
        repeat: false
        onTriggered: root.markersReady = true
    }

    function cleanName(v) {
        var s = String(v === undefined || v === null ? "" : v).trim()
        var lower = s.toLowerCase()
        if (!s || lower === "n.n." || lower === "nan" || lower === "n/a" || lower === "none")
            return ""
        return s
    }

    function xForSeconds(seconds) {
        var len = Number(trackLength)
        var s = Number(seconds)
        if (!isFinite(len) || len <= 0 || !isFinite(s)) return 0
        return Math.max(0, Math.min(width - 2, (s / len) * width))
    }

    function markerColor(i, isLoop) {
        return isLoop ? "#38e681" : "#4ab5ff"
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

            Rectangle {
                visible: cue.exists
                x: root.xForSeconds(cue.startSeconds)
                y: 0
                width: 3
                height: root.height
                color: root.markerColor(cue.cueIndex, cue.isLoop)
                z: 5
            }

            Rectangle {
                visible: cue.exists
                x: Math.max(0, root.xForSeconds(cue.startSeconds) - 8)
                y: 2
                width: 18
                height: 15
                radius: 3
                color: root.markerColor(cue.cueIndex, cue.isLoop)
                z: 6
                Text {
                    anchors.centerIn: parent
                    text: cue.cueIndex
                    color: "#05070a"
                    font.pixelSize: 9
                    font.bold: true
                }
            }

            Rectangle {
                visible: cue.exists && cue.isLoop && cue.lengthSeconds > 0
                x: root.xForSeconds(cue.startSeconds + cue.lengthSeconds)
                y: 0
                width: 3
                height: root.height
                color: "#38e681"
                z: 5
            }
        }
    }
}
