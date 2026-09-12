import QtQuick
import ".."

// Idle dot-field — slow gruvbox breathing grid, port of the dots.js reference.
//   hypridle (Stage 1) → nuit-idle-animation on → qs ipc setIdle → SysState.idleDim.
// Dots ONLY (no orb cursor, no mid-box, no header) + small clock text on top.
// Follow math mirrors dots.js: smoothstep falloff, per-dot ease variance,
// twinkle + rare white spark at 0.4x speed. No shadowBlur (too costly in QML
// Canvas) — heat reads via radius + color. ~15fps Timer, everything gated on
// root.visible → 0 CPU when hidden. Click or hover-move wakes via SysState.
Rectangle {
    id: root
    color: "#1D2021"    // gruvbox hard bg

    opacity: 0
    Component.onCompleted: opacity = 1
    Behavior on opacity { NumberAnimation { duration: 1500; easing.type: Easing.OutCubic } }

    Canvas {
        id: field
        anchors.fill: parent

        property var dots: []
        property real mx: -9999
        property real my: -9999
        property real tSec: 0

        // dots.js: SPACING 16 → 26 (perf), RADIUS 190 → 180, PULL 34 → 28, EASE 0.12 → 0.05 (slower)
        readonly property int spacing: 26
        readonly property real radius: 180
        readonly property real pull: 28
        readonly property real baseR: 1.5
        readonly property real hotR: 6.0

        // heat 0 → cream, rising heat → deep gruvbox blue #458588 → pale #83a598
        function heatColor(heat) {
            var a = [235, 219, 178], b = [69, 133, 136], t = heat * 2;
            if (heat > 0.5) { a = [69, 133, 136]; b = [131, 165, 152]; t = (heat - 0.5) * 2; }
            return [Math.round(a[0] + (b[0] - a[0]) * t),
                    Math.round(a[1] + (b[1] - a[1]) * t),
                    Math.round(a[2] + (b[2] - a[2]) * t)];
        }

        function build() {
            if (width <= 0 || height <= 0) return;
            var arr = [], m = 6;
            var ox = m + ((width - 2 * m) % spacing) / 2, oy = m + ((height - 2 * m) % spacing) / 2;
            for (var y = oy; y <= height - m; y += spacing)
                for (var x = ox; x <= width - m; x += spacing) {
                    var seed = Math.random();
                    arr.push({ hx: x, hy: y, x: x, y: y, ease: 0.05 * (0.7 + seed * 0.6), tw: 0.5 + seed });
                }
            dots = arr;
        }

        onWidthChanged: build()
        onHeightChanged: build()
        Component.onCompleted: build()

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            for (var i = 0; i < dots.length; i++) {
                var d = dots[i];
                var dx = mx - d.hx, dy = my - d.hy;
                var dist = Math.hypot(dx, dy);

                // rare sharp white flash; stars ignore the cursor (freq *0.4 — slower)
                var spark = Math.pow(Math.max(0, Math.sin(tSec * (0.5 + d.tw * 0.8) * 0.4 + d.tw * 39.0)), 40);
                var star = spark > 0.5;

                var tx = d.hx, ty = d.hy, heat = 0;
                if (!star && dist < radius && dist > 0.001) {
                    var f = 1 - dist / radius;
                    var eased = f * f * (3 - 2 * f);     // smoothstep falloff
                    heat = eased;
                    tx = d.hx + (dx / dist) * pull * eased;
                    ty = d.hy + (dy / dist) * pull * eased;
                }
                var rr = baseR + (hotR - baseR) * heat + spark * 1.4;
                tx = Math.min(Math.max(tx, rr), width - rr);
                ty = Math.min(Math.max(ty, rr), height - rr);
                d.x += (tx - d.x) * d.ease;
                d.y += (ty - d.y) * d.ease;

                // slow breathing twinkle (freq *0.4) so the field lives while still
                var tw = 0.45 + 0.15 * Math.sin(tSec * 1.4 * 0.4 + d.tw * 6.2832);
                var c = heatColor(heat), w = spark * (1 - heat);
                var cr = Math.round(c[0] + (255 - c[0]) * w);
                var cg = Math.round(c[1] + (255 - c[1]) * w);
                var cb = Math.round(c[2] + (255 - c[2]) * w);

                ctx.beginPath();
                ctx.arc(d.x, d.y, rr, 0, 6.2832);
                ctx.fillStyle = "rgba(" + cr + "," + cg + "," + cb + "," + (tw + heat * 0.45 + spark * 0.4).toFixed(3) + ")";
                ctx.fill();
            }
        }
    }

    // slow frame driver (~15fps) + breath clock; paused when hidden
    Timer {
        interval: 66; running: root.visible; repeat: true
        onTriggered: { field.tSec += 0.066; field.requestPaint(); }
    }

    Column {
        anchors.centerIn: parent
        spacing: 10
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "☾"
            color: Theme.accent
            font { family: Theme.fontFamily; pixelSize: 64 }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: {
                SysState.clock.seconds        // per-second refresh dependency
                return Qt.formatTime(new Date(), "h:mm AP")
            }
            color: Theme.fgBright             // gruvbox bright cream #FBF1C7
            font { family: "Liberation Serif"; pixelSize: 84; bold: true; letterSpacing: 2 }
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 120; height: 4; radius: 2
            color: Theme.accent
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "N U I T — I D L E"
            color: Theme.accent
            font { family: Theme.fontFamily; pixelSize: 14; letterSpacing: 5 }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "idle — click or move to wake"
            color: Theme.dimText
            font { family: Theme.fontFamily; pixelSize: 12 }
        }
    }

    // fullscreen wake: hover tracks the cursor for the field, any click wakes
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: mouse => { field.mx = mouse.x; field.my = mouse.y; }
        onClicked: SysState.setIdle(false)
    }
}
