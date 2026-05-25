import QtQuick
import Quickshell
import ".." as Bar

Bar.BarBlock {
    id: root

    property date now: new Date()

    onClicked: Quickshell.execDetached(["bash", "-lc", "pgrep -x gsimplecal >/dev/null && pkill -x gsimplecal || gsimplecal"])

    content: Bar.BarText {
        pointSize: 10
        symbolText: Qt.formatDateTime(root.now, "HH:mm")
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }
}
