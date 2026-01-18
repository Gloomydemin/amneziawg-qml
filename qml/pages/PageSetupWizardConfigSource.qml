// qml/pages/PageSetupWizardConfigSource.qml
import QtQuick 2.12
import Lomiri.Components 1.3 as UITK
import Lomiri.Content 1.3
import io.thp.pyotherside 1.3
import QtGraphicalEffects 1.0

import "../components"
// import "../style"

UITK.Page {
    id: profileSetupWizardConfigSource
    objectName: "configSource"

    header: UITK.PageHeader {
        title: i18n.tr("Connection")        
        z:10
        leadingActionBar.actions: []
    }

    property bool clipboardAvailable: false

    Component.onCompleted: {
        // Проверяем доступность Clipboard
        clipboardAvailable = typeof Clipboard !== 'undefined' && 
                            typeof Clipboard.getText === 'function';
        console.log("Clipboard available:", clipboardAvailable);
    }

    Flickable {
        // anchors.fill: parent
        // contentHeight: mainColumn.height
        // boundsBehavior: Flickable.StopAtBounds
        // clip: true

        anchors {
            left: parent.left
            right: parent.right
            top: header.bottom
            bottom: parent.bottom
            // topMargin: units.gu(2)
            bottomMargin: root.footerHeight //+ units.gu(2)
        }
        contentHeight: mainColumn.height + units.gu(2)
        contentWidth: width
        clip: true

        Column {
            id: mainColumn
            width: parent.width - units.gu(4)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: units.gu(2)
            spacing: units.gu(4)

            // Основная область ввода ключа
            Rectangle {
                id: keyInputArea
                width: parent.width
                height: units.gu(24)
                color: root.amneziaStyle.onyxBlack
                radius: units.gu(2)

                Column {
                    anchors.centerIn: parent
                    anchors.margins: units.gu(2)
                    spacing: units.gu(2)
                    width: parent.width - units.gu(4)

                    UITK.Label {
                        text: i18n.tr("Insert the key, add a configuration file or scan the QR-code")
                        wrapMode: Text.Wrap
                        color: root.amneziaStyle.mutedGray
                        font.pixelSize: units.gu(1.8)
                        width: parent.width
                    }

                    // Поле для ввода ключа
                    MyTextField {
                        id: textKey
                        width: parent.width
                        title: i18n.tr("Insert key")  // Используем title вместо headerText
                        
                        // Добавляем кнопку "Вставить" в компонент
                        control: UITK.Button {
                            text: i18n.tr("Paste")
                            width: units.gu(8)
                            color: root.amneziaStyle.richBrown
                            
                            onClicked: {
                                if (root.clipboardAvailable) {
                                    var clipboardText = Clipboard.getText();
                                    if (clipboardText) {
                                        textKey.text = clipboardText;
                                    } else {
                                        showToast(i18n.tr("Clipboard is empty"));
                                    }
                                } else {
                                    // Запасной вариант для мобильных
                                    showToast(i18n.tr("Use your device's paste function"));
                                    textKey.forceActiveFocus();
                                    
                                    // Для отладки - добавляем тестовый текст
                                    textKey.text = "vpn://sample-config-" + Date.now();
                                }
                            }
                        }
                        
                        onTextChanged: {
                            continueButton.opacity = text.length > 0 ? 1.0 : 0.0;
                            continueButton.enabled = text.length > 0 && python.ready;
                        }
                    }

                    UITK.Button {
                        id: continueButton
                        text: i18n.tr("Continue")
                        enabled: textKey.text.length > 0 && python.ready
                        width: parent.width
                        
                        // Контролируем высоту вместо visible
                        height: enabled ? implicitHeight : 0
                        opacity: enabled ? 1.0 : 0.0
                        
                        // Двойная анимация
                        Behavior on height {
                            NumberAnimation { duration: 200 }
                        }
                        Behavior on opacity {
                            NumberAnimation { duration: 200 }
                        }
                        
                        // Важно: скрываем когда высота = 0
                        visible: height > 0
                        
                        onClicked: {
                            if (!python.ready) {
                                showToast(i18n.tr("Initializing, please wait..."))
                                return
                            }
                            python.call("profile.extract_config_from_text", [textKey.text], function(result) {
                                if (result && result.ok) {
                                    stack.push(Qt.resolvedUrl("PickProfilePage.qml"))
                                } else {
                                    showToast(i18n.tr("Invalid key"))
                                }
                            })
                        }
                    }
                }
            }

            // Заголовок для дополнительных опций
            UITK.Label {
                text: i18n.tr("Other connection options")
                color: "#aaaaaa"
                font.pixelSize: units.gu(1.8)
                width: parent.width
            }

            // Колонка с дополнительными опциями
            Column {
                width: parent.width
                spacing: units.gu(1)

                // 1. VPN by Amnezia (неактивный)
                Rectangle {
                    id: amneziaVpnItem
                    width: parent.width
                    height: units.gu(7)
                    radius: units.gu(1)
                    color: hovered ? "#252525" : "#1e1e1e"
                    border.color: "#222"
                    opacity: 0.6
                    property bool hovered: false

                    Row {
                        anchors.fill: parent
                        anchors.margins: units.gu(2)
                        spacing: units.gu(2)

                        Image {
                            source: "../../assets/controls/amnezia.svg"
                            width: units.gu(2.5)
                            height: width
                            fillMode: Image.PreserveAspectFit
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - units.gu(6)
                            spacing: units.gu(0.3)
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: i18n.tr("VPN by Amnezia")
                                color: "#666"
                                font.bold: true
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: i18n.tr("Connect to classic paid and free VPN services from Amnezia")
                                color: "#444"
                                font.pixelSize: units.gu(1.6)
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        Image {
                            source: "../../assets/controls/chevron-right.svg"
                            width: units.gu(1.5)
                            height: width
                            anchors.verticalCenter: parent.verticalCenter
                            visible: false
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: amneziaVpnItem.hovered = true
                        onExited: amneziaVpnItem.hovered = false
                        onClicked: showToast(i18n.tr("Coming soon"))
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                // 2. Self-hosted VPN (неактивный)
                Rectangle {
                    id: selfHostedItem
                    width: parent.width
                    height: units.gu(7)
                    radius: units.gu(1)
                    color: hovered ? "#252525" : "#1e1e1e"
                    border.color: "#222"
                    opacity: 0.6
                    property bool hovered: false

                    Row {
                        anchors.fill: parent
                        anchors.margins: units.gu(2)
                        spacing: units.gu(2)

                        Image {
                            source: "../../assets/controls/server.svg"
                            width: units.gu(2.5)
                            height: width
                            fillMode: Image.PreserveAspectFit
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - units.gu(6)
                            spacing: units.gu(0.3)
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                text: i18n.tr("Self-hosted VPN")
                                color: "#666"
                                font.bold: true
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: i18n.tr("Configure Amnezia VPN on your own server")
                                color: "#444"
                                font.pixelSize: units.gu(1.6)
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        Image {
                            source: "../../assets/controls/chevron-right.svg"
                            width: units.gu(1.5)
                            height: width
                            anchors.verticalCenter: parent.verticalCenter
                            visible: false
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: selfHostedItem.hovered = true
                        onExited: selfHostedItem.hovered = false
                        onClicked: showToast(i18n.tr("Coming soon"))
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                // 3. Restore from backup (неактивный)
                Rectangle {
                    id: restoreBackupItem
                    width: parent.width
                    height: units.gu(7)
                    radius: units.gu(1)
                    color: hovered ? "#252525" : "#1e1e1e"
                    border.color: "#222"
                    opacity: 0.6
                    property bool hovered: false

                    Row {
                        anchors.fill: parent
                        anchors.margins: units.gu(2)
                        spacing: units.gu(2)

                        Image {
                            source: "../../assets/controls/archive-restore.svg"
                            width: units.gu(2.5)
                            height: width
                            fillMode: Image.PreserveAspectFit
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: i18n.tr("Restore from backup")
                            color: "#666"
                            font.bold: true
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - units.gu(6)
                        }

                        Image {
                            source: "../../assets/controls/chevron-right.svg"
                            width: units.gu(1.5)
                            height: width
                            anchors.verticalCenter: parent.verticalCenter
                            visible: false
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: restoreBackupItem.hovered = true
                        onExited: restoreBackupItem.hovered = false
                        onClicked: showToast(i18n.tr("Coming soon"))
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                // 4. File with connection settings (активный)
                Rectangle {
                    id: fileSettingsItem
                    width: parent.width
                    height: units.gu(7)
                    radius: units.gu(1)
                    color: hovered ? "#252525" : "#1e1e1e"
                    border.color: "#333"
                    opacity: 1.0
                    property bool hovered: false

                    Row {
                        anchors.fill: parent
                        anchors.margins: units.gu(2)
                        spacing: units.gu(2)

                        Image {
                            source: "../../assets/controls/folder-search-2.svg"
                            width: units.gu(2.5)
                            height: width
                            fillMode: Image.PreserveAspectFit
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: i18n.tr("File with connection settings")
                            color: "#D7D8DB"
                            font.bold: true
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - units.gu(6)
                        }

                        Image {
                            source: "../../assets/controls/chevron-right.svg"
                            width: units.gu(1.5)
                            height: width
                            anchors.verticalCenter: parent.verticalCenter
                            visible: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: fileSettingsItem.hovered = true
                        onExited: fileSettingsItem.hovered = false
                        onClicked: showToast(i18n.tr("Import works only on real device"))
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                Rectangle {
                    id: newFileSettingsItem
                    width: parent.width
                    height: units.gu(7)
                    radius: units.gu(1)
                    color: hovered ? "#252525" : "#1e1e1e"
                    border.color: "#333"
                    opacity: 1.0
                    property bool hovered: false

                    Row {
                        anchors.fill: parent
                        anchors.margins: units.gu(2)
                        spacing: units.gu(2)

                        Image {
                            source: "../../assets/controls/edit-3.svg"
                            width: units.gu(2.5)
                            height: width
                            fillMode: Image.PreserveAspectFit
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: i18n.tr("New config")
                            color: "#D7D8DB"
                            font.bold: true
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - units.gu(6)
                        }

                        Image {
                            source: "../../assets/controls/chevron-right.svg"
                            width: units.gu(1.5)
                            height: width
                            anchors.verticalCenter: parent.verticalCenter
                            visible: true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: fileSettingsItem.hovered = true
                        onExited: fileSettingsItem.hovered = false
                        onClicked: {
                            stack.push(Qt.resolvedUrl("ProfilePage.qml"))
                        }
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                // 5. QR code (неактивный)
                Rectangle {
                    id: qrCodeItem
                    width: parent.width
                    height: units.gu(7)
                    radius: units.gu(1)
                    color: hovered ? "#252525" : "#1e1e1e"
                    border.color: "#222"
                    opacity: 0.6
                    property bool hovered: false

                    Row {
                        anchors.fill: parent
                        anchors.margins: units.gu(2)
                        spacing: units.gu(2)

                        Image {
                            source: "../../assets/controls/scan-line.svg"
                            width: units.gu(2.5)
                            height: width
                            fillMode: Image.PreserveAspectFit
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: i18n.tr("QR code")
                            color: "#666"
                            font.bold: true
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - units.gu(6)
                        }

                        Image {
                            source: "../../assets/controls/chevron-right.svg"
                            width: units.gu(1.5)
                            height: width
                            anchors.verticalCenter: parent.verticalCenter
                            visible: false
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: qrCodeItem.hovered = true
                        onExited: qrCodeItem.hovered = false
                        onClicked: showToast(i18n.tr("Coming soon"))
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                // 6. Restore purchases (неактивный)
                Rectangle {
                    id: restorePurchasesItem
                    width: parent.width
                    height: units.gu(7)
                    radius: units.gu(1)
                    color: hovered ? "#252525" : "#1e1e1e"
                    border.color: "#222"
                    opacity: 0.6
                    property bool hovered: false

                    Row {
                        anchors.fill: parent
                        anchors.margins: units.gu(2)
                        spacing: units.gu(2)

                        Image {
                            source: "../../assets/controls/refresh-cw.svg"
                            width: units.gu(2.5)
                            height: width
                            fillMode: Image.PreserveAspectFit
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: i18n.tr("Restore purchases")
                            color: "#666"
                            font.bold: true
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - units.gu(6)
                        }

                        Image {
                            source: "../../assets/controls/chevron-right.svg"
                            width: units.gu(1.5)
                            height: width
                            anchors.verticalCenter: parent.verticalCenter
                            visible: false
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: restorePurchasesItem.hovered = true
                        onExited: restorePurchasesItem.hovered = false
                        onClicked: showToast(i18n.tr("Coming soon"))
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                // 7. I have nothing (активный)

Item {
    width: parent.width
    height: units.gu(6)
    
    Rectangle {
        id: siteLink2
        anchors.horizontalCenter: parent.horizontalCenter
        
        width: textLabel.implicitWidth + icon.width + units.gu(5)
        height: units.gu(4)
        radius: units.gu(1)
        color: hovered ? root.amneziaStyle.translucentWhite : root.amneziaStyle.transparent

        property bool hovered: mouseArea.containsMouse

        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: units.gu(1.5)
            anchors.right: parent.right
            anchors.rightMargin: units.gu(1.5)
            spacing: units.gu(1)

            Text {
                id: textLabel
                text: i18n.tr("Site Amnezia")
                color: root.amneziaStyle.goldenApricot
                font.pixelSize: units.gu(2.4)
                font.weight: Font.DemiBold
                anchors.verticalCenter: parent.verticalCenter
            }

            // ✅ ИСПРАВЛЕННАЯ иконка с ColorOverlay
            Item {
                id: iconContainer
                width: units.gu(2)
                height: width
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    id: icon
                    anchors.centerIn: parent
                    source: "../../assets/controls/external-link.svg"
                    width: parent.width * 0.8
                    height: width
                    fillMode: Image.PreserveAspectFit
                }

                ColorOverlay {
                    anchors.fill: icon  
                    source: icon        
                    color: root.amneziaStyle.burntOrange
                           
                }
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            
            onClicked: Qt.openUrlExternally("https://amnezia.com")
        }

        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }
}







            }
        }
    }

    // Toast уведомление
    Rectangle {
        id: toastOverlay
        anchors.fill: parent
        visible: false
        color: Qt.rgba(0, 0, 0, 0.8)
        z: 1000

        MouseArea {
            anchors.fill: parent
            onClicked: toastOverlay.visible = false
        }

        Rectangle {
            width: parent.width * 0.8
            height: Math.max(toastLabel.implicitHeight + units.gu(4), units.gu(8))
            anchors.centerIn: parent
            color: "#1e1e1e"
            radius: units.gu(1)
            border.color: "#333"

            UITK.Label {
                id: toastLabel
                anchors.centerIn: parent
                width: parent.width - units.gu(4)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: "white"
                wrapMode: Text.WordWrap
                font.pixelSize: units.gu(1.8)
                anchors.margins: units.gu(2)  // Используем margins вместо padding
            }
        }

        Timer {
            id: toastTimer
            interval: 3000
            repeat: false
            onTriggered: toastOverlay.visible = false
        }
    }

    function showToast(message) {
        toastLabel.text = message
        toastOverlay.visible = true
        toastTimer.restart()
    }

    Python {
        id: python
        property bool ready: false

        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl("../../src/"))
            importModule("profile", function() {
                ready = true
                console.log("Python module loaded successfully")
            })
        }

        onError: {
            console.error("Python error:", traceback)
            showToast(i18n.tr("Error loading Python module"))
            ready = false
        }
    }

    // Состояние инициализации
    Rectangle {
        id: initOverlay
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.7)
        visible: !python.ready
        z: 999

        Column {
            anchors.centerIn: parent
            spacing: units.gu(2)

            UITK.ActivityIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                running: true
            }

            UITK.Label {
                text: i18n.tr("Initializing application...")
                color: "white"
                font.pixelSize: units.gu(1.8)
            }
        }
    }
}