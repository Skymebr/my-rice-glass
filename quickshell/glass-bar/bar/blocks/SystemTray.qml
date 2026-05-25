import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../.." as Root

RowLayout {
    spacing: 6

    Repeater {
        model: ScriptModel { values: [...SystemTray.items.values] }

        MouseArea {
            id: delegate
            required property SystemTrayItem modelData
            property alias item: delegate.modelData

            Layout.preferredWidth: 24
            Layout.preferredHeight: 30
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            hoverEnabled: true

            onClicked: event => {
                if (event.button === Qt.LeftButton) item.activate()
                else if (event.button === Qt.MiddleButton) item.secondaryActivate()
                else if (event.button === Qt.RightButton) menuAnchor.open()
            }

            onWheel: event => {
                event.accepted = true
                item.scroll(event.angleDelta.y / 120, false)
            }

            Rectangle {
                anchors.fill: parent
                radius: 12
                color: delegate.containsMouse ? Root.Theme.blockHover : "transparent"
            }

            IconImage {
                anchors.centerIn: parent
                source: item.icon
                implicitSize: 18
            }

            QsMenuAnchor {
                id: menuAnchor
                menu: item.menu
                anchor.window: delegate.QsWindow ? delegate.QsWindow.window : null
                anchor.adjustment: PopupAdjustment.Flip
                anchor.onAnchoring: {
                    const window = delegate.QsWindow.window
                    anchor.rect = window.contentItem.mapFromItem(delegate, 0, delegate.height, delegate.width, delegate.height)
                }
            }
        }
    }
}
