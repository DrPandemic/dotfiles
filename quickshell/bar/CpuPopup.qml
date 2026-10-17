import QtQuick

Column {
    spacing: 8
    width: 340

    Component.onCompleted: Stats.cpuWatchers++
    Component.onDestruction: Stats.cpuWatchers--

    Title {
        width: parent.width
        text: "CPU"
        detail: "load " + Stats.loadavg.join("  ")
    }

    Meter {
        width: parent.width
        label: "Total"
        labelWidth: 50
        value: Stats.cpu / 100
    }

    Row {
        id: cores

        readonly property real barW: (parent.width - (Stats.cores.length - 1) * spacing) / Math.max(1, Stats.cores.length)

        spacing: 3
        height: 64

        Repeater {
            model: Stats.cores

            Rectangle {
                required property int modelData
                width: cores.barW
                height: cores.height
                radius: 2
                color: Theme.track

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: parent.height * parent.modelData / 100
                    radius: 2
                    color: parent.modelData >= 90 ? Theme.red : parent.modelData >= 70 ? Theme.yellow : Theme.accentLight

                    Behavior on height {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }

    Text {
        text: Stats.cores.length + " threads, busiest " + Math.max(0, ...Stats.cores) + "%"
        color: Theme.dim
        font.family: Theme.font
        font.pixelSize: 12
    }
}
