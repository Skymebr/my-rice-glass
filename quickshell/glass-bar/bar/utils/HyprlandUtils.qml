pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    property var workspaces: []
    property int activeWorkspace: 1

    function refresh() {
        workspaces = [...Hyprland.workspaces.values].map(ws => ws.id).sort((a, b) => a - b)

        if (Hyprland.focusedMonitor && Hyprland.focusedMonitor.activeWorkspace) {
            activeWorkspace = Hyprland.focusedMonitor.activeWorkspace.id
        }
    }

    function workspaceExists(id) {
        return workspaces.indexOf(id) !== -1
    }

    function switchWorkspace(id) {
        Hyprland.dispatch("workspace " + id)
    }

    Component.onCompleted: refresh()

    Connections {
        target: Hyprland
        function onRawEvent(event) { root.refresh() }
    }
}
