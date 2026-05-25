import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "blocks" as Blocks
import ".." as Root

Scope {
    id: root

    property var barInstances: []

    IpcHandler {
        target: "glassbar"

        function toggle(): void {
            for (let i = 0; i < root.barInstances.length; i++) {
                root.barInstances[i].visible = !root.barInstances[i].visible
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: bar
            property var modelData

            screen: modelData
            color: "transparent"
            implicitHeight: Root.Theme.barHeight
            visible: true

            anchors {
                top: !Root.Theme.bottomBar
                bottom: Root.Theme.bottomBar
                left: true
                right: true
            }

            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "glass-bar"
            WlrLayershell.exclusiveZone: Root.Theme.barHeight

            Component.onCompleted: root.barInstances.push(bar)

            Rectangle {
                anchors.fill: parent
                color: Root.Theme.barBackground
                border.width: 1
                border.color: Root.Theme.border
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                RowLayout {
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    Layout.fillWidth: true
                    spacing: 8

                    Blocks.Workspaces {}
                }

                Blocks.ActiveTitle {
                    Layout.alignment: Qt.AlignCenter
                    Layout.preferredWidth: Math.max(220, bar.width * 0.28)
                    Layout.maximumWidth: Math.max(220, bar.width * 0.38)
                }

                RowLayout {
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    Layout.fillWidth: true
                    layoutDirection: Qt.LeftToRight
                    spacing: 8

                    Item { Layout.fillWidth: true }
                    Blocks.SystemTray {}
                    Blocks.Memory {}
                    Blocks.Sound {}
                    Blocks.Battery {}
                    Blocks.NotificationButton {}
                    Blocks.Clock {}
                }
            }
        }
    }
}
