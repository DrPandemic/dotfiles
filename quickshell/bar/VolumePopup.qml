import QtQuick
import Quickshell.Services.Pipewire

Column {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream && n.audio && n.isSink)

    spacing: 8
    width: 340

    PwObjectTracker {
        objects: root.streams
    }

    Title {
        width: parent.width
        text: root.sink ? (root.sink.description || root.sink.name) : "No output"
        detail: "right-click to switch"
    }

    Row {
        spacing: 10

        Rectangle {
            width: 30
            height: 24
            radius: 6
            color: muteMouse.containsMouse ? Theme.hover : "transparent"

            Text {
                anchors.centerIn: parent
                text: root.sink?.audio?.muted ? "" : ""
                color: root.sink?.audio?.muted ? Theme.red : Theme.text
                font.family: Theme.font
                font.pixelSize: 15
            }

            MouseArea {
                id: muteMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (root.sink?.audio)
                        root.sink.audio.muted = !root.sink.audio.muted;
                }
            }
        }

        Slider {
            width: root.width - 30 - 10 - 10 - 44
            anchors.verticalCenter: parent.verticalCenter
            value: root.sink?.audio?.volume ?? 0
            barColor: root.sink?.audio?.muted ? Theme.dim : Theme.accentLight
            onMoved: v => {
                if (root.sink?.audio)
                    root.sink.audio.volume = v;
            }
        }

        Text {
            width: 44
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            text: Math.round((root.sink?.audio?.volume ?? 0) * 100) + "%"
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 13
        }
    }

    Text {
        visible: root.streams.length > 0
        text: "Applications"
        color: Theme.dim
        font.family: Theme.font
        font.pixelSize: 12
    }

    Repeater {
        model: root.streams

        Item {
            id: stream

            required property PwNode modelData
            readonly property string name: modelData.properties["application.name"] || modelData.description || modelData.name

            width: root.width
            height: 22

            Text {
                width: 120
                anchors.verticalCenter: parent.verticalCenter
                text: stream.name
                elide: Text.ElideRight
                color: stream.modelData.audio.muted ? Theme.dim : Theme.subtext
                font.family: Theme.font
                font.pixelSize: 13
            }

            Slider {
                x: 128
                width: parent.width - 128 - 52
                anchors.verticalCenter: parent.verticalCenter
                value: stream.modelData.audio.volume
                barColor: Theme.accent
                onMoved: v => stream.modelData.audio.volume = v
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(stream.modelData.audio.volume * 100) + "%"
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 12
            }
        }
    }
}
