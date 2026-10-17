import QtQuick

Item {
    id: title

    property string text
    property string detail

    implicitWidth: heading.implicitWidth + side.implicitWidth + 24
    implicitHeight: heading.implicitHeight + 6

    Text {
        id: heading
        width: Math.min(implicitWidth, title.width - side.implicitWidth - 12)
        elide: Text.ElideRight
        text: title.text
        color: Theme.text
        font.family: Theme.font
        font.pixelSize: 16
        font.bold: true
    }

    Text {
        id: side
        anchors.right: parent.right
        anchors.baseline: heading.baseline
        text: title.detail
        color: Theme.dim
        font.family: Theme.font
        font.pixelSize: 13
    }
}
