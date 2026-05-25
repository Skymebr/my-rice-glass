//@ pragma IconTheme Papirus-Dark

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Widgets

ShellRoot {
    id: root

    property var workspaceIds: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

    property color primary: "#a7cfc4"
    property color primaryText: "#0f362f"
    property color secondary: "#bacac5"
    property color background: "#121413"
    property color backgroundText: "#e2e3e1"
    property color surface: "#121413"
    property color surfaceText: "#e2e3e1"
    property color surfaceVariant: "#414846"
    property color outline: "#8b928f"
    property color error: "#ffb4ab"

    property int focusedWorkspaceId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : -1

    function colorWithAlpha(colorValue, opacity) {
        var c = String(colorValue)
        if ((c.length !== 7 && c.length !== 9) || c[0] !== "#")
            return colorValue

        var offset = c.length === 9 ? 3 : 1

        return Qt.rgba(
            parseInt(c.slice(offset, offset + 2), 16) / 255,
            parseInt(c.slice(offset + 2, offset + 4), 16) / 255,
            parseInt(c.slice(offset + 4, offset + 6), 16) / 255,
            opacity
        )
    }

    function applyColors() {
        var text = colorFile.text().trim()
        if (!text)
            return

        try {
            var d = JSON.parse(text)
            root.primary = d.primary || root.primary
            root.primaryText = d.primaryText || d.onPrimary || root.primaryText
            root.secondary = d.secondary || root.secondary
            root.background = d.background || root.background
            root.backgroundText = d.backgroundText || root.backgroundText
            root.surface = d.surfaceContainer || d.surface || root.surface
            root.surfaceText = d.surfaceText || root.surfaceText
            root.surfaceVariant = d.surfaceVariant || root.surfaceVariant
            root.outline = d.outline || root.outline
            root.error = d.error || root.error
        } catch (e) {
            console.log("Could not parse skwd-wall colors:", e)
        }
    }

    function audio() {
        if (!Pipewire.defaultAudioSink || !Pipewire.defaultAudioSink.audio)
            return null
        return Pipewire.defaultAudioSink.audio
    }

    function volumeIcon() {
        var nodeAudio = root.audio()
        if (!nodeAudio || nodeAudio.muted)
            return ""

        var percent = Math.round(nodeAudio.volume * 100)
        if (percent < 35)
            return ""
        if (percent < 70)
            return ""
        return ""
    }

    function volumeText() {
        var nodeAudio = root.audio()
        if (!nodeAudio)
            return " --"
        if (nodeAudio.muted)
            return " Mute"
        return root.volumeIcon() + " " + Math.round(nodeAudio.volume * 100) + "%"
    }

    function batteryIcon() {
        if (!UPower.onBattery)
            return ""

        var percent = UPower.displayDevice ? UPower.displayDevice.percentage : 0
        if (percent <= 15)
            return ""
        if (percent <= 30)
            return ""
        if (percent <= 55)
            return ""
        if (percent <= 80)
            return ""
        return ""
    }

    function batteryText() {
        if (!UPower.displayDevice || !UPower.displayDevice.ready)
            return ""
        return root.batteryIcon() + " " + Math.round(UPower.displayDevice.percentage) + "%"
    }

    FileView {
        id: colorFile
        path: Quickshell.env("HOME") + "/.cache/skwd-wall/colors.json"
        blockLoading: true
        watchChanges: true
        onLoaded: root.applyColors()
        onFileChanged: reload()
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    PwObjectTracker {
        objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
    }

    component ModulePill: Rectangle {
        id: modulePill

        property string text: ""
        property color pillColor: "transparent"
        property color textColor: "white"
        property color strokeColor: "transparent"
        property string family: "JetBrainsMono Nerd Font"
        property int textSize: 17
        property int horizontalPadding: 14

        implicitWidth: label.implicitWidth + horizontalPadding * 2
        implicitHeight: 28
        radius: 15
        color: pillColor
        border.color: strokeColor
        border.width: 1

        Text {
            id: label
            anchors.centerIn: parent
            text: modulePill.text
            color: modulePill.textColor
            font.family: modulePill.family
            font.pixelSize: modulePill.textSize
            font.bold: true
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel

            property var modelData

            screen: modelData

            anchors.top: true
            anchors.left: true
            anchors.right: true
            implicitHeight: 40
            exclusiveZone: 40
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                color: root.colorWithAlpha(root.background, 0.5)
            }

            RowLayout {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5

                Rectangle {
                    implicitWidth: workspaceRow.implicitWidth + 20
                    implicitHeight: 28
                    radius: 15
                    color: root.surface
                    border.color: root.secondary
                    border.width: 1

                    RowLayout {
                        id: workspaceRow
                        anchors.centerIn: parent
                        spacing: 2

                        Repeater {
                            model: root.workspaceIds

                            Rectangle {
                                property int workspaceId: modelData
                                property bool selected: root.focusedWorkspaceId === workspaceId

                                implicitWidth: workspaceLabel.implicitWidth + 12
                                implicitHeight: 20
                                radius: 10
                                color: selected ? root.primary : "transparent"

                                Text {
                                    id: workspaceLabel
                                    anchors.centerIn: parent
                                    text: String(parent.workspaceId)
                                    color: parent.selected ? root.background : root.secondary
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 17
                                    font.bold: true
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Hyprland.dispatch("workspace " + parent.workspaceId)
                                }
                            }
                        }
                    }
                }
            }

            ModulePill {
                anchors.centerIn: parent
                text: Qt.formatDateTime(clock.date, "hh:mm")
                pillColor: root.primary
                textColor: root.primaryText
                strokeColor: root.primary
                family: "Inter Display"
                textSize: 15
                horizontalPadding: 20

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton)
                            Quickshell.execDetached(["swaync-client", "-d", "-sw"])
                        else
                            Quickshell.execDetached(["gsimplecal"])
                    }
                }
            }

            RowLayout {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                ModulePill {
                    text: root.volumeText()
                    pillColor: root.surface
                    textColor: root.primary
                    strokeColor: root.secondary

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.RightButton && root.audio())
                                root.audio().muted = !root.audio().muted
                            else
                                Quickshell.execDetached(["pavucontrol"])
                        }
                    }
                }

                ModulePill {
                    visible: root.batteryText() !== ""
                    text: root.batteryText()
                    pillColor: root.batteryText().indexOf("") === 0 ? root.error : root.surface
                    textColor: root.batteryText().indexOf("") === 0 ? root.background : root.primary
                    strokeColor: root.secondary
                }

                Rectangle {
                    visible: trayRow.implicitWidth > 0
                    implicitWidth: trayRow.implicitWidth + 20
                    implicitHeight: 28
                    radius: 15
                    color: root.surface
                    border.color: root.secondary
                    border.width: 1

                    RowLayout {
                        id: trayRow
                        anchors.centerIn: parent
                        spacing: 8

                        Repeater {
                            model: SystemTray.items

                            Item {
                                property var trayItem: modelData

                                implicitWidth: 18
                                implicitHeight: 18

                                IconImage {
                                    anchors.centerIn: parent
                                    implicitSize: 18
                                    source: parent.trayItem.icon
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: function(mouse) {
                                        if (mouse.button === Qt.MiddleButton) {
                                            parent.trayItem.secondaryActivate()
                                        } else if (mouse.button === Qt.RightButton && parent.trayItem.hasMenu) {
                                            parent.trayItem.display(panel, 0, panel.implicitHeight)
                                        } else if (parent.trayItem.onlyMenu && parent.trayItem.hasMenu) {
                                            parent.trayItem.display(panel, 0, panel.implicitHeight)
                                        } else {
                                            parent.trayItem.activate()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                ModulePill {
                    text: ""
                    pillColor: root.surface
                    textColor: root.primary
                    strokeColor: root.secondary
                    horizontalPadding: 14

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["swaync-client", "-t", "-sw"])
                    }
                }
            }
        }
    }
}
