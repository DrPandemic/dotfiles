import QtQuick

Column {
    id: root

    readonly property var procs: Stats.mem.top || []

    spacing: 6
    width: 340

    Title {
        width: parent.width
        text: "Memory"
        detail: Theme.kib(Stats.mem.used_kb || 0) + " / " + Theme.kib(Stats.mem.total_kb || 0)
    }

    Meter {
        width: parent.width
        label: "Used"
        labelWidth: 50
        value: (Stats.mem.used_kb || 0) / (Stats.mem.total_kb || 1)
    }

    Item {
        width: 1
        height: 4
    }

    Repeater {
        model: root.procs

        Meter {
            required property var modelData
            width: parent.width
            label: modelData[0]
            value: modelData[1] / (Stats.mem.total_kb || 1)
            valueText: Theme.kib(modelData[1])
            barColor: Theme.accent
            labelWidth: 130
        }
    }
}
