import QtQuick

Item {
    id: cal

    required property date now
    property date month: new Date(now.getFullYear(), now.getMonth(), 1)
    property bool yearView: false
    readonly property color dayColor: "#ecc6d9"
    readonly property color otherColor: "#5c6474"
    readonly property int cellW: 42
    readonly property int cellH: 47
    readonly property bool onToday: !yearView && month.getFullYear() === now.getFullYear() && month.getMonth() === now.getMonth()

    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
    }

    function isoWeek(d) {
        const t = new Date(d.getFullYear(), d.getMonth(), d.getDate() + 3 - (d.getDay() + 6) % 7);
        const jan4 = new Date(t.getFullYear(), 0, 4);
        return 1 + Math.round(((t - jan4) / 86400000 - 3 + (jan4.getDay() + 6) % 7) / 7);
    }

    function dayOfYear(d) {
        return Math.round((new Date(d.getFullYear(), d.getMonth(), d.getDate()) - new Date(d.getFullYear(), 0, 1)) / 86400000) + 1;
    }

    // Six Monday-first weeks, so the grid height never jumps between months.
    function weeks(first) {
        const start = new Date(first.getFullYear(), first.getMonth(), 1 - (first.getDay() + 6) % 7);
        const out = [];
        for (let w = 0; w < 6; w++) {
            const days = [];
            for (let i = 0; i < 7; i++) days.push(new Date(start.getFullYear(), start.getMonth(), start.getDate() + w * 7 + i))
            out.push(days);
        }
        return out;
    }

    function shift(n) {
        month = yearView ? new Date(month.getFullYear() + n, month.getMonth(), 1) : new Date(month.getFullYear(), month.getMonth() + n, 1);
    }

    function goToday() {
        month = new Date(now.getFullYear(), now.getMonth(), 1);
        yearView = false;
    }

    implicitWidth: cellW * 8
    implicitHeight: body.implicitHeight

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: cal.yearView = !cal.yearView
        onWheel: wheel => cal.shift(wheel.angleDelta.y > 0 ? -1 : 1)
    }

    Column {
        id: body

        width: parent.width
        spacing: 10

        Item {
            width: parent.width
            height: clockText.implicitHeight

            Text {
                id: clockText

                text: Qt.formatDateTime(cal.now, "HH:mm")
                color: Theme.text
                font.family: Theme.font
                font.pixelSize: 44
                font.weight: Font.Light
            }

            Column {
                anchors.left: clockText.right
                anchors.leftMargin: 14
                anchors.verticalCenter: clockText.verticalCenter
                spacing: 2

                Text {
                    text: Qt.formatDate(cal.now, "dddd")
                    color: Theme.pink
                    font.family: Theme.font
                    font.pixelSize: 15
                    font.bold: true
                }

                Text {
                    text: Qt.formatDate(cal.now, "MMMM d, yyyy")
                    color: Theme.text
                    font.family: Theme.font
                    font.pixelSize: 14
                }
            }

            Column {
                anchors.right: parent.right
                anchors.verticalCenter: clockText.verticalCenter
                spacing: 2

                Text {
                    anchors.right: parent.right
                    text: "Week " + cal.isoWeek(cal.now)
                    color: Theme.teal
                    font.family: Theme.font
                    font.pixelSize: 13
                }

                Text {
                    anchors.right: parent.right
                    text: "Day " + cal.dayOfYear(cal.now)
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 13
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.border
        }

        Item {
            width: parent.width
            height: 28

            NavButton {
                label: "‹"
                onClicked: cal.shift(-1)
            }

            Rectangle {
                anchors.centerIn: parent
                width: heading.implicitWidth + 20
                height: 28
                radius: 6
                color: headingMouse.containsMouse ? Theme.hover : "transparent"

                Text {
                    id: heading

                    anchors.centerIn: parent
                    text: cal.yearView ? cal.month.getFullYear() : Qt.formatDate(cal.month, "MMMM yyyy")
                    color: Theme.cream
                    font.family: Theme.font
                    font.pixelSize: 15
                    font.bold: true
                }

                MouseArea {
                    id: headingMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: cal.yearView = !cal.yearView
                }
            }

            Row {
                anchors.right: parent.right
                spacing: 2

                NavButton {
                    visible: !cal.onToday
                    label: "Today"
                    onClicked: cal.goToday()
                }

                NavButton {
                    label: "›"
                    onClicked: cal.shift(1)
                }
            }
        }

        Item {
            width: parent.width
            height: 24 + 6 * cal.cellH

            Column {
                visible: !cal.yearView

                Row {
                    Repeater {
                        model: ["Wk", "Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

                        Text {
                            required property string modelData
                            required property int index

                            width: cal.cellW
                            height: 24
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: modelData
                            color: index === 0 ? Theme.teal : index >= 6 ? Qt.darker(Theme.yellow, 1.25) : Theme.yellow
                            font.family: Theme.font
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                }

                Repeater {
                    model: cal.weeks(cal.month)

                    Row {
                        id: week

                        required property var modelData
                        readonly property bool current: modelData.some(d => cal.sameDay(d, cal.now))

                        Text {
                            width: cal.cellW
                            height: cal.cellH
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: cal.isoWeek(week.modelData[0])
                            color: Theme.teal
                            opacity: week.current ? 1 : 0.55
                            font.family: Theme.font
                            font.pixelSize: 12
                        }

                        Repeater {
                            model: week.modelData

                            Item {
                                id: day

                                required property date modelData
                                required property int index
                                readonly property bool today: cal.sameDay(modelData, cal.now)
                                readonly property bool inMonth: modelData.getMonth() === cal.month.getMonth()

                                width: cal.cellW
                                height: cal.cellH

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 30
                                    height: 30
                                    radius: 15
                                    color: day.today ? Theme.pink : dayMouse.containsMouse ? Theme.hover : "transparent"
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: day.modelData.getDate()
                                    color: day.today ? "#2b303b" : !day.inMonth ? cal.otherColor : day.index >= 5 ? Qt.darker(cal.dayColor, 1.2) : cal.dayColor
                                    font.family: Theme.font
                                    font.pixelSize: 14
                                    font.bold: day.today || day.inMonth
                                }

                                MouseArea {
                                    id: dayMouse

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        if (!day.inMonth)
                                            cal.month = new Date(day.modelData.getFullYear(), day.modelData.getMonth(), 1);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Loader {
                active: cal.yearView

                sourceComponent: Grid {
                    columns: 3
                    columnSpacing: 12
                    rowSpacing: 4

                    Repeater {
                        model: 12

                        Rectangle {
                            id: mini

                            required property int index
                            readonly property date first: new Date(cal.month.getFullYear(), index, 1)
                            readonly property bool current: cal.now.getFullYear() === first.getFullYear() && cal.now.getMonth() === index

                            width: (cal.width - 24) / 3
                            height: miniCol.implicitHeight + 6
                            radius: 6
                            color: miniMouse.containsMouse ? Theme.hover : "transparent"
                            border.width: current ? 1 : 0
                            border.color: Theme.pink

                            Column {
                                id: miniCol

                                x: 4
                                y: 3

                                Text {
                                    width: mini.width - 8
                                    horizontalAlignment: Text.AlignHCenter
                                    text: Qt.formatDate(mini.first, "MMMM")
                                    color: Theme.cream
                                    font.family: Theme.font
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                Grid {
                                    columns: 7

                                    Repeater {
                                        model: cal.weeks(mini.first).reduce((all, w) => all.concat(w), [])

                                        Text {
                                            required property date modelData
                                            readonly property bool inMonth: modelData.getMonth() === mini.index

                                            width: (mini.width - 8) / 7
                                            height: 9
                                            horizontalAlignment: Text.AlignHCenter
                                            text: inMonth ? modelData.getDate() : ""
                                            color: cal.sameDay(modelData, cal.now) ? Theme.pink : cal.dayColor
                                            font.family: Theme.font
                                            font.pixelSize: 9
                                            font.bold: cal.sameDay(modelData, cal.now)
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: miniMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    cal.month = mini.first;
                                    cal.yearView = false;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component NavButton: Rectangle {
        id: btn

        property string label

        signal clicked()

        width: Math.max(28, btnText.implicitWidth + 16)
        height: 28
        radius: 6
        color: btnMouse.containsMouse ? Theme.hover : "transparent"

        Text {
            id: btnText

            anchors.centerIn: parent
            text: btn.label
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: 15
        }

        MouseArea {
            id: btnMouse

            anchors.fill: parent
            hoverEnabled: true
            onClicked: btn.clicked()
        }
    }
}
