import QtQuick
import Quickshell.Io
import ".." as Bar

Bar.BarBlock {
    id: root

    property int usage: 0

    content: Bar.BarText {
        pointSize: 10
        symbolText: " " + root.usage + "%"
    }

    Process {
        id: memProc
        command: ["bash", "-lc", "free | awk '/Mem:/ {printf \"%d\", ($3 / $2) * 100}'"]
        running: true
        stdout: SplitParser { onRead: data => root.usage = Number(String(data || "0").trim()) }
    }

    Timer {
        interval: 3000
        repeat: true
        running: true
        onTriggered: memProc.running = true
    }
}
