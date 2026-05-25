import QtQuick
import ".." as Root

Text {
    id: root

    property string symbolText: ""
    property bool active: false
    property int pointSize: 10

    text: wrapSymbols(symbolText)
    textFormat: Text.RichText
    color: active ? Root.Theme.onPrimary : Root.Theme.foreground
    font.family: Root.Theme.monoFont
    font.pointSize: pointSize
    font.weight: Font.DemiBold
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering

    function wrapSymbols(value) {
        const input = String(value || "")
        const isSymbol = codePoint =>
            (codePoint >= 0xE000 && codePoint <= 0xF8FF)
            || (codePoint >= 0xF0000 && codePoint <= 0xFFFFF)
            || (codePoint >= 0x100000 && codePoint <= 0x10FFFF)

        return input.replace(/./gu, c => isSymbol(c.codePointAt(0))
            ? `<span style='font-family: ${Root.Theme.monoFont}; font-size: ${pointSize + 3}pt'>${c}</span>`
            : c)
    }
}
