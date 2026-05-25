import QtQuick
import Quickshell.Io
import ".." as Bar

Bar.BarBlock {
    id: root

    property bool hasBattery: false
    property int capacity: 0
    property string status: "Unknown"

    visible: hasBattery
    active: status === "Charging"

    function icon() {
        if (status === "Charging") return ""
        if (capacity <= 15) return ""
        if (capacity <= 35) return ""
        if (capacity <= 60) return ""
        if (capacity <= 85) return ""
        return ""
    }

    content: Bar.BarText {
        active: root.active
        pointSize: 10
        symbolText: root.icon() + " " + root.capacity + "%"
    }

    Process {
        id: batteryProc
        command: ["bash", "-lc", "set -- /sys/class/power_supply/BAT*; [ -d \"$1\" ] || exit 1; printf '%s,%s' \"$(cat \"$1/capacity\")\" \"$(cat \"$1/status\")\""]
        running: true
        onExited: code => root.hasBattery = code === 0
        stdout: SplitParser {
            onRead: data => {
                const parts = String(data || "0,Unknown").trim().split(",")
                root.capacity = Number(parts[0] || 0)
                root.status = parts[1] || "Unknown"
            }
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: true
        onTriggered: batteryProc.running = true
    }
}
