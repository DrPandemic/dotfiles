import QtQuick

// Wrapped in a plain Item so the popup has a fixed implicit size. The popup used
// to resize when the sample arrived (and when meters appeared), and the software
// renderer stretched the surface mid-resize; a constant size avoids that, and
// the host list scrolls inside it if it ever gets taller.
Item {
    id: root

    readonly property int hostCount: Stats.remoteHosts.length
    readonly property int onlineCount: Stats.remoteHosts.filter(h => h.online).length
    readonly property int listHeight: 760

    implicitWidth: 360
    implicitHeight: column.implicitHeight
    width: 360
    height: column.implicitHeight

    // The popup is loaded lazily on hover, so this is what samples the hosts:
    // on load, then every 3s while it stays on screen. Nothing runs once it's
    // destroyed.
    Timer {
        running: true
        repeat: true
        interval: 3000
        triggeredOnStart: true
        onTriggered: Stats.refreshRemote()
    }

    Column {
        id: column

        width: root.width
        spacing: 10

        Title {
            width: parent.width
            text: "Remote hosts"
            detail: root.hostCount ? root.onlineCount + "/" + root.hostCount + " online" : "waiting…"
        }

        Flickable {
            width: parent.width
            height: root.listHeight
            contentHeight: list.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: list

                width: parent.width
                spacing: 10

                Text {
                    visible: !root.hostCount
                    text: "Collecting…"
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 13
                }

                // Fixed delegate count keeps the popup from rebuilding every refresh.
                Repeater {
                    model: root.hostCount

                    Column {
                        id: host

                        required property int index
                        readonly property var info: Stats.remoteHosts[index] ?? ({})
                        readonly property bool online: host.info.online === true
                        readonly property string state: host.info.status ?? (host.online ? "online" : "offline")
                        readonly property var history: Stats.remoteHistory[host.info.host] ?? []

                        width: list.width
                        spacing: 5

                        Item {
                            width: parent.width
                            implicitHeight: hostName.implicitHeight

                            Text {
                                id: hostName
                                text: host.info.host ?? ""
                                color: Theme.text
                                font.family: Theme.font
                                font.pixelSize: 14
                                font.bold: true
                            }

                            Text {
                                anchors.right: parent.right
                                anchors.baseline: hostName.baseline
                                text: host.online ? "load " + host.info.load : host.state === "locked" ? " ssh key locked" : host.state === "denied" ? " ssh auth denied" : "offline"
                                color: host.online ? Theme.dim : (host.state === "locked" || host.state === "denied") ? Theme.yellow : Theme.red
                                font.family: Theme.font
                                font.pixelSize: 12
                            }
                        }

                        Text {
                            visible: !host.online && (host.info.error ?? "") !== ""
                            width: parent.width
                            text: host.info.error ?? ""
                            color: Theme.red
                            elide: Text.ElideRight
                            font.family: Theme.font
                            font.pixelSize: 12
                        }

                        Text {
                            visible: host.online
                            text: "CPU over time"
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: 12
                        }

                        Sparkline {
                            visible: host.online
                            width: parent.width
                            values: host.history
                        }

                        Meter {
                            visible: host.online
                            width: parent.width
                            label: "CPU"
                            labelWidth: 40
                            value: (host.info.cpu ?? 0) / 100
                            valueText: (host.info.cpu ?? 0).toFixed(1) + "%"
                        }

                        Meter {
                            visible: host.online
                            width: parent.width
                            label: "RAM"
                            labelWidth: 40
                            value: (host.info.memused ?? 0) / (host.info.memtotal || 1)
                            valueText: Theme.kib(host.info.memused ?? 0) + " / " + Theme.kib(host.info.memtotal ?? 0)
                            barColor: Theme.green
                        }

                        Text {
                            visible: host.online && (host.info.disks ?? []).length > 0
                            text: "Disk"
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: 12
                        }

                        Repeater {
                            model: host.online ? (host.info.disks ?? []) : []

                            Meter {
                                required property var modelData
                                width: host.width
                                label: modelData.mount
                                labelWidth: 130
                                value: modelData.used / (modelData.total || 1)
                                valueWidth: 150
                                valueText: Theme.bytes(modelData.total - modelData.used, "B", 1) + " free / " + Theme.bytes(modelData.total, "B", 1)
                            }
                        }

                        Text {
                            visible: host.online
                            text: "Top processes"
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: 12
                        }

                        Repeater {
                            model: host.online ? (host.info.procs ?? []) : []

                            Meter {
                                required property var modelData
                                width: host.width
                                label: modelData.name
                                labelWidth: 130
                                value: modelData.cpu / 100
                                valueText: modelData.cpu.toFixed(1) + "%"
                                barColor: Theme.accentLight
                            }
                        }
                    }
                }
            }
        }
    }
}
