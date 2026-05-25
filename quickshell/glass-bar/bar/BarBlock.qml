import QtQuick
import QtQuick.Layouts
import ".." as Root

Rectangle {
    id: root

    signal clicked()
    signal scrolled(real steps)

    property Item content
    property bool active: false
    property int horizontalPadding: 12
    property int minimumWidth: 34

    Layout.preferredWidth: Math.max(minimumWidth, contentContainer.implicitWidth + horizontalPadding * 2)
    Layout.preferredHeight: 30
    radius: Root.Theme.radius
    color: active ? Root.Theme.primary : (hover.hovered ? Root.Theme.blockHover : Root.Theme.blockBackground)
    border.width: 1
    border.color: active ? Root.Theme.primary : Root.Theme.border

    Behavior on color { ColorAnimation { duration: 140 } }
    Behavior on border.color { ColorAnimation { duration: 140 } }

    Item {
        id: contentContainer
        implicitWidth: content ? content.implicitWidth : 0
        implicitHeight: content ? content.implicitHeight : 0
        anchors.centerIn: parent
        children: content
    }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { acceptedButtons: Qt.LeftButton; onTapped: root.clicked() }
    WheelHandler { onWheel: event => root.scrolled(event.angleDelta.y / 120) }
}
