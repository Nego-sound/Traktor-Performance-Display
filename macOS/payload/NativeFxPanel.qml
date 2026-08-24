import CSI 1.0
import QtQuick 2.12

Rectangle {
    id: root
    property int unit: 1
    readonly property string p: "app.traktor.fx." + unit + "."

    color: "#090d12"
    radius: 5
    border.color: "#202932"
    border.width: 1

    AppProperty { id: dryWet; path: p + "dry_wet" }
    AppProperty { id: knob1; path: p + "knobs.1" }
    AppProperty { id: knob2; path: p + "knobs.2" }
    AppProperty { id: knob3; path: p + "knobs.3" }

    AppProperty { id: select1; path: p + "select.1" }
    AppProperty { id: select2; path: p + "select.2" }
    AppProperty { id: select3; path: p + "select.3" }

    AppProperty { id: on1; path: p + "buttons.1" }
    AppProperty { id: on2; path: p + "buttons.2" }
    AppProperty { id: on3; path: p + "buttons.3" }

    function normalized(v) {
        var n = Number(v)
        if (!isFinite(n)) return 0
        if (Math.abs(n) > 1.0001) n = n / 100.0
        return Math.max(0, Math.min(1, n))
    }

    function pct(v) {
        return Math.round(normalized(v) * 100) + "%"
    }

    function effectName(prop, fallback) {
        var d = String(prop.description === undefined || prop.description === null ? "" : prop.description).trim()
        return d.length > 0 ? d : fallback
    }

    Row {
        anchors.fill: parent
        anchors.margins: 5
        spacing: 6

        Item {
            width: 62
            height: parent.height

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "FX " + root.unit
                color: "#ff941c"
                font.pixelSize: 17
                font.bold: true
            }
        }

        // D/W now matches the same one-line graphical style as the other FX cells.
        Rectangle {
            width: 128
            height: parent.height
            radius: 4
            color: "#0d1319"
            border.color: "#26313b"
            border.width: 1
            clip: true

            Rectangle {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: parent.width * root.normalized(dryWet.value)
                height: Math.max(18, Math.min(28, parent.height * 0.32))
                color: "#ff941c"
                opacity: 0.95
            }

            Row {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 8

                Text {
                    width: parent.width - 52
                    anchors.verticalCenter: parent.verticalCenter
                    text: "D/W"
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                }

                Text {
                    width: 44
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignRight
                    text: root.pct(dryWet.value)
                    color: "#f0f3f6"
                    font.pixelSize: 15
                    font.bold: true
                }
            }
        }

        Repeater {
            model: 3

            delegate: Rectangle {
                width: (parent.width - 208) / 3
                height: parent.height
                radius: 4
                color: "#0d1319"
                border.color: armed ? "#ff941c" : "#26313b"
                border.width: armed ? 2 : 1
                clip: true

                property bool armed: index === 0 ? !!on1.value
                                   : index === 1 ? !!on2.value
                                                 : !!on3.value

                property real amount: index === 0 ? root.normalized(knob1.value)
                                    : index === 1 ? root.normalized(knob2.value)
                                                  : root.normalized(knob3.value)

                Rectangle {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    width: parent.width * amount
                    height: Math.max(18, Math.min(28, parent.height * 0.32))
                    color: "#ff941c"
                    opacity: armed ? 1.0 : 0.86
                }

                Row {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 8

                    Text {
                        width: parent.width - 52
                        anchors.verticalCenter: parent.verticalCenter
                        text: index === 0 ? root.effectName(select1, "Effect 1")
                             : index === 1 ? root.effectName(select2, "Effect 2")
                                           : root.effectName(select3, "Effect 3")
                        color: "white"
                        font.pixelSize: 14
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        width: 44
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignRight
                        text: Math.round(amount * 100) + "%"
                        color: "#f0f3f6"
                        font.pixelSize: 15
                        font.bold: true
                    }
                }
            }
        }
    }
}
