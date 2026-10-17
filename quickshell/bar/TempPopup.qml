import QtQuick

Column {
    spacing: 4
    width: 320

    Title {
        width: parent.width
        text: "Temperatures"
        detail: "click for chart"
    }

    Repeater {
        model: Stats.sensors

        Item {
            required property var modelData
            width: parent.width
            height: 22

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: parent.modelData.label
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: 13
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: parent.modelData.temp + "°C"
                color: Theme.heat(parent.modelData.temp)
                font.family: Theme.font
                font.pixelSize: 13
                font.bold: true
            }
        }
    }
}
