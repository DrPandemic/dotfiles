import QtQuick
import Quickshell

Scope {
    id: root

    required property Item target
    property bool targetHovered: false
    property Component content
    property int openDelay: 250
    property int closeDelay: 200
    property bool suppressed: false
    property bool open: false

    readonly property bool hovered: targetHovered || (loader.item?.frameHovered ?? false)

    function dismiss() {
        suppressed = true;
        open = false;
    }

    function toggle() {
        suppressed = false;
        open = !open;
    }

    onHoveredChanged: {
        if (hovered) {
            closeTimer.stop();
            if (!open && !suppressed && content)
                openTimer.restart();
        } else {
            openTimer.stop();
            suppressed = false;
            closeTimer.restart();
        }
    }

    Timer {
        id: openTimer
        interval: root.openDelay
        onTriggered: root.open = true
    }

    Timer {
        id: closeTimer
        interval: root.closeDelay
        onTriggered: root.open = false
    }

    LazyLoader {
        id: loader
        active: root.open

        PopupWindow {
            readonly property bool frameHovered: frameHover.hovered

            anchor.item: root.target
            anchor.rect.x: 0
            anchor.rect.y: -6
            anchor.rect.width: root.target.width
            anchor.rect.height: root.target.height
            anchor.edges: Edges.Top
            anchor.gravity: Edges.Top
            anchor.adjustment: PopupAdjustment.SlideX | PopupAdjustment.FlipY

            visible: true
            implicitWidth: frame.implicitWidth
            implicitHeight: frame.implicitHeight
            color: "transparent"

            Rectangle {
                id: frame

                anchors.fill: parent
                implicitWidth: content.implicitWidth + 24
                implicitHeight: content.implicitHeight + 20
                radius: 8
                color: Theme.popupBg
                border.color: Theme.border
                border.width: 1

                HoverHandler {
                    id: frameHover
                }

                Loader {
                    id: content
                    x: 12
                    y: 10
                    sourceComponent: root.content
                }
            }
        }
    }
}
