pragma Singleton

import QtQuick
import Quickshell
import Quickshell.I3
import Quickshell.Io

Singleton {
    id: root

    property string mode: "default"
    property string layout: ""
    property var layouts: []

    readonly property var countries: ({ "US": "US", "Canada": "CA", "France": "FR", "UK": "GB" })
    readonly property string country: {
        const m = layout.match(/\(([^)]+)\)/);
        return m ? (countries[m[1]] || "") : "";
    }
    readonly property string flag: country ? String.fromCodePoint(...[...country].map(c => 0x1F1E6 + c.charCodeAt(0) - 65)) : layout

    function data(event) {
        return typeof event.data === "string" ? JSON.parse(event.data) : event.data;
    }

    function setInput(input) {
        if (!input || input.type !== "keyboard" || !input.xkb_active_layout_name)
            return;
        layout = input.xkb_active_layout_name;
        layouts = input.xkb_layout_names || layouts;
    }

    I3IpcListener {
        subscriptions: ["mode", "input"]
        onIpcEvent: event => {
            const d = root.data(event);
            if (event.type === "mode")
                root.mode = d.change;
            else if (d.change === "xkb_layout" || d.change === "xkb_keymap" || d.change === "added")
                root.setInput(d.input);
        }
    }

    Process {
        running: true
        command: ["swaymsg", "-r", "-t", "get_inputs"]
        stdout: StdioCollector {
            onStreamFinished: {
                const inputs = JSON.parse(text);
                root.setInput(inputs.filter(i => i.type === "keyboard").pop());
            }
        }
    }
}
