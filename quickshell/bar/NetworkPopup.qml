import QtQuick

Column {
    id: root

    readonly property real peak: Math.max(1024, ...Stats.netHistory.map(s => Math.max(s.rx, s.tx)))
    readonly property real rxPeak: Math.max(1, ...Stats.netProcs.map(p => p.rx))
    readonly property real txPeak: Math.max(1, ...Stats.netProcs.map(p => p.tx))
    readonly property int maxRows: 3

    spacing: 6
    width: 360

    Title {
        width: parent.width
        text: Stats.online ? Stats.iface : "Disconnected"
        detail: Stats.ipCidr
    }

    Row {
        spacing: 24

        Text {
            text: "↓ " + Theme.bytes(Stats.rxRate, "B/s")
            color: Theme.green
            font.family: Theme.font
            font.pixelSize: 14
        }

        Text {
            text: "↑ " + Theme.bytes(Stats.txRate, "B/s")
            color: Theme.accentLight
            font.family: Theme.font
            font.pixelSize: 14
        }

        Text {
            visible: Stats.gateway !== ""
            text: "gw " + Stats.gateway
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 13
        }
    }

    Canvas {
        id: chart
        width: parent.width
        height: 70

        Connections {
            target: Stats
            function onNetHistoryChanged() {
                chart.requestPaint();
            }
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.fillStyle = Theme.track;
            ctx.fillRect(0, 0, width, height);
            const h = Stats.netHistory;
            if (h.length < 2)
                return;
            const step = width / 59;
            const x0 = width - (h.length - 1) * step;
            const line = (key, color) => {
                ctx.beginPath();
                h.forEach((s, i) => {
                    const y = height - 2 - (height - 4) * s[key] / root.peak;
                    if (i === 0)
                        ctx.moveTo(x0, y);
                    else
                        ctx.lineTo(x0 + i * step, y);
                });
                ctx.strokeStyle = color;
                ctx.lineWidth = 1.5;
                ctx.stroke();
            };
            line("rx", Theme.green);
            line("tx", Theme.accentLight);
        }
    }

    Text {
        text: "last 3 min, peak " + Theme.bytes(root.peak, "B/s")
        color: Theme.dim
        font.family: Theme.font
        font.pixelSize: 12
    }

    Item {
        width: parent.width
        implicitHeight: header.implicitHeight

        Text {
            id: header
            text: "Top bandwidth"
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 12
        }

        Row {
            anchors.right: parent.right
            anchors.baseline: header.baseline
            spacing: 10

            Text {
                text: "◀ down"
                color: Theme.green
                font.family: Theme.font
                font.pixelSize: 12
            }

            Text {
                text: "up ▶"
                color: Theme.accentLight
                font.family: Theme.font
                font.pixelSize: 12
            }
        }
    }

    // Fixed delegate count so updates reuse the same rows instead of rebuilding
    // (and resizing) the popup every refresh.
    Repeater {
        model: root.maxRows

        NetProcRow {
            required property int index

            readonly property var proc: Stats.netProcs[index] ?? null

            width: parent.width
            label: proc ? proc.name : ""
            rx: proc ? proc.rx : 0
            tx: proc ? proc.tx : 0
            rxPeak: root.rxPeak
            txPeak: root.txPeak
            valueText: proc ? "↓" + Theme.bytes(proc.rx, "B/s") + "  ↑" + Theme.bytes(proc.tx, "B/s") : ""
        }
    }
}
