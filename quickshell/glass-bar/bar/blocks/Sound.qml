import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import ".." as Bar
import "../.." as Root

Bar.BarBlock {
    id: root

    property var sink: Pipewire.defaultAudioSink
    active: Boolean(sink && sink.audio && sink.audio.muted)

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
        onObjectsChanged: root.sink = Pipewire.defaultAudioSink
    }

    function volume() {
        return sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0
    }

    function icon() {
        if (!sink || !sink.audio) return "󰕿"
        if (sink.audio.muted) return "󰖁"
        if (sink.audio.volume <= 0.35) return ""
        if (sink.audio.volume <= 0.70) return ""
        return ""
    }

    onClicked: menu.visible = !menu.visible
    onScrolled: steps => {
        if (sink && sink.audio) {
            sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + steps * 0.05))
        }
    }

    content: Bar.BarText {
        active: root.active
        pointSize: 10
        symbolText: root.icon() + " " + root.volume() + "%"
    }

    PopupWindow {
        id: menu
        implicitWidth: 230
        implicitHeight: 116
        visible: false

        anchor.window: root.QsWindow ? root.QsWindow.window : null
        anchor.edges: Root.Theme.bottomBar ? Edges.Top : Edges.Bottom
        anchor.gravity: Root.Theme.bottomBar ? Edges.Bottom : Edges.Top

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: Root.Theme.surface
            border.width: 1
            border.color: Root.Theme.border

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Slider {
                    id: slider
                    Layout.fillWidth: true
                    from: 0
                    to: 1
                    value: root.sink && root.sink.audio ? root.sink.audio.volume : 0
                    onMoved: if (root.sink && root.sink.audio) root.sink.audio.volume = value
                }

                RowLayout {
                    Layout.fillWidth: true

                    Button {
                        Layout.fillWidth: true
                        text: root.sink && root.sink.audio && root.sink.audio.muted ? "Ativar som" : "Mutar"
                        onClicked: if (root.sink && root.sink.audio) root.sink.audio.muted = !root.sink.audio.muted
                    }

                    Button {
                        Layout.fillWidth: true
                        text: "Mixer"
                        onClicked: {
                            Quickshell.execDetached(["pavucontrol"])
                            menu.visible = false
                        }
                    }
                }
            }
        }
    }
}
