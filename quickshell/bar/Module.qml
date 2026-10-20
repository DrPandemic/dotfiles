import QtQuick

Item {
    id: mod

    property string text
    property color color: Theme.fg
    property bool italic: false
    property string tooltip
    property Component popup: tooltip ? tooltipComponent : null
    property int popupDelay: 250
    property bool dismissOnClick: true
    property bool popupOnClick: false
    property string widthSample
    readonly property alias hovered: hover.hovered

    signal clicked
    signal rightClicked
    signal middleClicked
    signal scrolled(int delta)

    visible: text !== ""
    implicitWidth: visible ? Math.max(label.implicitWidth, sample.implicitWidth) + 12 : 0
    implicitHeight: Theme.barHeight

    Text {
        id: label
        x: mod.widthSample ? 6 : (parent.width - width) / 2
        anchors.verticalCenter: parent.verticalCenter
        text: Theme.pango(mod.text)
        textFormat: Text.RichText
        color: mod.color
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        font.italic: mod.italic
    }

    Text {
        id: sample
        visible: false
        text: mod.widthSample ? Theme.pango(mod.widthSample) : ""
        textFormat: Text.RichText
        font: label.font
    }

    HoverHandler {
        id: hover
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton && mod.popupOnClick)
                hoverPopup.toggle();
            else if (mod.dismissOnClick)
                hoverPopup.dismiss();
            if (mouse.button === Qt.RightButton)
                mod.rightClicked();
            else if (mouse.button === Qt.MiddleButton)
                mod.middleClicked();
            else
                mod.clicked();
        }
        onWheel: wheel => mod.scrolled(wheel.angleDelta.y)
    }

    HoverPopup {
        id: hoverPopup
        target: mod
        targetHovered: mod.popupOnClick ? false : hover.hovered
        content: mod.popup
        openDelay: mod.popupDelay
    }

    Component {
        id: tooltipComponent

        TooltipText {
            text: Theme.pango(mod.tooltip)
        }
    }
}
