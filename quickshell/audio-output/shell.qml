import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Wayland

ShellRoot {
    id: root

    readonly property var sinks: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    property var chosen: null

    function label(node) {
        return node.description || node.nickname || node.name;
    }

    PwObjectTracker {
        objects: root.sinks
    }

    // Quitting right after setting the default can drop the metadata write, so wait for PipeWire to report it.
    Connections {
        target: Pipewire
        function onDefaultAudioSinkChanged() {
            if (root.chosen && Pipewire.defaultAudioSink === root.chosen)
                Qt.quit();
        }
    }

    Timer {
        running: root.chosen !== null
        interval: 1000
        onTriggered: Qt.quit()
    }

    DismissLayer {}

    PanelWindow {
        visible: Pipewire.ready && root.sinks.every(n => n.ready)
        screen: {
            const want = Quickshell.env("AUDIO_SCREEN");
            const screens = Quickshell.screens;
            for (let i = 0; i < screens.length; i++)
                if (screens[i].name === want)
                    return screens[i];
            return screens[0];
        }
        anchors.bottom: true
        anchors.right: true
        margins.bottom: 6
        margins.right: 6
        implicitWidth: 360
        implicitHeight: list.implicitHeight + 52
        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "audio-output"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: "#ee2b303b"
            border.color: "#4c566a"
            border.width: 1
            focus: true
            Keys.onEscapePressed: Qt.quit()

            Text {
                x: 16
                y: 12
                text: "Sound output"
                color: "#eceff4"
                font.pixelSize: 16
                font.bold: true
            }

            Column {
                id: list
                x: 8
                y: 42
                width: parent.width - 16
                spacing: 2

                Repeater {
                    model: root.sinks

                    Rectangle {
                        id: row
                        required property var modelData
                        readonly property bool current: Pipewire.defaultAudioSink === modelData
                        width: list.width
                        height: 34
                        radius: 4
                        color: current ? "#5e81ac" : (rowMouse.containsMouse ? "#434c5e" : "transparent")

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.right: volume.left
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.label(row.modelData)
                            elide: Text.ElideRight
                            color: "#eceff4"
                            font.pixelSize: 14
                        }

                        Text {
                            id: volume
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.modelData.audio.muted ? "muted" : Math.round(row.modelData.audio.volume * 100) + "%"
                            color: row.current ? "#eceff4" : "#9aa5b8"
                            font.pixelSize: 12
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (row.current)
                                    return Qt.quit();
                                root.chosen = row.modelData;
                                Pipewire.preferredDefaultAudioSink = row.modelData;
                            }
                        }
                    }
                }
            }
        }
    }
}
