import CSI 1.0
import QtQuick 2.12
import Traktor.Gui 1.0 as Traktor

Item {
    id: root
    property int deckId: 0
    property bool showFxStates: true
    property bool showStemVolumes: true
    property bool showCueMarkers: true
    property bool showBeatGrid: true
    property bool showMasterHighlight: true
    property bool showPhaseMeter: true
    property bool showZoomControl: true
    property bool largeFxStates: true
    property int zoomIndex: 10
    // NI's own S8 TrackDeck.qml defines 0x800 (2048 samples) as its native
    // minimum sample width. v0.17.59 adds that missing closest zoom step while
    // preserving every existing wider zoom value and the previous default view.
    readonly property var zoomWidths: [2048, 4096, 8192, 16384, 32768, 65536, 122880, 245760, 491520, 983040, 1966080]
    readonly property int waveformSampleWidth: zoomWidths[Math.max(0, Math.min(zoomWidths.length - 1, zoomIndex))]
    readonly property int appDeck: deckId + 1
    readonly property string deckLetter: String.fromCharCode(65 + deckId)
    readonly property string pathPrefix: "app.traktor.decks." + appDeck + "."

    property string loadedKey: ""
    property string previousResultingKey: ""
    property int semitoneShift: 0
    // Local display mode only: false = manual channel gain, true = track Auto Gain.
    property bool showAutoGainValue: false


    function zoomOut() { zoomIndex = Math.min(zoomWidths.length - 1, zoomIndex + 1) }
    function zoomIn()  { zoomIndex = Math.max(0, zoomIndex - 1) }

    AppProperty {
        id: isLoaded
        path: pathPrefix + "is_loaded"
        onValueChanged: {
            if (value) {
                root.loadedKey = String(resultingKey.value || "")
                root.previousResultingKey = root.loadedKey
                root.semitoneShift = 0
            }
        }
    }
    AppProperty { id: primaryKey;       path: pathPrefix + "track.content.entry_key" }
    AppProperty { id: titleProp;        path: pathPrefix + "content.title" }
    AppProperty { id: artistProp;       path: pathPrefix + "content.artist" }
    AppProperty { id: trackLengthProp;  path: pathPrefix + "track.content.track_length" }
    AppProperty { id: elapsedTimeProp;  path: pathPrefix + "track.player.elapsed_time" }
    AppProperty { id: fxAssign1;        path: "app.traktor.mixer.channels." + root.appDeck + ".fx.assign.1" }
    AppProperty { id: fxAssign2;        path: "app.traktor.mixer.channels." + root.appDeck + ".fx.assign.2" }
    AppProperty { id: channelFilter;     path: "app.traktor.mixer.channels." + root.appDeck + ".fx.adjust" }
    // Gain data. channelGain is the user/manual mixer gain; totalGain is the combined
    // gain Traktor applies for the loaded track (channel gain + Auto Gain).
    AppProperty { id: channelGain;      path: "app.traktor.mixer.channels." + root.appDeck + ".gain" }
    AppProperty { id: totalGain;        path: pathPrefix + "content.total_gain" }
    AppProperty { id: baseBpm;          path: pathPrefix + "tempo.base_bpm" }
    AppProperty { id: tempoRatio;       path: pathPrefix + "tempo.tempo_for_display" }
    AppProperty {
        id: resultingKey
        path: pathPrefix + "track.key.resulting.precise"
        onValueChanged: root.updateKeyShift(String(value || ""))
    }
    AppProperty { id: keyAdjust;      path: pathPrefix + "track.key.adjust" }
    AppProperty {
        id: keyLockEnabled
        path: pathPrefix + "track.key.lock_enabled"
        onValueChanged: {
            if (!value) {
                root.semitoneShift = 0
                root.previousResultingKey = String(resultingKey.value || "")
            } else {
                root.previousResultingKey = String(resultingKey.value || "")
                root.semitoneShift = 0
            }
        }
    }
    AppProperty { id: loopActive;       path: pathPrefix + "loop.active" }
    AppProperty { id: loopSize;         path: pathPrefix + "loop.size" }
    AppProperty { id: loopSelectedSize; path: pathPrefix + "loop.set.auto_with_size" }
    AppProperty {
        id: moveSize
        path: pathPrefix + "move.size"
        // Hard ceiling for Beatjump: index 11 = 32. If Traktor or a controller
        // attempts to advance into the following LOOP state, immediately restore
        // the real application property to 32 rather than merely changing display text.
        onValueChanged: {
            var n = Number(value)
            if (isFinite(n) && n > 11)
                moveSize.value = 11
        }
    }
    AppProperty { id: phaseProp;        path: pathPrefix + "tempo.phase" }
    AppProperty { id: masterDeckIdProp; path: "app.traktor.masterclock.source_id" }
    readonly property bool isMasterDeck: Number(masterDeckIdProp.value) === root.deckId
    AppProperty { id: waveformColorMode; path: "app.traktor.settings.waveform.color" }
    AppProperty { id: sampleRateProp;    path: pathPrefix + "track.content.sample_rate" }
    AppProperty { id: activeCueType;     path: pathPrefix + "track.cue.active.type" }
    AppProperty { id: activeCueStart;    path: pathPrefix + "track.cue.active.start_pos" }
    AppProperty { id: activeCueLength;   path: pathPrefix + "track.cue.active.length" }

    // Stem Deck state + live stem metadata/volumes.
    AppProperty { id: deckTypeProp; path: pathPrefix + "type" }
    readonly property bool isStemDeck: Number(deckTypeProp.value) === DeckType.Stem

    // Dynamic left-side reflow. Stem volume controls occupy their own column;
    // when a Stem Deck is loaded the mixer panel and zoom control slide right
    // to make room, then return automatically for a normal Track Deck.
    readonly property int stemPanelWidth: 70
    readonly property int stemPanelGap: 8
    readonly property int mixerPanelBaseX: 0
    readonly property int mixerPanelStemX: stemPanelWidth + stemPanelGap + 8
    readonly property int mixerPanelX: isStemDeck && showStemVolumes ? mixerPanelStemX : mixerPanelBaseX
    readonly property int zoomBaseX: 186
    readonly property int zoomStemX: mixerPanelStemX + 186
    readonly property int zoomPanelX: isStemDeck && showStemVolumes ? zoomStemX : zoomBaseX

    AppProperty { id: stem1Name;   path: pathPrefix + "stems.1.name" }
    AppProperty { id: stem2Name;   path: pathPrefix + "stems.2.name" }
    AppProperty { id: stem3Name;   path: pathPrefix + "stems.3.name" }
    AppProperty { id: stem4Name;   path: pathPrefix + "stems.4.name" }
    AppProperty { id: stem1Volume; path: pathPrefix + "stems.1.volume" }
    AppProperty { id: stem2Volume; path: pathPrefix + "stems.2.volume" }
    AppProperty { id: stem3Volume; path: pathPrefix + "stems.3.volume" }
    AppProperty { id: stem4Volume; path: pathPrefix + "stems.4.volume" }

    function stemName(i) {
        var names = [stem1Name.value, stem2Name.value, stem3Name.value, stem4Name.value]
        var fallback = ["DRUMS", "BASS", "OTHER", "VOCALS"]
        var n = String(names[i] || "")
        return n.length ? n.toUpperCase() : fallback[i]
    }

    function stemVolume(i) {
        var vals = [stem1Volume.value, stem2Volume.value, stem3Volume.value, stem4Volume.value]
        var v = Number(vals[i])
        if (!isFinite(v)) return 0
        return Math.max(0, Math.min(1, v))
    }

    function stemColor(i) {
        // Traktor Stem order:
        // 1 Drums = Orange, 2 Bass = Pink, 3 Other = Green, 4 Vocals = Blue
        return ["#ff9a32", "#ff4fa3", "#38d46a", "#3d8dff"][i]
    }

    function samplesToWaveformX(samples, viewWidth) {
        var sw = Number(root.waveformSampleWidth)
        if (!isFinite(sw) || sw <= 0) return 0
        return (samples / sw) * viewWidth
    }

    function loopText(v) {
        var m = {0:"1/32",1:"1/16",2:"1/8",3:"1/4",4:"1/2",5:"1",6:"2",7:"4",8:"8",9:"16",10:"32"}
        return m[v] !== undefined ? m[v] : String(v)
    }

    function selectedLoopValue() {
        var s = Number(loopSelectedSize.value)
        if (!loopActive.value && isFinite(s) && Math.floor(s) === s && s >= 0 && s <= 10)
            return s
        return Number(loopSize.value)
    }

    function moveText(v) {
        var m = {0:"1/32",1:"1/16",2:"1/8",3:"1/4",4:"1/2",5:"1",6:"2",7:"4",8:"4",9:"8",10:"16",11:"32"}
        return m[v] !== undefined ? m[v] : String(v)
    }

    function liveBpm() {
        var b = Number(baseBpm.value)
        var t = Number(tempoRatio.value)
        if (!isFinite(b)) return "—"
        if (!isFinite(t) || t === 0) t = 1
        return (b * t).toFixed(2)
    }

    function pitchText() {
        var t = Number(tempoRatio.value)
        if (!isFinite(t) || t === 0) t = 1
        var p = (t - 1) * 100
        if (Math.abs(p) < 0.005) p = 0
        return (p > 0 ? "+" : "") + p.toFixed(2) + "%"
    }

    function timeText(seconds) {
        var n = Number(seconds)
        if (!isFinite(n) || n < 0) n = 0
        var total = Math.floor(n)
        var m = Math.floor(total / 60)
        var sec = total % 60
        return m + ":" + (sec < 10 ? "0" : "") + sec
    }

    function remainingTime() {
        var len = Number(trackLengthProp.value)
        var elapsed = Number(elapsedTimeProp.value)
        if (!isFinite(len)) len = 0
        if (!isFinite(elapsed)) elapsed = 0
        return Math.max(0, len - elapsed)
    }

    function gainDbFromLinear(v) {
        var n = Number(v)
        if (!isFinite(n) || n <= 0) return 0
        return 20.0 * Math.log(n) / Math.LN10
    }

    function signedDb(v) {
        var n = Number(v)
        if (!isFinite(n) || Math.abs(n) < 0.05) n = 0
        return (n > 0 ? "+" : "") + n.toFixed(1) + " dB"
    }

    // Traktor exposes the channel gain control as a normalized 0..1 knob value.
    // The old build parsed AppProperty.description, which is why it only ever showed
    // tiny positive values. Convert the full knob travel instead: centre = 0 dB,
    // upper half = 0..+12 dB, lower half follows a logarithmic attenuation curve
    // down to -infinity at the hard-left stop.
    function channelGainDb() {
        var v = Number(channelGain.value)
        if (!isFinite(v)) return NaN
        v = Math.max(0.0, Math.min(1.0, v))
        if (v <= 0.00001) return -Infinity
        if (v < 0.5) return 20.0 * Math.log(v / 0.5) / Math.LN10
        return (v - 0.5) * 24.0
    }

    function manualGainText() {
        var db = root.channelGainDb()
        if (db === -Infinity) return "-∞ dB"
        if (isFinite(db)) return root.signedDb(db)
        return "—"
    }

    function autoGainText() {
        var totalDb = root.gainDbFromLinear(totalGain.value)
        var manualDb = root.channelGainDb()
        // NI documents total deck gain as Channel Gain + Auto Gain. When the manual
        // dB value is available, subtract it to expose the track's Auto Gain value.
        if (isFinite(manualDb)) return root.signedDb(totalDb - manualDb)
        return root.signedDb(totalDb)
    }

    function keyPitchClass(k) {
        var m = String(k).match(/^(\d+)([md])$/i)
        if (!m) return -1
        var n = Number(m[1]), mode = m[2].toLowerCase()
        var minor = [-1,8,3,10,5,0,7,2,9,4,11,6,1]
        var major = [-1,11,6,1,8,3,10,5,0,7,2,9,4]
        return mode === "m" ? minor[n] : major[n]
    }

    function updateKeyShift(k) {
        if (!k) return
        if (!previousResultingKey) {
            previousResultingKey = k
            loadedKey = k
            semitoneShift = 0
            return
        }
        if (k === previousResultingKey) return
        var a = keyPitchClass(previousResultingKey)
        var b = keyPitchClass(k)
        if (a >= 0 && b >= 0) {
            var d = (b - a + 12) % 12
            if (d > 6) d -= 12
            semitoneShift += d
        }
        previousResultingKey = k
    }

    function displayedKeyShift() {
        if (!keyLockEnabled.value) return 0
        return root.semitoneShift
    }

    function saturatedKeyColor(k) {
        var c = Qt.color(root.keyColor(k))
        var hi = Math.max(c.r, Math.max(c.g,c.b))
        var lo = Math.min(c.r, Math.min(c.g,c.b))
        if (hi <= 0 || hi === lo) return c
        var mid=(hi+lo)/2.0, f=1.30
        return Qt.rgba(Math.max(0,Math.min(1,mid+(c.r-mid)*f)),
                       Math.max(0,Math.min(1,mid+(c.g-mid)*f)),
                       Math.max(0,Math.min(1,mid+(c.b-mid)*f)),1)
    }

    function keyColor(k) {
        // Open Key wheel palette supplied by user:
        // 1 = magenta/purple, then rotating through blue, cyan, green,
        // yellow, orange and red back to magenta.
        var m = String(k).match(/^(\d+)([md])$/i)
        if (!m) return "#d8dee6"
        var n = Number(m[1])
        var mode = m[2].toLowerCase()

        var major = {
            1:"#b45aa6",
            2:"#7f6caf",
            3:"#5588c7",
            4:"#3fb9df",
            5:"#59bdc9",
            6:"#49b58f",
            7:"#72b72f",
            8:"#98c900",
            9:"#ffd21a",
            10:"#fb8c29",
            11:"#f26732",
            12:"#ef4c4f"
        }

        var minor = {
            1:"#c58bbd",
            2:"#9b89bd",
            3:"#82a8cf",
            4:"#8ccddd",
            5:"#7fc6cb",
            6:"#7ac8ab",
            7:"#8bc957",
            8:"#b2d044",
            9:"#ffd84d",
            10:"#f6a24c",
            11:"#f58a63",
            12:"#f3787a"
        }

        return mode === "m" ? minor[n] : major[n]
    }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: "#080b0f"
        border.color: "#252c34"
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            // Compact header: deck ID + track info + key + BPM
            Row {
                width: parent.width
                height: 72
                spacing: 10

                Rectangle {
                    width: 64
                    height: 58
                    radius: 6
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.showMasterHighlight && root.isMasterDeck ? "#0b5d92" : "#0c1116"
                    border.color: root.showMasterHighlight && root.isMasterDeck ? "#20a9ff" : "#33404c"
                    border.width: root.showMasterHighlight && root.isMasterDeck ? 2 : 1

                    Text {
                        anchors.centerIn: parent
                        text: root.deckLetter
                        color: root.showMasterHighlight && root.isMasterDeck ? "#eaf7ff" : "white"
                        font.pixelSize: 34
                        font.bold: true
                    }
                }

                Column {
                    width: Math.max(170, parent.width - 570)
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        width: parent.width
                        text: isLoaded.value ? (titleProp.value || "Untitled") : "Load a track on Deck " + root.deckLetter
                        color: "white"
                        font.pixelSize: 23
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: artistProp.value || ""
                        color: "#b6bec7"
                        font.pixelSize: 15
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    width: 78
                    height: 64
                    radius: 2
                    anchors.verticalCenter: parent.verticalCenter
                    color: Qt.darker(root.saturatedKeyColor(resultingKey.value), 2.8)
                    border.color: Qt.darker(root.saturatedKeyColor(resultingKey.value), 1.65)
                    border.width: 1
                    clip: true

                    Column {
                        anchors.fill: parent
                        anchors.topMargin: 4
                        anchors.bottomMargin: 3
                        spacing: -2

                        Text {
                            width: parent.width
                            height: 30
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: resultingKey.value || "—"
                            color: root.saturatedKeyColor(resultingKey.value)
                            font.pixelSize: 24
                            font.bold: true
                        }

                        Text {
                            width: parent.width
                            height: 29
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: (root.displayedKeyShift() > 0 ? "+" : "") + root.displayedKeyShift()
                            color: root.saturatedKeyColor(resultingKey.value)
                            font.pixelSize: 24
                            font.bold: true
                        }
                    }
                }

                Item {
                    width: 182
                    height: 62
                    anchors.verticalCenter: parent.verticalCenter

                    Column {
                        anchors.centerIn: parent
                        spacing: -3

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.liveBpm()
                            color: "white"
                            font.pixelSize: 38
                            font.bold: true
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.pitchText()
                            color: "#9ba6b1"
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }
                }

                Rectangle {
                    width: 92
                    height: 54
                    radius: 5
                    anchors.verticalCenter: parent.verticalCenter
                    color: loopActive.value ? "#0b7f45" : "#10251b"
                    border.color: loopActive.value ? "#39f08c" : "#245a3c"
                    border.width: loopActive.value ? 2 : 1

                    Column {
                        anchors.centerIn: parent
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "LOOP"
                            color: loopActive.value ? "#c8ffdc" : "#7fad90"
                            font.pixelSize: 8
                            font.bold: true
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.loopText(root.selectedLoopValue())
                            color: loopActive.value ? "#f2fff7" : "#d9f3e3"
                            font.pixelSize: 24
                            font.bold: true
                        }
                    }
                }

                Rectangle {
                    width: 104
                    height: 54
                    radius: 5
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#1a1228"
                    border.color: "#4c3270"
                    border.width: 1

                    Column {
                        anchors.centerIn: parent
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "BEATJUMP"
                            color: "#a98bd0"
                            font.pixelSize: 11
                            font.bold: true
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.moveText(Number(moveSize.value))
                            color: "#eadcff"
                            font.pixelSize: 24
                            font.bold: true
                        }
                    }
                }
            }

            Item {
                id: waveformArea
                width: parent.width
                height: parent.height - 78
                clip: true

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: "#070a0e"
                }

                Traktor.WaveformPosition {
                    id: wfPosition
                    deckId: root.deckId
                    followsPlayhead: true
                    sampleWidth: root.waveformSampleWidth
                    viewWidth: waveformArea.width
                    Behavior on sampleWidth {
                        PropertyAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Traktor.Waveform {
                    id: nativeWaveform
                    anchors.fill: parent
                    anchors.margins: 1
                    visible: !root.isStemDeck
                    deckId: root.deckId
                    waveformPosition: wfPosition
                    audioStreamKey: primaryKey.value == 0 ? ["MixerDeckKey", root.appDeck] : ["PrimaryKey", primaryKey.value, 0]

                    colorMatrix.background: "#070a0e"
                    // v0.17.67 refined blend. Keep the calibrated channel mapping
                    // from v0.17.66, but move the low/transient contribution from dark
                    // red toward hot pink/magenta, lighten the blue body toward cyan,
                    // and soften the secondary layers so transitions blend more like
                    // Traktor's native Spectrum display.
                    // v0.17.74: restore the six-channel depth seen in the diagnostic
                    // build, but keep the palette Traktor-like rather than diagnostic RGB.
                    // Each 1/2 pair is deliberately distinct and the stronger diagnostic
                    // alpha structure is restored so the layers remain visibly separate.
                    // lows: hot red -> pink/magenta
                    // mids: green-cyan -> electric cyan/blue
                    // highs: deep electric blue -> violet/magenta
                    colorMatrix.low1:  Qt.rgba(1.00, 0.02, 0.22, 0.82)
                    colorMatrix.low2:  Qt.rgba(1.00, 0.08, 0.48, 1.00)
                    colorMatrix.mid1:  Qt.rgba(0.00, 0.72, 0.64, 0.82)
                    colorMatrix.mid2:  Qt.rgba(0.00, 0.62, 1.00, 1.00)
                    colorMatrix.high1: Qt.rgba(0.00, 0.18, 1.00, 0.82)
                    colorMatrix.high2: Qt.rgba(0.62, 0.04, 1.00, 1.00)
                }

                // Native Stem streams 1–4. NI's StemWaveforms.qml feeds
                // streamId 1..4 from the same PrimaryKey/waveform position.
                Item {
                    id: stemWaveformStack
                    anchors.fill: parent
                    anchors.margins: 1
                    visible: root.isStemDeck && root.showStemVolumes
                    clip: true
                    z: 1

                    Repeater {
                        model: 4
                        delegate: Item {
                            width: stemWaveformStack.width
                            height: stemWaveformStack.height / 4
                            y: index * height
                            clip: true

                            Rectangle {
                                anchors.fill: parent
                                color: "#070a0e"
                            }

                            Traktor.Waveform {
                                anchors.fill: parent
                                deckId: root.deckId
                                waveformPosition: wfPosition
                                audioStreamKey: ["PrimaryKey", primaryKey.value, index + 1]

                                colorMatrix.background: "#070a0e"
                                colorMatrix.low1:  Qt.darker(root.stemColor(index), 1.55)
                                colorMatrix.low2:  Qt.darker(root.stemColor(index), 1.20)
                                colorMatrix.mid1:  root.stemColor(index)
                                colorMatrix.mid2:  Qt.lighter(root.stemColor(index), 1.15)
                                colorMatrix.high1: Qt.lighter(root.stemColor(index), 1.28)
                                colorMatrix.high2: Qt.lighter(root.stemColor(index), 1.42)
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 1
                                color: "#303841"
                                opacity: index < 3 ? 0.85 : 0
                            }
                        }
                    }
                }

                // Exact active loop region from Traktor's own active cue data.
                Traktor.WaveformTranslator {
                    id: activeLoopTranslator
                    followTarget: wfPosition
                    pos: Number(activeCueStart.value) * Number(sampleRateProp.value)
                    anchors.fill: parent
                    visible: loopActive.value &&
                             Number(activeCueType.value) === 5 &&
                             Number(activeCueLength.value) > 0 &&
                             Number(sampleRateProp.value) > 0
                    z: 3

                    Rectangle {
                        x: 0
                        y: 1
                        height: parent.height - 2
                        width: root.samplesToWaveformX(
                                   Number(activeCueLength.value) * Number(sampleRateProp.value),
                                   waveformArea.width)
                        color: Qt.rgba(0.05, 0.85, 0.35, 0.20)
                        border.color: Qt.rgba(0.15, 1.00, 0.45, 0.72)
                        border.width: 2
                    }
                }

                // Persist loop boundaries when the loop is not active.
                Traktor.WaveformTranslator {
                    followTarget: wfPosition
                    pos: Number(activeCueStart.value) * Number(sampleRateProp.value)
                    anchors.fill: parent
                    visible: Number(activeCueType.value) === 5 &&
                             Number(activeCueLength.value) > 0 &&
                             Number(sampleRateProp.value) > 0
                    z: 5
                    Rectangle { x: 0; y: 0; width: 3; height: parent.height; color: "#38e681"; opacity: 0.95 }
                }

                Traktor.WaveformTranslator {
                    followTarget: wfPosition
                    pos: (Number(activeCueStart.value) + Number(activeCueLength.value)) * Number(sampleRateProp.value)
                    anchors.fill: parent
                    visible: Number(activeCueType.value) === 5 &&
                             Number(activeCueLength.value) > 0 &&
                             Number(sampleRateProp.value) > 0
                    z: 5
                    Rectangle { x: 0; y: 0; width: 3; height: parent.height; color: "#38e681"; opacity: 0.95 }
                }

                NativeCueMarkerOverlay {
                    anchors.fill: parent
                    deckId: root.deckId
                    pathPrefix: root.pathPrefix
                    waveformPosition: wfPosition
                    sampleRate: Number(sampleRateProp.value) > 0 ? Number(sampleRateProp.value) : 44100
                    waveformSampleWidth: root.waveformSampleWidth
                    viewWidth: waveformArea.width
                    trackKey: primaryKey.value
                    trackLength: Number(trackLengthProp.value)
                    visible: isLoaded.value && root.showCueMarkers
                    z: 6
                }

                NativeBeatGridOverlay {
                    anchors.fill: parent
                    anchors.margins: 1
                    deckId: root.deckId
                    trackId: primaryKey.value
                    waveformPosition: wfPosition
                    visible: isLoaded.value && root.showBeatGrid
                }

                // Live Stem volume strip. Read-only display of Traktor's
                // app.traktor.decks.<deck>.stems.1..4.volume properties.
                Rectangle {
                    id: stemVolumeStrip
                    width: 70
                    height: Math.min(parent.height - 16, 188)
                    x: 8
                    y: Math.round((parent.height - height) / 2)
                    radius: 7
                    color: "#d0080d12"
                    border.color: "#56616c"
                    border.width: 1
                    visible: root.isStemDeck && root.showStemVolumes
                    z: 31

                    Column {
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 3

                        Repeater {
                            model: 4
                            delegate: Rectangle {
                                width: parent.width
                                height: (stemVolumeStrip.height - 19) / 4
                                radius: 4
                                color: "#10161c"
                                border.color: "#26313a"

                                Rectangle {
                                    id: levelTrack
                                    x: 5
                                    y: 5
                                    width: 8
                                    height: parent.height - 10
                                    radius: 3
                                    color: "#050709"

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        height: parent.height * root.stemVolume(index)
                                        radius: 3
                                        color: root.stemColor(index)
                                    }
                                }

                                Column {
                                    anchors.left: levelTrack.right
                                    anchors.leftMargin: 5
                                    anchors.right: parent.right
                                    anchors.rightMargin: 3
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: -1

                                    Text {
                                        width: parent.width
                                        text: root.stemName(index)
                                        color: root.stemColor(index)
                                        font.pixelSize: 8
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        width: parent.width
                                        text: Math.round(root.stemVolume(index) * 100) + "%"
                                        color: "white"
                                        font.pixelSize: 12
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    }
                }

                // Floating zoom on left (moves beside Stem volumes on Stem Decks).
                Rectangle {
                    width: 38
                    height: 116
                    x: root.zoomPanelX
                    y: Math.round((parent.height - height) / 2)
                    Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    radius: 6
                    color: "#b00b1117"
                    border.color: "#56616c"
                    border.width: 1
                    z: 30
                    visible: root.showZoomControl

                    Column {
                        anchors.fill: parent
                        anchors.margins: 3
                        spacing: 2

                        Rectangle {
                            width: parent.width
                            height: 36
                            radius: 6
                            color: "#80182028"
                            Text { anchors.centerIn: parent; text: "+"; color: "white"; font.pixelSize: 24; font.bold: true }
                            MouseArea { anchors.fill: parent; onClicked: root.zoomIn() }
                        }

                        Item {
                            width: parent.width
                            height: 40
                            Column {
                                anchors.centerIn: parent
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: "ZOOM"; color: "#98a4af"; font.pixelSize: 7; font.bold: true }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: (root.zoomIndex + 1) + "/" + root.zoomWidths.length; color: "white"; font.pixelSize: 11; font.bold: true }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 36
                            radius: 6
                            color: "#80182028"
                            Text { anchors.centerIn: parent; text: "−"; color: "white"; font.pixelSize: 26; font.bold: true }
                            MouseArea { anchors.fill: parent; onClicked: root.zoomOut() }
                        }
                    }
                }

                // Integrated left-side mixer/gain panel. Mirrors the right-side
                // track/time panel and keeps gain, FX assignment and filter controls
                // clear of the waveform/overview stripe.
                Rectangle {
                    id: mixerPanel
                    width: 178
                    height: parent.height
                    x: root.mixerPanelX
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    radius: 5
                    color: "#d00a0e13"
                    border.color: "#222c35"
                    border.width: 1
                    z: 28

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 9

                        Item { width: 1; height: 2 }

                        Rectangle {
                            id: gainReadout
                            width: parent.width
                            height: 52
                            radius: 5
                            color: root.showAutoGainValue ? "#2a1607" : "#0b2030"
                            border.color: root.showAutoGainValue ? "#ff941c" : "#2b8fd8"
                            border.width: 1

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 58
                                    spacing: 1
                                    Text {
                                        text: "GAIN"
                                        color: "#8b98a4"
                                        font.pixelSize: 9
                                        font.bold: true
                                    }
                                    Text {
                                        text: root.showAutoGainValue ? "AUTO" : "MANUAL"
                                        color: root.showAutoGainValue ? "#ff9a22" : "#43b4ff"
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.showAutoGainValue ? root.autoGainText() : root.manualGainText()
                                    color: "white"
                                    font.pixelSize: 19
                                    font.bold: true
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.showAutoGainValue = !root.showAutoGainValue
                            }
                        }

                        Rectangle {
                            id: fxStateOverlay
                            width: parent.width
                            height: 52
                            radius: 5
                            color: "#d00a0e13"
                            border.color: "#36414b"
                            border.width: 1
                            visible: root.showFxStates

                            Row {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "FX"
                                    color: "#9ba6b1"
                                    font.pixelSize: 10
                                    font.bold: true
                                }

                                Rectangle {
                                    width: 48
                                    height: 34
                                    radius: 4
                                    color: !!fxAssign1.value ? "#2d1a0b" : "#0f151b"
                                    border.color: !!fxAssign1.value ? "#ff941c" : "#59636d"
                                    border.width: !!fxAssign1.value ? 2 : 1
                                    Text { anchors.centerIn: parent; text: "1"; color: "white"; font.pixelSize: 18; font.bold: true }
                                }

                                Rectangle {
                                    width: 48
                                    height: 34
                                    radius: 4
                                    color: !!fxAssign2.value ? "#2d1a0b" : "#0f151b"
                                    border.color: !!fxAssign2.value ? "#ff941c" : "#59636d"
                                    border.width: !!fxAssign2.value ? 2 : 1
                                    Text { anchors.centerIn: parent; text: "2"; color: "white"; font.pixelSize: 18; font.bold: true }
                                }
                            }
                        }

                        Rectangle {
                            id: filterOverlay
                            width: parent.width
                            height: 46
                            radius: 5

                            readonly property real raw: Number(channelFilter.value)
                            readonly property real v: isNaN(raw) ? 0.5 : Math.max(0.0, Math.min(1.0, raw))
                            readonly property real bipolar: (v - 0.5) * 2.0
                            readonly property bool filterActive: Math.abs(bipolar) >= 0.02

                            color: filterActive ? "#b51f1f" : "#d00a0e13"
                            border.color: filterActive ? "#ff5a5a" : "#36414b"
                            border.width: filterActive ? 2 : 1

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: Math.abs(filterOverlay.bipolar) < 0.02 ? "FILTER" : (filterOverlay.bipolar < 0 ? "LPF" : "HPF")
                                color: filterOverlay.filterActive ? "white" : "#98a4af"
                                font.pixelSize: 9
                                font.bold: true
                            }

                            Item {
                                id: filterTrack
                                width: 74
                                height: 20
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.verticalCenter: parent.verticalCenter

                                // Centre reference line.
                                Rectangle {
                                    width: 2
                                    height: parent.height
                                    x: parent.width / 2 - 1
                                    color: "#7c8792"
                                }

                                // Solid rectangular indication growing directly out from centre.
                                Rectangle {
                                    height: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: filterOverlay.bipolar < 0 ? parent.width/2 - width : parent.width/2
                                    width: Math.abs(filterOverlay.bipolar) * (parent.width/2)
                                    color: filterOverlay.bipolar < 0 ? "#36a9ff" : "#ff941c"
                                }
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: Math.round(Math.abs(filterOverlay.bipolar) * 100) + "%"
                                color: filterOverlay.filterActive ? "white" : "#dce3e9"
                                font.pixelSize: 9
                                font.bold: true
                            }
                        }
                    }
                }

                // Integrated right-side track/time panel.
                Rectangle {
                    id: timePanel
                    width: 178
                    height: parent.height
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    radius: 5
                    color: "#d00a0e13"
                    border.color: "#222c35"
                    border.width: 1
                    z: 28


                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 9
                        z: 2

                        Item { width: 1; height: 2 }

                        Column {
                            width: parent.width
                            spacing: 1

                            Text {
                                text: "LENGTH"
                                color: "#7d8893"
                                font.pixelSize: 10
                                font.bold: true
                            }

                            Text {
                                text: root.timeText(trackLengthProp.value)
                                color: "white"
                                font.pixelSize: 24
                                font.bold: false
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: 1

                            Text {
                                text: "REMAINING"
                                color: "#7d8893"
                                font.pixelSize: 10
                                font.bold: true
                            }

                            Text {
                                text: "-" + root.timeText(root.remainingTime())
                                color: "white"
                                font.pixelSize: 24
                                font.bold: false
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: 1

                            Text {
                                text: "ELAPSED"
                                color: "#7d8893"
                                font.pixelSize: 10
                                font.bold: true
                            }

                            Text {
                                text: root.timeText(elapsedTimeProp.value)
                                color: "white"
                                font.pixelSize: 24
                                font.bold: false
                            }
                        }

                        Item {
                            width: parent.width
                            height: 1
                            Rectangle {
                                anchors.fill: parent
                                color: "#36414b"
                            }
                        }

                    }
                }

                // Phase meter centered above the playhead.
                Rectangle {
                    width: 420
                    height: 22
                    radius: 6
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 5
                    color: Qt.rgba(0.02,0.03,0.04,0.76)
                    border.color: "#4a5561"
                    border.width: 1
                    visible: isLoaded.value && root.showPhaseMeter
                    z: 25

                    readonly property real normalizedPhase: {
                        var p = Number(phaseProp.value) * 2.0
                        if (!isFinite(p)) p = 0
                        return Math.max(-1.0, Math.min(1.0, p))
                    }

                    Rectangle {
                        width: 1
                        height: parent.height - 8
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        color: "white"
                        opacity: 0.55
                    }

                    Rectangle {
                        width: 8
                        height: parent.height - 6
                        radius: 3
                        y: 3
                        x: 6 + ((parent.width - 20) * ((parent.normalizedPhase + 1.0) / 2.0))
                        color: Math.abs(parent.normalizedPhase) < 0.08 ? "#28c76f" : "#ff9f1a"
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 7
                        anchors.verticalCenter: parent.verticalCenter
                        text: "PHASE"
                        color: "#aab4bd"
                        font.pixelSize: 9
                        font.bold: true
                    }
                }

                Rectangle {
                    width: 2
                    height: parent.height
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "white"
                    opacity: 0.95
                    z: 20
                }

                Text {
                    visible: !isLoaded.value
                    anchors.centerIn: parent
                    text: "DECK " + root.deckLetter + " — LOAD TRACK"
                    color: "#606b76"
                    font.pixelSize: 20
                    font.bold: true
                }
            }
        }
    }
}
