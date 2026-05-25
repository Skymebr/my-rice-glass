import QtQuick
import Quickshell
import ".." as Bar

Bar.BarBlock {
    onClicked: Quickshell.execDetached(["swaync-client", "-t", "-sw"])

    content: Bar.BarText {
        pointSize: 10
        symbolText: ""
    }
}
