pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int cpu: 0
    property var cores: []
    property var loadavg: []
    property var cpuPrev: []
    property int cpuWatchers: 0

    property var mem: ({})

    property int maxTemp: 0
    property var sensors: []

    property int diskMax: 0
    property var disks: []

    property int gpuBusy: 0
    property real vramUsed: 0
    property real vramTotal: 0
    property real gttUsed: 0
    property real gttTotal: 0

    property var updates: []
    property bool updatesChecked: false

    property var kb: ({})
    property var weather: ({})

    property string iface: ""
    property string ipCidr: ""
    property string gateway: ""
    property bool online: true
    property real rxRate: 0
    property real txRate: 0
    property var netHistory: []
    property var netPrev: null

    property string stopwatch: ""
    property var oats: ({})
    property var sunTint: ({})
    property bool idleInhibited: false

    function parseJson(text, fallback) {
        try {
            return JSON.parse(text);
        } catch (e) {
            return fallback;
        }
    }

    function parseCpu(text) {
        const lines = text.split("\n");
        const samples = [];
        for (const l of lines) {
            if (!l.startsWith("cpu"))
                continue;
            const f = l.split(/\s+/).slice(1, 9).map(Number);
            samples.push({ idle: f[3] + f[4], total: f.reduce((a, b) => a + b, 0) });
        }
        const prev = cpuPrev;
        const pct = samples.map((s, i) => {
            const p = prev[i] || { idle: 0, total: 0 };
            const dt = s.total - p.total;
            return dt > 0 ? Math.round(100 * (1 - (s.idle - p.idle) / dt)) : 0;
        });
        cpuPrev = samples;
        cpu = pct[0] || 0;
        cores = pct.slice(1);
        const la = lines.find(l => /^\d+\.\d+ \d+\.\d+ \d+\.\d+/.test(l));
        if (la)
            loadavg = la.split(" ").slice(0, 3);
    }

    function parseTemps(text) {
        const lines = text.split(/\r|\n/).filter(l => l !== "");
        maxTemp = parseInt(lines[0]) || 0;
        sensors = lines.slice(1).map(l => {
            const m = l.match(/^(.*) \((\S+) : (-?\d+)°C\)$/);
            return m ? { label: m[1], key: m[2], temp: Number(m[3]) } : null;
        }).filter(s => s);
    }

    function parseDisks(text) {
        const lines = text.split(/\r|\n/).filter(l => l !== "");
        diskMax = parseInt(lines[0]) || 0;
        disks = lines.slice(1).map(l => {
            const m = l.match(/^(\S+)\s*:\s*([\d.]+)%/);
            return m ? { name: m[1], util: Number(m[2]) } : null;
        }).filter(d => d);
    }

    function parseNetDev(text) {
        if (!iface)
            return;
        const line = text.split("\n").find(l => l.trim().startsWith(iface + ":"));
        if (!line)
            return;
        const f = line.split(":")[1].trim().split(/\s+/).map(Number);
        const now = Date.now() / 1000;
        const cur = { t: now, rx: f[0], tx: f[8] };
        const p = netPrev;
        if (p && p.t < now) {
            rxRate = Math.max(0, (cur.rx - p.rx) / (now - p.t));
            txRate = Math.max(0, (cur.tx - p.tx) / (now - p.t));
            netHistory = netHistory.concat([{ rx: rxRate, tx: txRate }]).slice(-60);
        }
        netPrev = cur;
    }

    function parseRoute(text) {
        const docs = text.split("\n").filter(l => l !== "").map(l => parseJson(l, []));
        const route = (docs[0] || [])[0];
        online = !!route;
        if (!route)
            return;
        if (route.dev !== iface) {
            netPrev = null;
            netHistory = [];
        }
        iface = route.dev;
        gateway = route.gateway || "";
        const link = (docs[1] || []).find(a => a.ifname === route.dev);
        const addr = link ? (link.addr_info || []).find(a => a.family === "inet") : null;
        ipCidr = addr ? addr.local + "/" + addr.prefixlen : route.prefsrc || "";
    }

    Poll {
        interval: root.cpuWatchers > 0 ? 2000 : 10000
        command: ["cat", "/proc/stat", "/proc/loadavg"]
        onOutput: text => root.parseCpu(text)
    }

    Poll {
        interval: 5000
        command: [Theme.bin + "get-memory"]
        onOutput: text => root.mem = root.parseJson(text, root.mem)
    }

    Poll {
        interval: 10000
        command: [Theme.bin + "get-max-temp"]
        onOutput: text => root.parseTemps(text)
    }

    Poll {
        interval: 10000
        command: [Theme.bin + "get-max-disk"]
        onOutput: text => root.parseDisks(text)
    }

    Poll {
        readonly property string dev: "/sys/bus/pci/devices/0000:03:00.0/"
        interval: 10000
        command: ["cat", dev + "gpu_busy_percent", dev + "mem_info_vram_used", dev + "mem_info_vram_total", dev + "mem_info_gtt_used", dev + "mem_info_gtt_total"]
        onOutput: text => {
            const v = text.split("\n").map(Number);
            root.gpuBusy = v[0] || 0;
            root.vramUsed = v[1] || 0;
            root.vramTotal = v[2] || 0;
            root.gttUsed = v[3] || 0;
            root.gttTotal = v[4] || 0;
        }
    }

    Poll {
        id: updatesPoll
        interval: 600000
        command: ["sh", "-c", "checkupdates 2>/dev/null"]
        onOutput: text => {
            root.updates = text.split("\n").filter(l => l !== "");
            root.updatesChecked = true;
        }
    }

    Poll {
        id: kbPoll
        interval: 30000
        command: [Theme.waybarDir + "keyboard-battery.rb"]
        onOutput: text => root.kb = root.parseJson(text, root.kb)
    }

    Poll {
        interval: 3600000
        command: ["wttrbar", "--location", "Montreal", "--hide-conditions"]
        onOutput: text => root.weather = root.parseJson(text, root.weather)
    }

    Poll {
        interval: 30000
        command: ["sh", "-c", "ip -j route get 1.1.1.1 2>/dev/null || echo '[]'; ip -j addr"]
        onOutput: text => root.parseRoute(text)
    }

    Poll {
        interval: 3000
        command: ["cat", "/proc/net/dev"]
        onOutput: text => root.parseNetDev(text)
    }

    Stream {
        command: [Theme.bin + "stopwatch"]
        onLine: data => root.stopwatch = data
    }

    Stream {
        command: ["oats", "waybar"]
        onLine: data => root.oats = root.parseJson(data, root.oats)
    }

    Stream {
        command: [Theme.bin + "sun-tint", "--timezone", "America/Montreal", "--intensity", "50", "--default", "on"]
        onLine: data => root.sunTint = root.parseJson(data, root.sunTint)
    }

    function refreshUpdates() {
        updatesPoll.refresh();
    }

    function refreshKeyboard() {
        kbPoll.refresh();
    }

    IpcHandler {
        target: "bar"

        function refreshKeyboard(): void {
            root.refreshKeyboard();
        }
    }
}
