import QtQuick
import Quickshell.Io

Process {
    id: stream

    property int restartInterval: 5000
    signal line(string data)

    running: true
    stdout: SplitParser {
        onRead: data => stream.line(data)
    }
    onExited: restart.start()

    property Timer restart: Timer {
        id: restart
        interval: stream.restartInterval
        onTriggered: stream.running = true
    }
}
