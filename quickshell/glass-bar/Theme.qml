pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string colorsPath: Quickshell.env("HOME") + "/.cache/quickshell/glass-colors.json"

    property string rawColors: "{}"
    property var colors: ({})

    property color background: colorValue("background", "#191114")
    property color foreground: colorValue("foreground", "#eedfe3")
    property color primary: colorValue("primary", "#feb0d3")
    property color onPrimary: colorValue("on_primary", "#191114")
    property color secondary: colorValue("secondary", "#e0bdcb")
    property color surface: colorValue("surface", "#191114")
    property color surfaceBright: colorValue("surface_bright", "#40373a")
    property color error: colorValue("error", "#ffb4ab")

    readonly property int barHeight: 42
    readonly property int radius: 15
    readonly property bool bottomBar: true
    readonly property color barBackground: withAlpha(background, 0.58)
    readonly property color blockBackground: withAlpha(surface, 0.78)
    readonly property color blockHover: withAlpha(surfaceBright, 0.82)
    readonly property color border: withAlpha(secondary, 0.70)

    readonly property string textFont: "Inter Display"
    readonly property string monoFont: "JetBrainsMono Nerd Font"

    function withAlpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a)
    }

    function colorValue(name, fallback) {
        const value = colors && colors[name] ? String(colors[name]) : fallback
        return value
    }

    function load(raw) {
        rawColors = String(raw || "{}").trim()

        try {
            colors = JSON.parse(rawColors)
        } catch (e) {
            console.log("[glass-bar] failed to parse colors:", e)
            colors = ({})
        }
    }

    function reload() {
        colorFile.reload()
    }

    FileView {
        id: colorFile
        path: root.colorsPath
        watchChanges: true
        preload: true
        onLoaded: root.load(text())
        onTextChanged: root.load(text())
        onFileChanged: reload()
        onLoadFailed: root.load("{}")
    }
}
