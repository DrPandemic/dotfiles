import QtQuick

// One app's throughput as a diverging bar: tx grows left of center, rx grows
// right. Each direction is scaled to the busiest app in that direction so both
// stay legible even though downloads usually dwarf uploads.
Item {
    id: row

    property string label
    property real rx: 0
    property real tx: 0
    property real rxPeak: 1
    property real txPeak: 1
    property string valueText
    property int labelWidth: 90
    property int valueWidth: 108

    implicitWidth: 320
    implicitHeight: 22

    Text {
        id: name
        width: row.labelWidth
        anchors.verticalCenter: parent.verticalCenter
        text: row.label
        elide: Text.ElideRight
        color: Theme.subtext
        font.family: Theme.font
        font.pixelSize: 13
    }

    Text {
        id: amount
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: row.valueWidth
        horizontalAlignment: Text.AlignRight
        text: row.valueText
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 13
        font.features: { "tnum": 1 }
    }

    Rectangle {
        id: track
        anchors.left: name.right
        anchors.right: amount.left
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        height: 8
        radius: 4
        color: Theme.track

        Rectangle { // center tick
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: parent.height
            color: Theme.border
        }

        Rectangle { // download, left of center
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: track.horizontalCenter
            height: parent.height
            width: parent.width / 2 * Math.max(0, Math.min(1, row.rx / row.rxPeak))
            color: Theme.green

            Behavior on width {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }
        }

        Rectangle { // upload, right of center
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: track.horizontalCenter
            height: parent.height
            width: parent.width / 2 * Math.max(0, Math.min(1, row.tx / row.txPeak))
            color: Theme.accentLight

            Behavior on width {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
