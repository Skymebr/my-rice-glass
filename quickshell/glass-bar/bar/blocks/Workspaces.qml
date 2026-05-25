import QtQuick
import QtQuick.Layouts
import ".." as Bar
import "../utils" as Utils
import "../.." as Root

RowLayout {
    id: root
    spacing: 5

    Repeater {
        model: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

        Bar.BarBlock {
            id: workspaceButton
            required property int modelData

            active: Utils.HyprlandUtils.activeWorkspace === modelData
            minimumWidth: modelData === 10 ? 42 : 34
            horizontalPadding: 8
            opacity: Utils.HyprlandUtils.workspaceExists(modelData) || active ? 1.0 : 0.55
            onClicked: Utils.HyprlandUtils.switchWorkspace(modelData)

            content: Bar.BarText {
                active: workspaceButton.active
                pointSize: 10
                symbolText: workspaceButton.modelData.toString()
            }
        }
    }
}
