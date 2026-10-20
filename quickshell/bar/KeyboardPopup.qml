import QtQuick

Column {
    id: root

    readonly property var kb: Stats.kb
    readonly property var sides: [
        { key: "left", label: "Left", color: "#5fb3f2" },
        { key: "right", label: "Right", color: "#f2a65f" }
    ]

    function level(key) {
        return kb[key] ?? 0;
    }

    spacing: 6
    width: 300

    Title {
        width: parent.width
        text: "Keyboard battery"
        detail: kb.text ?? ""
    }

    Repeater {
        model: root.sides

        Meter {
            required property var modelData
            readonly property real level: root.level(modelData.key) / 100

            width: parent.width
            label: modelData.label
            labelWidth: 50
            value: level
            valueText: level > 0 ? Math.round(level * 100) + "%" : "—"
            barColor: level <= 0.15 ? Theme.red : modelData.color
        }
    }

    Item {
        width: 1
        height: 2
    }

    TooltipText {
        width: parent.width
        wrapMode: Text.WordWrap
        color: Theme.subtext
        font.pixelSize: 13
        text: Theme.pango(root.kb.closed ?? "")
    }

    TooltipText {
        width: parent.width
        wrapMode: Text.WordWrap
        color: Theme.subtext
        font.pixelSize: 13
        text: Theme.pango(root.kb.drain ?? "")
    }
}
