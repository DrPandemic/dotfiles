import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    readonly property string stateDir: Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"
    // HEARTBEAT_SECS in keyboard-battery.rb plus slack: rows further apart than this mean the keyboard was gone in between.
    readonly property int heartbeatSecs: 2100
    // SETTLE_SECS in keyboard-battery.rb: a gap's end level is read this long after the half wakes.
    readonly property int settleSecs: 900
    readonly property int minGapSecs: 3600
    readonly property int chargeJump: 3
    readonly property var sides: [
        { key: "L", label: "Left", color: "#5fb3f2" },
        { key: "R", label: "Right", color: "#f2a65f" }
    ]
    readonly property var ranges: [
        { label: "6h", hours: 6 },
        { label: "24h", hours: 24 },
        { label: "7d", hours: 168 },
        { label: "30d", hours: 720 },
        { label: "All", hours: 0 }
    ]

    property int rangeHours: 24
    property string rawText: ""
    property string rollupText: ""
    property var series: ({ L: [], R: [], gaps: { L: [], R: [] }, first: 0 })
    property real now: Date.now() / 1000
    property real hoverT: -1

    function parseLines(text, fn) {
        const lines = text.split("\n");
        for (let i = 0; i < lines.length; i++) {
            if (lines[i] === "")
                continue;
            try {
                fn(JSON.parse(lines[i]));
            } catch (e) {}
        }
    }

    function gapsBetween(segs) {
        const gaps = [];
        for (let i = 1; i < segs.length; i++) {
            const a = segs[i - 1][segs[i - 1].length - 1];
            const b = segs[i][0];
            if (b.t - a.t < minGapSecs)
                continue;
            let after = b.v;
            for (const p of segs[i]) {
                if (p.t > b.t + settleSecs)
                    break;
                after = p.v;
            }
            const hours = (b.t - a.t) / 3600;
            const delta = after - a.v;
            gaps.push({ t0: a.t, v0: a.v, t1: b.t, v1: after, hours: hours, delta: delta, charged: delta >= chargeJump, rate: delta / hours });
        }
        return gaps;
    }

    function gapAt(key, t) {
        for (const g of series.gaps[key])
            if (g.t0 < t && t < g.t1)
                return g;
        return null;
    }

    function fmtRate(g) {
        return g.charged ? "charged" : (g.rate > 0 ? "+" : g.rate < 0 ? "−" : "") + Math.abs(g.rate).toFixed(2) + "%/h";
    }

    function fmtGap(g) {
        const delta = (g.delta > 0 ? "+" : g.delta < 0 ? "−" : "") + Math.abs(g.delta) + "%";
        return `${delta} in ${g.hours.toFixed(1)}h` + (g.charged ? ", charged" : `, ${fmtRate(g)}`);
    }

    function rebuild() {
        const byHour = {};
        const rows = [];
        parseLines(rollupText, r => {
            if (!byHour[r.t]) {
                byHour[r.t] = { t: r.t, L: null, R: null, gap_h: r.gap_h };
                rows.push(byHour[r.t]);
            }
            byHour[r.t][r.side] = r.last;
        });
        parseLines(rawText, r => rows.push(r));
        rows.sort((a, b) => a.t - b.t);

        const out = { first: rows.length ? rows[0].t : now, gaps: {} };
        for (const side of sides) {
            const segs = [];
            let cur = null;
            let last = null;
            for (const row of rows) {
                const v = row[side.key];
                if (cur && (row.gap_h || !v || row.t - last.t > heartbeatSecs))
                    cur = null;
                if (!v)
                    continue;
                if (!cur) {
                    cur = [];
                    segs.push(cur);
                } else {
                    cur.push({ t: row.t, v: cur[cur.length - 1].v });
                }
                cur.push({ t: row.t, v: v });
                last = row;
            }
            if (cur && last && now - last.t < heartbeatSecs)
                cur.push({ t: now, v: cur[cur.length - 1].v });
            out[side.key] = segs;
            out.gaps[side.key] = gapsBetween(segs);
        }
        series = out;
        canvas.requestPaint();
    }

    function startT() {
        return rangeHours > 0 ? now - rangeHours * 3600 : Math.min(series.first, now - 3600);
    }

    readonly property var yAxis: {
        const s = startT();
        let lo = 100;
        let hi = 0;
        for (const side of sides) {
            const v = valueAt(side.key, s);
            if (v !== null) {
                lo = Math.min(lo, v);
                hi = Math.max(hi, v);
            }
            for (const seg of series[side.key])
                for (const p of seg)
                    if (p.t >= s) {
                        lo = Math.min(lo, p.v);
                        hi = Math.max(hi, p.v);
                    }
        }
        if (lo > hi)
            return { lo: 0, hi: 100, ticks: [0, 25, 50, 75, 100] };
        for (const step of [5, 10, 25]) {
            const a = Math.max(0, Math.floor((lo - 1) / step) * step);
            const b = Math.min(100, Math.ceil((hi + 1) / step) * step);
            if ((b - a) / step > 5)
                continue;
            const ticks = [];
            for (let v = a; v <= b; v += step)
                ticks.push(v);
            return { lo: a, hi: b, ticks: ticks };
        }
    }

    function valueAt(key, t) {
        const segs = series[key];
        for (const seg of segs) {
            if (t < seg[0].t || t > seg[seg.length - 1].t)
                continue;
            let v = seg[0].v;
            for (const p of seg) {
                if (p.t > t)
                    break;
                v = p.v;
            }
            return v;
        }
        return null;
    }

    function latest(key) {
        const segs = series[key];
        if (!segs.length)
            return null;
        const seg = segs[segs.length - 1];
        return seg[seg.length - 1].v;
    }

    function fmtTime(t) {
        const d = new Date(t * 1000);
        const span = now - startT();
        if (span <= 86400)
            return Qt.formatDateTime(d, "HH:mm");
        if (span <= 7 * 86400)
            return Qt.formatDateTime(d, "ddd HH:mm");
        return Qt.formatDateTime(d, "MMM d");
    }

    onRawTextChanged: rebuild()
    onRollupTextChanged: rebuild()
    onRangeHoursChanged: canvas.requestPaint()

    FileView {
        path: root.stateDir + "/keyboard-battery.jsonl"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.rawText = text()
    }

    FileView {
        path: root.stateDir + "/keyboard-battery-rollups.jsonl"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.rollupText = text()
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: {
            root.now = Date.now() / 1000;
            root.rebuild();
        }
    }

    PanelWindow {
        id: win

        screen: {
            const want = Quickshell.env("KB_SCREEN");
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
        implicitWidth: 680
        implicitHeight: 340
        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "keyboard-battery-chart"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        Rectangle {
            id: panel
            anchors.fill: parent
            radius: 8
            color: "#ee2b303b"
            border.color: "#4c566a"
            border.width: 1
            focus: true
            Keys.onEscapePressed: Qt.quit()

            property bool entered: false

            HoverHandler {
                onHoveredChanged: {
                    if (hovered)
                        panel.entered = true;
                    else if (panel.entered)
                        Qt.quit();
                }
            }

            Row {
                id: header
                x: 16
                y: 12
                spacing: 16

                Text {
                    text: "⌨ Keyboard battery"
                    color: "#eceff4"
                    font.pixelSize: 16
                    font.bold: true
                }

                Repeater {
                    model: root.sides
                    Text {
                        required property var modelData
                        readonly property var v: root.latest(modelData.key)
                        text: modelData.label + " " + (v === null ? "—" : v + "%")
                        color: modelData.color
                        font.pixelSize: 16
                    }
                }
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 12
                y: 9
                spacing: 4

                Repeater {
                    model: root.ranges
                    Rectangle {
                        required property var modelData
                        readonly property bool active: root.rangeHours === modelData.hours
                        width: label.implicitWidth + 14
                        height: label.implicitHeight + 6
                        radius: 4
                        color: active ? "#5e81ac" : (rangeMouse.containsMouse ? "#434c5e" : "transparent")

                        Text {
                            id: label
                            anchors.centerIn: parent
                            text: modelData.label
                            color: "#eceff4"
                            font.pixelSize: 13
                        }

                        MouseArea {
                            id: rangeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.rangeHours = modelData.hours
                        }
                    }
                }
            }

            Canvas {
                id: canvas
                anchors.fill: parent
                anchors.topMargin: 44
                anchors.leftMargin: 44
                anchors.rightMargin: 16
                anchors.bottomMargin: 30

                function xOf(t) {
                    const s = root.startT();
                    return (t - s) / (root.now - s) * (width - 4);
                }

                function yOf(v) {
                    const y = root.yAxis;
                    return height - (v - y.lo) / (y.hi - y.lo) * height;
                }

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    ctx.lineWidth = 1;
                    ctx.strokeStyle = "#3b4252";
                    for (const v of root.yAxis.ticks) {
                        ctx.beginPath();
                        ctx.moveTo(0, yOf(v));
                        ctx.lineTo(width, yOf(v));
                        ctx.stroke();
                    }
                    if (root.yAxis.lo < 20 && 20 < root.yAxis.hi) {
                        ctx.strokeStyle = "#bf616a";
                        ctx.setLineDash([4, 4]);
                        ctx.beginPath();
                        ctx.moveTo(0, yOf(20));
                        ctx.lineTo(width, yOf(20));
                        ctx.stroke();
                        ctx.setLineDash([]);
                    }

                    ctx.lineWidth = 1;
                    ctx.setLineDash([3, 3]);
                    ctx.globalAlpha = 0.6;
                    for (const side of root.sides) {
                        ctx.strokeStyle = side.color;
                        for (const g of root.series.gaps[side.key]) {
                            ctx.beginPath();
                            ctx.moveTo(xOf(g.t0), yOf(g.v0));
                            ctx.lineTo(xOf(g.t1), yOf(g.v1));
                            ctx.stroke();
                        }
                    }
                    ctx.setLineDash([]);
                    ctx.globalAlpha = 1;

                    ctx.font = "11px sans-serif";
                    ctx.textAlign = "center";
                    ctx.textBaseline = "middle";
                    const placed = [];
                    for (const side of root.sides) {
                        ctx.fillStyle = side.color;
                        for (const g of root.series.gaps[side.key]) {
                            const text = root.fmtRate(g);
                            const w = ctx.measureText(text).width + 4;
                            const x0 = xOf(g.t0);
                            const x1 = xOf(g.t1);
                            const mx = (x0 + x1) / 2;
                            const my = (yOf(g.v0) + yOf(g.v1)) / 2;
                            if (x1 - x0 < w + 8 || mx - w / 2 < 0 || mx + w / 2 > width)
                                continue;
                            for (const cy of [my - 10, my + 10, my - 24, my + 24]) {
                                const r = { x: mx - w / 2, y: cy - 7, w: w, h: 14 };
                                if (r.y < 0 || r.y + r.h > height || placed.some(o => r.x < o.x + o.w && o.x < r.x + r.w && r.y < o.y + o.h && o.y < r.y + r.h))
                                    continue;
                                placed.push(r);
                                ctx.fillText(text, mx, cy);
                                break;
                            }
                        }
                    }

                    ctx.lineWidth = 2;
                    ctx.lineJoin = "round";
                    for (const side of root.sides) {
                        ctx.strokeStyle = side.color;
                        for (const seg of root.series[side.key]) {
                            ctx.beginPath();
                            seg.forEach((p, i) => i ? ctx.lineTo(xOf(p.t), yOf(p.v)) : ctx.moveTo(xOf(p.t), yOf(p.v)));
                            ctx.stroke();
                            {
                                const p = seg[seg.length - 1];
                                ctx.fillStyle = side.color;
                                ctx.beginPath();
                                ctx.arc(xOf(p.t), yOf(p.v), 3.5, 0, 2 * Math.PI);
                                ctx.fill();
                            }
                        }
                    }

                    if (root.hoverT >= 0) {
                        ctx.lineWidth = 1;
                        ctx.strokeStyle = "#d8dee9";
                        ctx.beginPath();
                        ctx.moveTo(xOf(root.hoverT), 0);
                        ctx.lineTo(xOf(root.hoverT), height);
                        ctx.stroke();
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onPositionChanged: mouse => {
                        const s = root.startT();
                        root.hoverT = s + mouse.x / width * (root.now - s);
                        canvas.requestPaint();
                    }
                    onExited: {
                        root.hoverT = -1;
                        canvas.requestPaint();
                    }
                }

                Repeater {
                    model: root.yAxis.ticks
                    Text {
                        required property int modelData
                        x: -implicitWidth - 8
                        y: canvas.yOf(modelData) - implicitHeight / 2
                        text: modelData + "%"
                        color: "#9aa5b8"
                        font.pixelSize: 11
                    }
                }

                Repeater {
                    model: 5
                    Text {
                        required property int index
                        readonly property real t: root.startT() + index / 4 * (root.now - root.startT())
                        x: Math.max(0, Math.min(canvas.width - implicitWidth, canvas.xOf(t) - implicitWidth / 2))
                        y: canvas.height + 8
                        text: root.fmtTime(t)
                        color: "#9aa5b8"
                        font.pixelSize: 11
                    }
                }

                Rectangle {
                    visible: root.hoverT >= 0
                    x: Math.min(canvas.width - width, canvas.xOf(root.hoverT) + 8)
                    y: 4
                    width: tip.implicitWidth + 12
                    height: tip.implicitHeight + 8
                    radius: 4
                    color: "#e63b4252"

                    Text {
                        id: tip
                        anchors.centerIn: parent
                        color: "#eceff4"
                        font.pixelSize: 12
                        textFormat: Text.RichText
                        text: {
                            if (root.hoverT < 0)
                                return "";
                            const parts = [Qt.formatDateTime(new Date(root.hoverT * 1000), "ddd MMM d HH:mm")];
                            for (const side of root.sides) {
                                const v = root.valueAt(side.key, root.hoverT);
                                const g = v === null ? root.gapAt(side.key, root.hoverT) : null;
                                const state = v !== null ? v + "%" : g ? "asleep " + root.fmtGap(g) : "asleep";
                                parts.push(`<font color="${side.color}">${side.key} ${state}</font>`);
                            }
                            return parts.join("&nbsp;&nbsp;");
                        }
                    }
                }
            }
        }
    }
}
