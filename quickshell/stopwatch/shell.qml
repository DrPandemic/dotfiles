import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    readonly property string stateDir: Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state"
    readonly property real fullDayHours: 8

    property var days: ({})
    property real runningSince: 0
    property real now: Date.now() / 1000
    property date month: new Date(new Date().getFullYear(), new Date().getMonth(), 1)
    property string selected: dayKey(new Date())
    readonly property string today: dayKey(new Date(now * 1000))

    function dayKey(d) {
        return Qt.formatDate(d, "yyyy-MM-dd");
    }

    function parseState(text) {
        try {
            runningSince = JSON.parse(text).running_since || 0;
        } catch (e) {}
        now = Date.now() / 1000;
    }

    // A crash mid-close can log a session twice under the same start; the later row wins.
    function parseHistory(text) {
        const byStart = {};
        for (const line of text.split("\n")) {
            try {
                const r = JSON.parse(line);
                byStart[r.start] = r;
            } catch (e) {}
        }
        const out = {};
        for (const r of Object.values(byStart))
            (out[r.day] = out[r.day] || []).push([r.start, r.end]);
        for (const k in out)
            out[k].sort((a, b) => a[0] - b[0]);
        days = out;
    }

    function sessions(key) {
        const out = (days[key] || []).map(p => ({ start: p[0], end: p[1], running: false }));
        if (runningSince && dayKey(new Date(runningSince * 1000)) === key)
            out.push({ start: runningSince, end: now, running: true });
        return out;
    }

    function total(key) {
        return sessions(key).reduce((sum, s) => sum + s.end - s.start, 0);
    }

    function monthTotal() {
        let sum = 0;
        for (const c of cells())
            if (c)
                sum += total(c);
        return sum;
    }

    function daySpan(key) {
        const d = new Date(key + "T00:00");
        return { lo: d.getTime() / 1000, hi: new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1).getTime() / 1000 };
    }

    function fmtDur(secs) {
        const m = Math.floor(secs / 60);
        return Math.floor(m / 60) + ":" + String(m % 60).padStart(2, "0");
    }

    function fmtClock(t) {
        return Qt.formatDateTime(new Date(t * 1000), "HH:mm");
    }

    // Monday-first grid of day keys, with "" padding before the 1st and after the last day.
    function cells() {
        const y = month.getFullYear();
        const m = month.getMonth();
        const offset = (new Date(y, m, 1).getDay() + 6) % 7;
        const count = new Date(y, m + 1, 0).getDate();
        const out = [];
        for (let i = 0; i < offset; i++)
            out.push("");
        for (let d = 1; d <= count; d++)
            out.push(dayKey(new Date(y, m, d)));
        while (out.length % 7)
            out.push("");
        return out;
    }

    function shiftMonth(n) {
        month = new Date(month.getFullYear(), month.getMonth() + n, 1);
    }

    FileView {
        path: root.stateDir + "/stopwatch.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.parseState(text())
    }

    FileView {
        path: root.stateDir + "/stopwatch.jsonl"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.parseHistory(text())
    }

    Process {
        id: toggler
        command: [Quickshell.env("STOPWATCH_BIN"), "toggle"]
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = Date.now() / 1000
    }

    component Button: Rectangle {
        id: btn

        property string label
        property bool active: false
        signal clicked

        width: btnText.implicitWidth + 16
        height: btnText.implicitHeight + 8
        radius: 4
        color: active ? "#5e81ac" : (btnMouse.containsMouse ? "#434c5e" : "transparent")

        Text {
            id: btnText
            anchors.centerIn: parent
            text: btn.label
            color: "#eceff4"
            font.pixelSize: 13
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: btn.clicked()
        }
    }

    DismissLayer {}

    PanelWindow {
        screen: {
            const want = Quickshell.env("STOPWATCH_SCREEN");
            const screens = Quickshell.screens;
            for (let i = 0; i < screens.length; i++)
                if (screens[i].name === want)
                    return screens[i];
            return screens[0];
        }
        anchors.bottom: true
        margins.bottom: 6
        implicitWidth: 440
        implicitHeight: 560
        exclusiveZone: 0
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "stopwatch"
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
                text: "Timer"
                color: "#eceff4"
                font.pixelSize: 16
                font.bold: true
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 12
                y: 9
                spacing: 4

                Button {
                    label: root.runningSince ? "Stop" : "Start"
                    active: root.runningSince > 0
                    onClicked: toggler.running = true
                }

                Button {
                    label: "✕"
                    onClicked: Qt.quit()
                }
            }

            Item {
                id: nav
                x: 12
                y: 44
                width: parent.width - 24
                height: 28

                Button {
                    anchors.verticalCenter: parent.verticalCenter
                    label: "‹"
                    onClicked: root.shiftMonth(-1)
                }

                Text {
                    anchors.centerIn: parent
                    textFormat: Text.RichText
                    text: Qt.formatDate(root.month, "MMMM yyyy") + `&nbsp;&nbsp;<font color="#9aa5b8">${root.fmtDur(root.monthTotal())}</font>`
                    color: "#eceff4"
                    font.pixelSize: 14
                }

                Button {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    label: "›"
                    onClicked: root.shiftMonth(1)
                }
            }

            Grid {
                id: calendar
                x: 12
                y: nav.y + nav.height + 6
                columns: 7
                spacing: 4

                readonly property real cellW: (parent.width - 24 - 6 * spacing) / 7

                Repeater {
                    model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                    Text {
                        required property string modelData
                        width: calendar.cellW
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: "#ffcc66"
                        font.pixelSize: 11
                    }
                }

                Repeater {
                    model: root.cells()
                    Rectangle {
                        id: cell

                        required property string modelData
                        readonly property real secs: modelData ? root.total(modelData) : 0

                        width: calendar.cellW
                        height: 44
                        radius: 4
                        color: secs > 0 ? Qt.rgba(0.369, 0.506, 0.675, 0.15 + 0.75 * Math.min(1, secs / 3600 / root.fullDayHours)) : (cellMouse.containsMouse && modelData ? "#434c5e" : "transparent")
                        border.width: modelData === root.selected ? 1 : 0
                        border.color: "#eceff4"

                        Text {
                            x: 5
                            y: 3
                            visible: cell.modelData !== ""
                            text: Number(cell.modelData.slice(8))
                            color: cell.modelData === root.today ? "#ff6699" : "#d8dee9"
                            font.pixelSize: 11
                            font.bold: cell.modelData === root.today
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 4
                            visible: cell.secs >= 60
                            text: root.fmtDur(cell.secs)
                            color: "#eceff4"
                            font.pixelSize: 13
                        }

                        MouseArea {
                            id: cellMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: cell.modelData !== ""
                            onClicked: root.selected = cell.modelData
                        }
                    }
                }
            }

            Rectangle {
                id: divider
                x: 12
                y: calendar.y + calendar.height + 12
                width: parent.width - 24
                height: 1
                color: "#4c566a"
            }

            Text {
                id: dayTitle
                x: 16
                y: divider.y + 10
                text: Qt.formatDate(new Date(root.selected + "T00:00"), "dddd, MMMM d")
                color: "#eceff4"
                font.pixelSize: 14
                font.bold: true
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 16
                y: dayTitle.y
                text: "Total " + root.fmtDur(root.total(root.selected))
                color: "#eceff4"
                font.pixelSize: 14
                font.bold: true
            }

            Item {
                id: timeline

                readonly property var list: root.sessions(root.selected)
                readonly property var span: root.daySpan(root.selected)
                property real hoverStart: -1
                readonly property var hovered: list.find(s => s.start === hoverStart) || null

                function xOf(t) {
                    return (t - span.lo) / (span.hi - span.lo) * width;
                }

                x: 16
                y: dayTitle.y + dayTitle.height + 12
                width: parent.width - 32
                height: 36

                Rectangle {
                    width: parent.width
                    height: 14
                    radius: 3
                    color: "#3b4252"
                }

                Repeater {
                    model: timeline.list
                    Rectangle {
                        required property var modelData
                        readonly property bool lit: timeline.hoverStart === modelData.start
                        x: timeline.xOf(modelData.start)
                        width: Math.max(2, timeline.xOf(modelData.end) - x)
                        height: 14
                        radius: 3
                        color: modelData.running ? (lit ? "#b8d4a0" : "#a3be8c") : (lit ? "#81a1c1" : "#5e81ac")

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: timeline.hoverStart = parent.modelData.start
                            onExited: timeline.hoverStart = -1
                        }
                    }
                }

                Repeater {
                    model: 9
                    Text {
                        required property int index
                        x: Math.max(0, Math.min(timeline.width - implicitWidth, index / 8 * timeline.width - implicitWidth / 2))
                        y: 18
                        text: String(index * 3).padStart(2, "0")
                        color: "#9aa5b8"
                        font.pixelSize: 11
                    }
                }

                Rectangle {
                    visible: timeline.hovered !== null
                    x: timeline.hovered ? Math.max(0, Math.min(timeline.width - width, timeline.xOf(timeline.hovered.start))) : 0
                    y: -height - 4
                    width: tip.implicitWidth + 12
                    height: tip.implicitHeight + 8
                    radius: 4
                    color: "#e63b4252"

                    Text {
                        id: tip
                        anchors.centerIn: parent
                        color: "#eceff4"
                        font.pixelSize: 12
                        text: timeline.hovered ? root.fmtClock(timeline.hovered.start) + " – " + (timeline.hovered.running ? "now" : root.fmtClock(timeline.hovered.end)) + "   " + root.fmtDur(timeline.hovered.end - timeline.hovered.start) : ""
                    }
                }
            }

            ListView {
                x: 16
                y: timeline.y + timeline.height + 8
                width: parent.width - 32
                height: parent.height - y - 12
                clip: true
                spacing: 2
                model: root.sessions(root.selected)

                delegate: Item {
                    required property var modelData
                    width: ListView.view.width
                    height: sessionText.implicitHeight + 4

                    Text {
                        id: sessionText
                        text: root.fmtClock(parent.modelData.start) + " – " + (parent.modelData.running ? "now" : root.fmtClock(parent.modelData.end))
                        color: parent.modelData.running ? "#a3be8c" : "#d8dee9"
                        font.pixelSize: 13
                    }

                    Text {
                        anchors.right: parent.right
                        text: root.fmtDur(parent.modelData.end - parent.modelData.start)
                        color: "#9aa5b8"
                        font.pixelSize: 13
                    }
                }

                Text {
                    visible: parent.count === 0
                    text: "Not started"
                    color: "#9aa5b8"
                    font.pixelSize: 13
                }
            }
        }
    }
}
