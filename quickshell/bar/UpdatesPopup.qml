import QtQuick

Column {
    readonly property int shown: 25

    spacing: 3
    width: 360

    Title {
        width: parent.width
        text: Stats.updates.length ? Stats.updates.length + " updates" : "Up to date"
        detail: "click to recheck"
    }

    Repeater {
        model: Stats.updates.slice(0, parent.shown)

        Item {
            required property string modelData
            readonly property var parts: modelData.split(" ")
            width: parent.width
            height: 18

            Text {
                width: parent.width - version.implicitWidth - 10
                text: parent.parts[0]
                elide: Text.ElideRight
                color: Theme.subtext
                font.family: Theme.font
                font.pixelSize: 13
            }

            Text {
                id: version
                anchors.right: parent.right
                text: parent.parts.slice(1).join(" ").replace("->", "→")
                color: Theme.dim
                font.family: Theme.mono
                font.pixelSize: 11
            }
        }
    }

    Text {
        visible: Stats.updates.length > parent.shown
        text: "+ " + (Stats.updates.length - parent.shown) + " more"
        color: Theme.dim
        font.family: Theme.font
        font.pixelSize: 12
    }
}
