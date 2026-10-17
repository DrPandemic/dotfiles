import QtQuick

Column {
    spacing: 6
    width: 320

    Title {
        width: parent.width
        text: "GPU"
        detail: "click for amdgpu_top"
    }

    Meter {
        width: parent.width
        label: "Busy"
        labelWidth: 60
        value: Stats.gpuBusy / 100
    }

    Meter {
        width: parent.width
        label: "VRAM"
        labelWidth: 60
        value: Stats.vramUsed / (Stats.vramTotal || 1)
        valueText: (Stats.vramUsed / 2 ** 30).toFixed(1) + " / " + Math.round(Stats.vramTotal / 2 ** 30) + "G"
    }

    Meter {
        width: parent.width
        label: "GTT"
        labelWidth: 60
        value: Stats.gttUsed / (Stats.gttTotal || 1)
        valueText: (Stats.gttUsed / 2 ** 30).toFixed(1) + " / " + Math.round(Stats.gttTotal / 2 ** 30) + "G"
    }

    Repeater {
        model: Stats.sensors.filter(s => s.key.startsWith("amdgpu"))

        Item {
            required property var modelData
            width: parent.width
            height: 20

            Text {
                text: parent.modelData.label
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: 13
            }

            Text {
                anchors.right: parent.right
                text: parent.modelData.temp + "°C"
                color: Theme.heat(parent.modelData.temp)
                font.family: Theme.font
                font.pixelSize: 13
            }
        }
    }
}
