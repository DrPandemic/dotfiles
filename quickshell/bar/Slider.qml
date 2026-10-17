import QtQuick

Item {
    id: slider

    property real value: 0
    property color barColor: Theme.accentLight
    signal moved(real value)

    implicitWidth: 200
    implicitHeight: 20

    function set(x) {
        slider.moved(Math.max(0, Math.min(1, x / width)));
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Theme.track

        Rectangle {
            width: parent.width * Math.min(1, slider.value)
            height: parent.height
            radius: 3
            color: slider.barColor
        }
    }

    Rectangle {
        x: slider.width * Math.min(1, slider.value) - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: 14
        height: 14
        radius: 7
        color: area.pressed || area.containsMouse ? Theme.text : Theme.subtext
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        onPressed: mouse => slider.set(mouse.x)
        onPositionChanged: mouse => {
            if (pressed)
                slider.set(mouse.x);
        }
        onWheel: wheel => slider.moved(Math.max(0, Math.min(1, slider.value + (wheel.angleDelta.y > 0 ? 0.01 : -0.01))))
    }
}
