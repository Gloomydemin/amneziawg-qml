// qml/components/TextTypes/HeaderText1.qml
import QtQuick 2.12
// import "../style"

Text {
    color: AmneziaStyle.color.paleGray
    font.pixelSize: units.gu(3.2)  // ~32px
    font.weight: Font.Bold
    font.letterSpacing: -1.0
    wrapMode: Text.WordWrap
    lineHeight: units.gu(3.8)  // ~38px
    lineHeightMode: Text.FixedHeight
}