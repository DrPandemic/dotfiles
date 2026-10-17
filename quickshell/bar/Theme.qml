pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property string bin: Quickshell.shellDir + "/../../bin/"
    readonly property string waybarDir: Quickshell.shellDir + "/../../waybar/"

    readonly property string font: "Roboto"
    readonly property string mono: "monospace"
    readonly property string regularIcons: "\uf192\uf111\uf073\uf06e\uf070\uf186\uf185"
    readonly property string brandIcons: "\uf269\uf1d0\uf1bc"
    readonly property var symbolFonts: ({ "♻": "DejaVuSansM Nerd Font Propo", "⌨": "DejaVuSansM Nerd Font Propo", "⚠": "DejaVuSansM Nerd Font Propo", "🖴": "Noto Sans Symbols 2", "🌪": "Noto Sans Symbols 2" })
    readonly property int fontSize: 20
    readonly property int barHeight: 35

    readonly property color fg: "#ffffff"
    readonly property color barBg: Qt.rgba(43 / 255, 48 / 255, 59 / 255, 0.3)
    readonly property color wsBg: Qt.rgba(43 / 255, 48 / 255, 59 / 255, 0.8)
    readonly property color wsFocused: Qt.rgba(100 / 255, 114 / 255, 125 / 255, 0.2)
    readonly property color popupBg: "#f42b303b"
    readonly property color border: "#4c566a"
    readonly property color track: "#3b4252"
    readonly property color hover: "#434c5e"
    readonly property color text: "#eceff4"
    readonly property color subtext: "#d8dee9"
    readonly property color dim: "#9aa5b8"
    readonly property color accent: "#5e81ac"
    readonly property color accentLight: "#81a1c1"
    readonly property color green: "#a3be8c"
    readonly property color red: "#f8625c"
    readonly property color yellow: "#ffcc66"
    readonly property color pink: "#ff6699"
    readonly property color teal: "#99ffdd"
    readonly property color cream: "#ffead3"

    function html(s) {
        return String(s).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }

    // Waybar scripts emit Pango markup with \n or \r line breaks; Qt rich text wants <font> and <br>, and collapses runs of spaces.
    function pango(s) {
        return String(s || "").replace(/<span\s+(?:fg)?color=(['"])(.*?)\1\s*>/g, "<font color=\"$2\">").replace(/<\/span>/g, "</font>").replace(/ {2,}/g, m => "&nbsp;".repeat(m.length)).replace(/\r\n|\r|\n/g, "<br>").replace(/[\uf000-\uf8ff\u267b\u2328\u26a0]|\ud83d\uddb4|\ud83c\udf2a/g, icon);
    }

    // Pins each glyph to the face Pango falls back to for waybar's font list, so the bar renders the same glyphs.
    function icon(c) {
        if (symbolFonts[c])
            return `<span style="font-family:'${symbolFonts[c]}'">${c}</span>`;
        const family = brandIcons.includes(c) ? "Font Awesome 7 Brands" : "Font Awesome 7 Free";
        const weight = brandIcons.includes(c) || regularIcons.includes(c) ? 400 : 900;
        return `<span style="font-family:'${family}'; font-weight:${weight}">${c}</span>`;
    }

    function bytes(n, suffix, minUnit) {
        const units = ["", "k", "M", "G", "T"];
        let i = 0;
        while ((n >= 999.5 || i < (minUnit || 0)) && i < units.length - 1) {
            n /= 1000;
            i++;
        }
        return Math.round(n) + units[i] + (suffix || "B");
    }

    function kib(kb) {
        return kb >= 1024 * 1024 ? (kb / 1024 / 1024).toFixed(1) + " GB" : Math.round(kb / 1024) + " MB";
    }

    function heat(t) {
        return t >= 80 ? red : t >= 65 ? yellow : t >= 50 ? text : green;
    }
}
