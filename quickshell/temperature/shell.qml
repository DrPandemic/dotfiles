import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    // get-max-temp logs a row every ~30s, so a longer silence means the machine was suspended.
    readonly property int gapSecs: 120
    readonly property var ranges: [
        { label: "10m", hours: 1 / 6 },
        { label: "1h", hours: 1 },
        { label: "6h", hours: 6 },
        { label: "24h", hours: 24 },
        { label: "Boot", hours: 0 }
    ]
    readonly property var tempSeries: [
        { key: "cpu", label: "CPU", color: "#f2a65f" },
        { key: "gpu", label: "GPU", color: "#a3be8c" },
        { key: "gpu_hot", label: "GPU hotspot", color: "#bf616a" },
        { key: "vram", label: "VRAM", color: "#b48ead" },
        { key: "nvme", label: "NVMe", color: "#5fb3f2" }
    ]
    // Unplugged headers read 0 forever, so a fan only shows once it has spun; `always` keeps fans that idle at 0.
    readonly property var fanSeries: [
        { key: "cpu_fan", label: "CPU", color: "#f2a65f" },
        { key: "sys_fan1", label: "Sys 1", color: "#88c0d0" },
        { key: "sys_fan2", label: "Sys 2", color: "#e5e9f0" },
        { key: "sys_fan3", label: "Sys 3", color: "#8fbcbb" },
        { key: "sys_fan4", label: "Sys 4", color: "#f0a0c8" },
        { key: "gpu_fan", label: "GPU", color: "#a3be8c", always: true }
    ]

    property real rangeHours: 0
    property var rows: []
    readonly property var defaultHidden: ({ sys_fan1: true, sys_fan4: true })

    property var hidden: defaultHidden
    property real now: Date.now() / 1000
    property var hoverRow: null
    property var shownTemps: []
    property var shownFans: []
    property real tLo: 30
    property real tStep: 10
    property real fStep: 250
    property int tickCount: 5

    function parse(text) {
        const out = [];
        const lines = text.split("\n");
        for (let i = 0; i < lines.length; i++) {
            if (lines[i] === "")
                continue;
            try {
                out.push(JSON.parse(lines[i]));
            } catch (e) {}
        }
        now = Date.now() / 1000;
        rows = out;
    }

    function startT() {
        if (rangeHours > 0)
            return now - rangeHours * 3600;
        return rows.length ? Math.min(rows[0].t, now - 60) : now - 60;
    }

    function firstIndex(t) {
        let lo = 0;
        let hi = rows.length;
        while (lo < hi) {
            const mid = (lo + hi) >> 1;
            if (rows[mid].t < t)
                lo = mid + 1;
            else
                hi = mid;
        }
        return lo;
    }

    function visibleRows() {
        return rows.slice(firstIndex(startT()));
    }

    function latest(key) {
        for (let i = rows.length - 1; i >= 0; i--)
            if (rows[i][key] !== undefined)
                return rows[i][key];
        return null;
    }

    function peak(key) {
        let best = null;
        for (const r of visibleRows())
            if (r[key] !== undefined && (best === null || r[key] > best))
                best = r[key];
        return best;
    }

    function bounds(list) {
        let lo = Infinity;
        let hi = -Infinity;
        for (const r of visibleRows()) {
            for (const s of list) {
                const v = r[s.key];
                if (hidden[s.key] || v === undefined)
                    continue;
                lo = Math.min(lo, v);
                hi = Math.max(hi, v);
            }
        }
        return [lo, hi];
    }

    function niceStep(raw) {
        return [5, 10, 20, 25, 50, 100, 200, 250, 500, 1000, 2000, 5000].find(s => s >= raw) || 10000;
    }

    // The fan axis reuses the temperature grid lines, so it gets the same number of ticks.
    function rescale() {
        const present = s => s.always || rows.some(r => r[s.key] > 0);
        shownTemps = tempSeries.filter(present);
        shownFans = fanSeries.filter(present);
        let [lo, hi] = bounds(shownTemps);
        if (lo > hi) {
            lo = 35;
            hi = 85;
        }
        tStep = niceStep((hi - lo + 10) / 4);
        tLo = Math.floor((lo - 5) / tStep) * tStep;
        tickCount = Math.max(1, Math.ceil((hi + 5 - tLo) / tStep));
        const fanMax = bounds(shownFans)[1];
        fStep = niceStep((fanMax > 0 ? fanMax * 1.1 : 1000) / tickCount);
        canvas.requestPaint();
    }

    function toggle(key) {
        const h = Object.assign({}, hidden);
        h[key] = !h[key];
        hidden = h;
    }

    function solo(key) {
        const others = shownTemps.concat(shownFans).filter(s => s.key !== key);
        if (!hidden[key] && others.every(s => hidden[s.key])) {
            hidden = defaultHidden;
            return;
        }
        const h = {};
        for (const s of others)
            h[s.key] = true;
        hidden = h;
    }

    function fmtTime(t) {
        const span = now - startT();
        return Qt.formatDateTime(new Date(t * 1000), span <= 86400 ? "HH:mm" : "ddd HH:mm");
    }

    function tipLine(list, unit) {
        const r = hoverRow;
        const parts = [];
        for (const s of list)
            if (!hidden[s.key] && r[s.key] !== undefined)
                parts.push(`<font color="${s.color}">${s.label} ${r[s.key]}${unit}</font>`);
        return parts.join("&nbsp;&nbsp;");
    }

    onRowsChanged: rescale()
    onRangeHoursChanged: rescale()
    onHiddenChanged: rescale()

    FileView {
        path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/temp-history.jsonl"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.parse(text())
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: {
            root.now = Date.now() / 1000;
            root.rescale();
        }
    }

    component Chip: Rectangle {
        id: chip

        required property var modelData
        required property var src
        property string unit: ""
        readonly property var cur: src.latest(modelData.key)
        readonly property var max: src.peak(modelData.key)

        width: chipText.implicitWidth + 12
        height: chipText.implicitHeight + 6
        radius: 4
        color: chipMouse.containsMouse ? "#434c5e" : "transparent"
        opacity: src.hidden[modelData.key] ? 0.4 : 1

        Text {
            id: chipText
            anchors.centerIn: parent
            textFormat: Text.RichText
            text: `<font color="${chip.modelData.color}">${chip.modelData.label} ${chip.cur === null ? "—" : chip.cur + chip.unit}</font>`
                + (chip.max === null ? "" : ` <font color="#9aa5b8">↑${chip.max}${chip.unit}</font>`)
            font.pixelSize: 13
        }

        MouseArea {
            id: chipMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: mouse => mouse.modifiers & Qt.ShiftModifier ? chip.src.solo(chip.modelData.key) : chip.src.toggle(chip.modelData.key)
        }
    }

    PanelWindow {
        id: win

        screen: {
            const want = Quickshell.env("TEMP_SCREEN");
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
        implicitWidth: 760
        implicitHeight: 420
        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "temperature-chart"
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

            Text {
                x: 16
                y: 12
                text: "Temperatures & fans"
                color: "#eceff4"
                font.pixelSize: 16
                font.bold: true
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

            Column {
                id: legend
                x: 12
                y: 40

                Row {
                    spacing: 4

                    Repeater {
                        model: root.shownTemps
                        Chip {
                            src: root
                            unit: "°"
                        }
                    }
                }

                Row {
                    spacing: 4

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        leftPadding: 6
                        rightPadding: 4
                        text: "Fans ┈ rpm"
                        color: "#9aa5b8"
                        font.pixelSize: 13
                    }

                    Repeater {
                        model: root.shownFans
                        Chip {
                            src: root
                        }
                    }
                }
            }

            Canvas {
                id: canvas
                anchors.fill: parent
                anchors.topMargin: legend.y + legend.height + 10
                anchors.leftMargin: 44
                anchors.rightMargin: 48
                anchors.bottomMargin: 30

                function xOf(t) {
                    const s = root.startT();
                    return (t - s) / (root.now - s) * (width - 4);
                }

                function tempY(v) {
                    return height - (v - root.tLo) / (root.tStep * root.tickCount) * height;
                }

                function fanY(v) {
                    return height - v / (root.fStep * root.tickCount) * height;
                }

                // Keeps the highest reading per 2px column, so long uptimes stay cheap to draw without hiding spikes.
                function segments(key, vis, yOf) {
                    const segs = [];
                    let cur = null;
                    let prevT = -Infinity;
                    for (const r of vis) {
                        const v = r[key];
                        if (v === undefined || r.t - prevT > root.gapSecs)
                            cur = null;
                        prevT = r.t;
                        if (v === undefined)
                            continue;
                        const x = Math.round(xOf(r.t) / 2) * 2;
                        if (!cur) {
                            cur = [];
                            segs.push(cur);
                        }
                        const last = cur[cur.length - 1];
                        if (last && last.x === x)
                            last.y = Math.min(last.y, yOf(v));
                        else
                            cur.push({ x: x, y: yOf(v) });
                    }
                    return segs;
                }

                function drawSeries(ctx, list, vis, yOf, dash) {
                    ctx.setLineDash(dash);
                    for (const s of list) {
                        if (root.hidden[s.key])
                            continue;
                        ctx.strokeStyle = s.color;
                        ctx.fillStyle = s.color;
                        for (const seg of segments(s.key, vis, yOf)) {
                            ctx.beginPath();
                            seg.forEach((p, i) => i ? ctx.lineTo(p.x, p.y) : ctx.moveTo(p.x, p.y));
                            ctx.stroke();
                            const p = seg[seg.length - 1];
                            ctx.beginPath();
                            ctx.arc(p.x, p.y, 3, 0, 2 * Math.PI);
                            ctx.fill();
                        }
                    }
                }

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    ctx.lineWidth = 1;
                    ctx.strokeStyle = "#3b4252";
                    for (let i = 0; i <= root.tickCount; i++) {
                        const y = height - i / root.tickCount * height;
                        ctx.beginPath();
                        ctx.moveTo(0, y);
                        ctx.lineTo(width, y);
                        ctx.stroke();
                    }

                    const vis = root.visibleRows();
                    ctx.lineJoin = "round";
                    ctx.lineWidth = 2;
                    drawSeries(ctx, root.shownFans, vis, fanY, [2, 4]);
                    drawSeries(ctx, root.shownTemps, vis, tempY, []);
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onPositionChanged: mouse => {
                        const s = root.startT();
                        const t = s + mouse.x / width * (root.now - s);
                        const i = root.firstIndex(t);
                        const cands = [root.rows[i - 1], root.rows[i]].filter(r => r && r.t >= s);
                        cands.sort((a, b) => Math.abs(a.t - t) - Math.abs(b.t - t));
                        root.hoverRow = cands.length && Math.abs(cands[0].t - t) <= root.gapSecs ? cands[0] : null;
                    }
                    onExited: root.hoverRow = null
                }

                Repeater {
                    model: root.tickCount + 1
                    Item {
                        required property int index
                        y: canvas.height - index / root.tickCount * canvas.height

                        Text {
                            x: -implicitWidth - 8
                            y: -implicitHeight / 2
                            text: (root.tLo + index * root.tStep) + "°"
                            color: "#9aa5b8"
                            font.pixelSize: 11
                        }

                        Text {
                            x: canvas.width + 8
                            y: -implicitHeight / 2
                            text: index * root.fStep
                            color: "#9aa5b8"
                            font.pixelSize: 11
                        }
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
                    visible: root.hoverRow !== null
                    x: root.hoverRow ? canvas.xOf(root.hoverRow.t) : 0
                    width: 1
                    height: canvas.height
                    color: "#d8dee9"
                }

                Rectangle {
                    visible: root.hoverRow !== null
                    x: root.hoverRow ? Math.max(0, Math.min(canvas.width - width, canvas.xOf(root.hoverRow.t) + 8)) : 0
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
                            if (!root.hoverRow)
                                return "";
                            return Qt.formatDateTime(new Date(root.hoverRow.t * 1000), "HH:mm:ss") + "&nbsp;&nbsp;" + root.tipLine(root.shownTemps, "°")
                                + "<br>Fans rpm&nbsp;&nbsp;" + root.tipLine(root.shownFans, "");
                        }
                    }
                }
            }
        }
    }
}
