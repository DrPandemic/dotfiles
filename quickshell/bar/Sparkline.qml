import QtQuick

// Small filled line chart over a fixed 0..maxValue range (eg. CPU percent).
Item {
    id: spark

    property var values: []
    property real maxValue: 100
    property color lineColor: Theme.accentLight
    property color fillColor: Qt.rgba(lineColor.r, lineColor.g, lineColor.b, 0.18)

    implicitHeight: 36

    Canvas {
        id: canvas

        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        Connections {
            target: spark

            function onValuesChanged() {
                canvas.requestPaint();
            }
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.fillStyle = Theme.track;
            ctx.fillRect(0, 0, width, height);

            const v = spark.values;
            if (v.length < 2)
                return;

            const peak = Math.max(spark.maxValue, ...v);
            const step = width / 59;
            const x0 = width - (v.length - 1) * step;
            const y = val => height - 2 - (height - 4) * Math.min(1, val / peak);

            ctx.beginPath();
            ctx.moveTo(x0, height);
            v.forEach((val, i) => ctx.lineTo(x0 + i * step, y(val)));
            ctx.lineTo(x0 + (v.length - 1) * step, height);
            ctx.closePath();
            ctx.fillStyle = spark.fillColor;
            ctx.fill();

            ctx.beginPath();
            v.forEach((val, i) => i === 0 ? ctx.moveTo(x0, y(val)) : ctx.lineTo(x0 + i * step, y(val)));
            ctx.strokeStyle = spark.lineColor;
            ctx.lineWidth = 1.5;
            ctx.stroke();
        }
    }
}
