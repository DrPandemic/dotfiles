import QtQuick
import Quickshell.Io

Process {
    id: poll

    property int interval: 10000
    signal output(string text)

    function refresh() {
        running = true;
    }

    stdout: StdioCollector {
        onStreamFinished: poll.output(text)
    }

    property Timer timer: Timer {
        interval: poll.interval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: poll.running = true
    }
}
