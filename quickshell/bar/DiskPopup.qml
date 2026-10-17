import QtQuick

Column {
    spacing: 6
    width: 300

    Title {
        width: parent.width
        text: "Disk utilization"
    }

    Repeater {
        model: Stats.disks

        Meter {
            required property var modelData
            width: parent.width
            label: modelData.name
            labelWidth: 80
            value: modelData.util / 100
            valueText: modelData.util.toFixed(1) + "%"
        }
    }
}
