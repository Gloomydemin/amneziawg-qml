// components/FooterIcon.qml
import QtQuick 2.12
import QtGraphicalEffects 1.0
import Lomiri.Components 1.3 as UITK
import QtGraphicalEffects 1.0

Item {
    id: footerIcon
    property var amneziaStyle: null

    width: units.gu(7)
    height: parent.height  // ← ключевое изменение

    property string icon
    property bool active: false
    signal clicked()

    Image {
        id: iconImg
        anchors.centerIn: parent
        source: icon
        width: units.gu(3)
        height: units.gu(3)
        fillMode: Image.PreserveAspectFit
        visible: false
    }

    ColorOverlay {
        anchors.fill: iconImg
        source: iconImg
        color: active && amneziaStyle
               ? amneziaStyle.burntOrange
               : "#cccccc"
    }

    MouseArea {
        anchors.fill: parent
        onClicked: footerIcon.clicked()
        cursorShape: Qt.PointingHandCursor
    }
}