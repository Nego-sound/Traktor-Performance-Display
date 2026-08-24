import CSI 1.0
import QtQuick 2.12
import Traktor.Gui 1.0 as Traktor

// Native Traktor beat-grid overlay.
// deckId and trackId are inherited properties of Traktor.Beatgrid.
Traktor.Beatgrid {
    id: grid
    property var waveformPosition

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
    }
}
