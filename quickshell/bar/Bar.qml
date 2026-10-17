import QtQuick
import Quickshell
import Quickshell.I3
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: bar

    required property ShellScreen modelData
    readonly property var sink: Pipewire.defaultAudioSink?.audio ?? null
    readonly property var wsIcons: ({ "1": "", "2": "", "3": "", "4": "", "5": "" })

    function run(...cmd) {
        Quickshell.execDetached(cmd);
    }

    screen: modelData
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    implicitHeight: Theme.barHeight
    color: Theme.barBg
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "quickshell-bar"

    IdleInhibitor {
        window: bar
        enabled: Stats.idleInhibited
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Row {
        anchors.left: parent.left
        height: parent.height

        Repeater {
            model: I3.workspaces.values.filter(w => w.monitor?.name === bar.modelData?.name).sort((a, b) => a.number - b.number)

            Rectangle {
                id: ws

                required property var modelData
                readonly property string icon: modelData.urgent ? "" : modelData.focused ? "" : (bar.wsIcons[modelData.name] ?? "")

                width: wsText.implicitWidth + 33
                height: bar.height
                color: modelData.focused ? Theme.wsFocused : Theme.wsBg

                Text {
                    id: wsText
                    anchors.centerIn: parent
                    text: Theme.pango(ws.icon)
                    textFormat: Text.RichText
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: ws.modelData.activate()
                }
            }
        }

        Module {
            text: Sway.mode === "default" ? "" : Sway.mode
            italic: true
        }
    }

    Row {
        anchors.centerIn: parent
        height: parent.height

        Module {
            property bool alt: false
            text: alt ? Qt.formatDateTime(clock.date, "dddd, MMMM dd, yyyy   HH:mm") : Qt.formatDateTime(clock.date, "yyyy-MM-dd  HH:mm")
            dismissOnClick: false
            popupDelay: 150
            onClicked: alt = !alt
            popup: Component {
                CalendarPopup {
                    now: clock.date
                }
            }
        }

        Module {
            text: Stats.stopwatch
            onClicked: bar.run(Theme.bin + "stopwatch", "toggle")
            onRightClicked: bar.run(Theme.bin + "stopwatch-panel")
        }
    }

    Row {
        anchors.right: parent.right
        height: parent.height

        Module {
            text: Sway.flag
            color: Sway.country === "US" ? Theme.red : Sway.country === "CA" ? "#5ed6fe" : Theme.fg
            tooltip: Sway.layout
        }

        Module {
            text: Stats.updatesChecked ? "♻ " + Stats.updates.length : ""
            onClicked: Stats.refreshUpdates()
            popup: Component {
                UpdatesPopup {}
            }
        }

        Module {
            text: " " + Stats.cpu + "%"
            popup: Component {
                CpuPopup {}
            }
        }

        Module {
            text: Stats.mem.text ?? ""
            popup: Component {
                MemoryPopup {}
            }
        }

        Module {
            text: Stats.sensors.length ? " " + Stats.maxTemp + "°C" : ""
            onClicked: bar.run(Theme.bin + "temperature-chart")
            popup: Component {
                TempPopup {}
            }
        }

        Module {
            text: Stats.disks.length ? "🖴 " + Stats.diskMax + "%" : ""
            popup: Component {
                DiskPopup {}
            }
        }

        Module {
            text: "🌪 " + Stats.gpuBusy + "%"
            onClicked: bar.run("amdgpu_top", "--gui")
            popup: Component {
                GpuPopup {}
            }
        }

        Module {
            text: Stats.kb.text ? "⌨ " + Stats.kb.text : ""
            tooltip: Stats.kb.tooltip ?? ""
            onClicked: bar.run(Theme.bin + "keyboard-battery-chart")
        }

        Module {
            text: !bar.sink ? "" : bar.sink.muted ? "" : " " + Math.round(bar.sink.volume * 100) + "%"
            onClicked: bar.run("helvum")
            onRightClicked: bar.run(Theme.bin + "audio-output-panel")
            onScrolled: delta => {
                if (bar.sink)
                    bar.sink.volume = Math.max(0, Math.min(1, bar.sink.volume + (delta > 0 ? 0.01 : -0.01)));
            }
            popup: Component {
                VolumePopup {}
            }
        }

        Module {
            text: Stats.online ? " " + Theme.bytes(Stats.rxRate + Stats.txRate, "B/s", 1) : "⚠ Disconnected"
            color: Stats.online ? Theme.fg : "crimson"
            widthSample: "\uf0c1 888kB/s"
            popup: Component {
                NetworkPopup {}
            }
        }

        Module {
            text: Stats.weather.text ? Stats.weather.text + "°" : ""
            tooltip: Stats.weather.tooltip ?? ""
        }

        Module {
            text: Stats.idleInhibited ? "" : ""
            tooltip: Stats.idleInhibited ? "activated" : "deactivated"
            dismissOnClick: false
            onClicked: Stats.idleInhibited = !Stats.idleInhibited
        }

        Module {
            text: Stats.sunTint.text ?? ""
            tooltip: Stats.sunTint.tooltip ?? ""
            color: Stats.sunTint.class === "error" ? Theme.red : Theme.fg
            dismissOnClick: false
            onClicked: bar.run(Theme.bin + "sun-tint", "toggle")
        }

        Module {
            text: Stats.oats.text ?? ""
            tooltip: Stats.oats.tooltip ?? ""
            color: Stats.oats.class === "recording" ? Theme.red : Stats.oats.class === "stopping" ? Theme.yellow : Theme.fg
            dismissOnClick: false
            onClicked: bar.run("oats", "toggle")
        }

        Row {
            leftPadding: 6
            rightPadding: 6
            spacing: 10
            height: parent.height

            Repeater {
                model: SystemTray.items.values.filter(i => i.status !== Status.Passive)

                Item {
                    id: tray

                    required property SystemTrayItem modelData

                    width: 16
                    height: bar.height

                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 16
                        source: tray.modelData.icon
                    }

                    HoverHandler {
                        id: trayHover
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: mouse => {
                            trayTip.dismiss();
                            if (mouse.button === Qt.MiddleButton)
                                tray.modelData.secondaryActivate();
                            else if (mouse.button === Qt.RightButton || tray.modelData.onlyMenu)
                                trayMenu.open();
                            else
                                tray.modelData.activate();
                        }
                        onWheel: wheel => tray.modelData.scroll(wheel.angleDelta.y, false)
                    }

                    QsMenuAnchor {
                        id: trayMenu
                        menu: tray.modelData.menu
                        anchor.item: tray
                        anchor.edges: Edges.Top
                        anchor.gravity: Edges.Top
                    }

                    HoverPopup {
                        id: trayTip
                        target: tray
                        targetHovered: trayHover.hovered
                        content: Component {
                            TooltipText {
                                text: Theme.html(tray.modelData.tooltipTitle || tray.modelData.title || tray.modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }
}
