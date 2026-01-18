// Header2Type.qml
import QtQuick 2.0
import QtQuick.Layouts 1.12
import Lomiri.Components 1.3 as UITK

// import "../style"

import "TextTypes"

Item {
    id: root

    property string actionButtonImage
    property var actionButtonFunction

    property alias actionButton: headerActionButton

    property string headerText
    property string descriptionText

    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    ColumnLayout {
        id: content
        anchors.fill: parent

        RowLayout {
            Header2TextType {
                id: header

                Layout.fillWidth: true

                text: root.headerText
            }

            ImageButtonType {
                id: headerActionButton

                implicitWidth: 40
                implicitHeight: 40

                image: root.actionButtonImage
                imageColor: AmneziaStyle.color.paleGray

                visible: image ? true : false

                onClicked: {
                    if (actionButtonFunction && typeof actionButtonFunction === "function") {
                        actionButtonFunction()
                    }
                }
            }
        }

        ParagraphTextType {
            id: description

            Layout.topMargin: 16
            Layout.fillWidth: true

            text: root.descriptionText

            color: AmneziaStyle.color.mutedGray

            visible: root.descriptionText !== ""
        }
    }

    Keys.onEnterPressed: {
        if (actionButtonFunction && typeof actionButtonFunction === "function") {
            actionButtonFunction()
        }
    }

    Keys.onReturnPressed: {
        if (actionButtonFunction && typeof actionButtonFunction === "function") {
            actionButtonFunction()
        }
    }
}