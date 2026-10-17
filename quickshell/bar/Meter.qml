import QtQuick

Item {
    id: meter

    property string label
    property real value: 0
    property string valueText: Math.round(value * 100) + "%"
    property color barColor: value >= 0.9 ? Theme.red : value >= 0.7 ? Theme.yellow : Theme.accent
    property int labelWidth: 110

    implicitWidth: 320
    implicitHeight: 22

    Text {
        id: name
        width: meter.labelWidth
        anchors.verticalCenter: parent.verticalCenter
        text: meter.label
        elide: Text.ElideRight
        color: Theme.subtext
        font.family: Theme.font
        font.pixelSize: 13
    }

    Rectangle {
        id: track
        anchors.left: name.right
        anchors.right: amount.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        height: 8
        radius: 4
        color: Theme.track

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, meter.value))
            height: parent.height
            radius: 4
            color: meter.barColor

            Behavior on width {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    Text {
        id: amount
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 64
        horizontalAlignment: Text.AlignRight
        text: meter.valueText
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 13
        font.features: { "tnum": 1 }
    }
}
