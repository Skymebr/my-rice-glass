import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import Quickshell.Io
import ".." as Bar

Bar.BarBlock {
    id: root

    property string title: "Desktop"

    horizontalPadding: 14

    minimumWidth: 180


    content: Bar.BarText {
        pointSize: 10
        symbolText: root.title.length > 0 ? root.title : "Desktop"
        elide: Text.ElideRight
        width: Math.min(implicitWidth, root.width - 28)
    }

    Process {
        id: titleProc
        command: ["bash", "-lc", "hyprctl activewindow 2>/dev/null | sed -n 's/^[[:space:]]*title: //p' | head -n 1"]
        running: true
        stdout: SplitParser { onRead: data => root.title = String(data || "").trim() }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) { titleProc.running = true }
    }
}
