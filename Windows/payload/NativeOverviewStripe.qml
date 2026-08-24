import CSI 1.0
import QtQuick 2.12
import Traktor.Gui 1.0 as Traktor

Item {
    id: root
    property int deckId: 0
    readonly property int appDeck: deckId + 1
    readonly property string deckLetter: String.fromCharCode(65 + deckId)
    readonly property string pathPrefix: "app.traktor.decks." + appDeck + "."

    AppProperty { id: isLoaded;    path: pathPrefix + "is_loaded" }
    AppProperty { id: primaryKey;  path: pathPrefix + "track.content.entry_key" }
    AppProperty { id: elapsedTime; path: pathPrefix + "track.player.elapsed_time" }
    AppProperty { id: trackLength; path: pathPrefix + "track.content.track_length" }
    AppProperty { id: titleProp;   path: pathPrefix + "content.title" }
    AppProperty { id: waveformColorMode; path: "app.traktor.settings.waveform.color" }
    AppProperty { id: activeCueType;   path: pathPrefix + "track.cue.active.type" }
    AppProperty { id: activeCueStart;  path: pathPrefix + "track.cue.active.start_pos" }
    AppProperty { id: activeCueLength; path: pathPrefix + "track.cue.active.length" }

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: "#070a0e"
        border.color: "#252c34"
        border.width: 1
        clip: true

        Row {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 8

            Rectangle {
                width: 42; height: parent.height; radius: 6
                color: "#151c23"; border.color: "#35404c"
                Text { anchors.centerIn: parent; text: root.deckLetter; color: "white"; font.pixelSize: 20; font.bold: true }
            }

            Item {
                id: stripeArea
                width: parent.width - 50
                height: parent.height
                clip: true

                Traktor.Stripe {
                    id: stripe
                    anchors.fill: parent
                    deckId: root.deckId
                    audioStreamKey: primaryKey.value == 0 ? ["PrimaryKey", 0] : ["PrimaryKey", primaryKey.value]

                    // Match the scrolling waveform's sweep-calibrated RGB bands.
                    // Slightly reduced alpha keeps the compact stripe readable.
                    colorMatrix.background: "#070a0e"
                    colorMatrix.low1:  Qt.rgba(0.62, 0.02, 0.24, 0.74)
                    colorMatrix.low2:  Qt.rgba(1.00, 0.08, 0.42, 0.96)
                    colorMatrix.mid1:  Qt.rgba(0.28, 0.03, 0.62, 0.72)
                    colorMatrix.mid2:  Qt.rgba(0.62, 0.08, 1.00, 0.94)
                    colorMatrix.high1: Qt.rgba(0.00, 0.18, 0.88, 0.76)
                    colorMatrix.high2: Qt.rgba(0.08, 0.34, 1.00, 0.96)
                }

                NativeStripeCueMarkers {
                    anchors.fill: parent
                    pathPrefix: root.pathPrefix
                    trackLength: Number(trackLength.value)
                    trackKey: primaryKey.value
                    visible: isLoaded.value
                    z: 5
                }

                // Persistent most-recent loop boundaries.
                Rectangle {
                    visible: Number(activeCueType.value) === 5 &&
                             Number(activeCueLength.value) > 0 &&
                             Number(trackLength.value) > 0
                    x: Math.max(0, Math.min(parent.width - 2,
                       (Number(activeCueStart.value) / Number(trackLength.value)) * parent.width))
                    y: 0
                    width: 3
                    height: parent.height
                    color: "#38e681"
                    z: 5
                }

                Rectangle {
                    visible: Number(activeCueType.value) === 5 &&
                             Number(activeCueLength.value) > 0 &&
                             Number(trackLength.value) > 0
                    x: Math.max(0, Math.min(parent.width - 2,
                       ((Number(activeCueStart.value) + Number(activeCueLength.value)) /
                        Number(trackLength.value)) * parent.width))
                    y: 0
                    width: 3
                    height: parent.height
                    color: "#38e681"
                    z: 5
                }

                Item {
                    id: minuteMarkers
                    anchors.fill: parent
                    z: 4
                    visible: isLoaded.value && Number(trackLength.value) > 0

                    property int fullMinutes: Math.floor(Number(trackLength.value) / 60)

                    Repeater {
                        model: minuteMarkers.fullMinutes

                        delegate: Item {
                            property int minuteNumber: index + 1
                            x: Math.round((minuteNumber * 60 / Number(trackLength.value)) * minuteMarkers.width)
                            y: 0
                            width: 1
                            height: minuteMarkers.height

                            Rectangle {
                                x: 0
                                y: 0
                                width: 1
                                height: parent.height
                                color: "#8b96a1"
                                opacity: 0.55
                            }

                            Rectangle {
                                x: -14
                                y: 2
                                width: 28
                                height: 16
                                radius: 3
                                color: "#9a0a0f14"

                                Text {
                                    anchors.centerIn: parent
                                    text: minuteNumber + "m"
                                    color: "#d4dbe2"
                                    font.pixelSize: 9
                                    font.bold: true
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    height: parent.height
                    width: 2
                    x: {
                        var len = Number(trackLength.value)
                        var pos = Number(elapsedTime.value)
                        if (!isFinite(len) || len <= 0 || !isFinite(pos)) return 0
                        return Math.max(0, Math.min(parent.width - width, (pos / len) * parent.width))
                    }
                    color: "white"
                    opacity: isLoaded.value ? 0.95 : 0
                }

                Rectangle {
                    height: parent.height
                    width: {
                        var len = Number(trackLength.value)
                        var pos = Number(elapsedTime.value)
                        if (!isFinite(len) || len <= 0 || !isFinite(pos)) return 0
                        return Math.max(0, Math.min(parent.width, (pos / len) * parent.width))
                    }
                    color: "#000000"
                    opacity: 0.18
                    anchors.left: parent.left
                }

                Text {
                    visible: !isLoaded.value
                    anchors.centerIn: parent
                    text: "LOAD DECK " + root.deckLetter
                    color: "#5e6873"
                    font.pixelSize: 13
                    font.bold: true
                }
            }
        }
    }
}
