// ProfilePage.qml (исправленная версия)
import QtQuick 2.12
import QtQuick.Layouts 1.12
import Qt.labs.settings 1.0
import Lomiri.Components 1.3 as UITK
import io.thp.pyotherside 1.3

import "../components"
// import "../Style"

UITK.Page {
    id: profilePage
    objectName: "profile"
    property bool isEditing: false
    property string errorMsg
    property string profileName
    property string ipAddress
    property string privateKey
    property string extraRoutes
    property string dnsServers
    property string interfaceName

    property var peers
    property var jc
    property var jmin
    property var jmax

    ListModel {
        id: listmodel
        dynamicRoles: true
    }

    Settings {
        id: settings
        property int interfaceNumber: 0
    }

    header: UITK.PageHeader {
        id: header
        title: isEditing
               ? i18n.tr("Edit AmneziaWG profile %1").arg(profileName)
               : i18n.tr("Create AmneziaWG profile")
        leadingActionBar.actions: []
    }

    Flickable {
        id: flick
        anchors {
            left: parent.left
            right: parent.right
            top: header.bottom
            bottom: parent.bottom
            topMargin: units.gu(2)
            bottomMargin: root.footerHeight //+ units.gu(2)
        }
        contentHeight: contentColumn.height + units.gu(2)
        contentWidth: width
        clip: true

        Column {
            id: contentColumn
            width: parent.width - units.gu(4)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: units.gu(2)

            // Основные поля профиля
            Column {
                width: parent.width
                spacing: units.gu(2)

                MyTextField {
                    visible: !isEditing
                    title: i18n.tr("Profile name")
                    text: profileName
                    enabled: !isEditing
                    placeholder: i18n.tr("Enter profile name")  // ИСПРАВЛЕНО: placeholderText -> placeholder
                    onChanged: {
                        errorMsg = ""
                        profileName = text
                    }
                }

                // Секция Private Key
                Column {
                    width: parent.width
                    spacing: units.gu(1)

                    UITK.Label {
                        width: parent.width
                        text: i18n.tr("Private Key")
                        font.bold: true
                        color: root.amneziaStyle.onyxBlack
                        fontSize: "medium"
                    }

                    Rectangle {
                        width: parent.width
                        height: units.gu(5)
                        color: root.amneziaStyle.mutedGray
                        radius: units.dp(4)
                        border.color: root.amneziaStyle.onyxBlack
                        border.width: 1

                        TextEdit {
                            id: privateKeyText
                            anchors {
                                fill: parent
                                margins: units.gu(1)
                            }
                            text: privateKey
                            font.pixelSize: units.gu(1.5)
                            color: root.amneziaStyle.onyxBlack
                            wrapMode: Text.WrapAnywhere
                            selectByMouse: true
                            onTextChanged: {
                                errorMsg = ""
                                privateKey = text
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: units.gu(1)

                        UITK.Button {
                            id: genKey
                            text: i18n.tr("Generate")
                            width: parent.width / 2 - units.gu(0.5)
                            onClicked: {
                                python.call("vpn.instance.genkey", [], function(key) {
                                    if (key)
                                        privateKey = key
                                })
                            }
                        }

                        UITK.Button {
                            text: i18n.tr("Copy pubkey")
                            enabled: privateKey
                            width: parent.width / 2 - units.gu(0.5)
                            onClicked: {
                                const pubkey = python.call_sync(
                                                   "vpn.instance.genpubkey",
                                                   [privateKey])
                                UITK.Clipboard.push(pubkey)
                                toast.show("Public key copied to clipboard")
                            }
                        }
                    }
                }

                MyTextField {
                    title: i18n.tr("IP address (with prefix length)")
                    text: ipAddress
                    placeholder: "10.0.0.14/24"  // ИСПРАВЛЕНО: используем placeholder
                    
                    onChanged: {
                        errorMsg = ""
                        ipAddress = text
                    }
                }

                // ===== AMNEZIAWG OBFUSCATION =====
                UITK.ListItem {
                    width: parent.width
                    height: units.gu(5)
                    divider.colorFrom: root.amneziaStyle.onyxBlack
                    divider.colorTo: root.amneziaStyle.onyxBlack

                    UITK.Label {
                        anchors.centerIn: parent
                        text: "AmneziaWG Obfuscation (DPI bypass)"
                        font.bold: true
                        fontSize: "medium"
                        color: root.amneziaStyle.onyxBlack
                    }
                }

                GridLayout {
                    width: parent.width
                    columns: 3
                    columnSpacing: units.gu(1)
                    rowSpacing: units.gu(1)

                    MyTextField {
                        id: jcField
                        Layout.fillWidth: true
                        title: "Jc (1-128)"
                        placeholder: "4"  // ИСПРАВЛЕНО: используем placeholder
                        text: "4"
                        
                        onChanged: errorMsg = ""
                    }

                    MyTextField {
                        id: jminField
                        Layout.fillWidth: true
                        title: "Jmin (0-300)"
                        placeholder: "20"  // ИСПРАВЛЕНО: используем placeholder
                        text: "20"
                        
                        onChanged: errorMsg = ""
                    }

                    MyTextField {
                        id: jmaxField
                        Layout.fillWidth: true
                        title: "Jmax (0-3000)"
                        placeholder: "40"  // ИСПРАВЛЕНО: используем placeholder
                        text: "40"
                        
                        onChanged: errorMsg = ""
                    }
                }

                RowLayout {
                    width: parent.width
                    spacing: units.gu(1)

                    UITK.Button {
                        text: "Random"
                        Layout.fillWidth: true
                        color: UITK.LomiriColors.orange
                        onClicked: {
                            jcField.text = Math.floor(Math.random() * 128) + 1
                            jminField.text = Math.floor(Math.random() * 100)
                            jmaxField.text = Math.floor(Math.random() * 500) + 200
                            toast.show("Random AmneziaWG obfuscation generated!")
                        }
                    }

                    UITK.Button {
                        text: "Optimal"
                        Layout.fillWidth: true
                        color: UITK.LomiriColors.green
                        onClicked: {
                            jcField.text = "4"
                            jminField.text = "20"
                            jmaxField.text = "40"
                            toast.show("Optimal AmneziaWG settings loaded!")
                        }
                    }
                }
                // ===== END AMNEZIAWG =====

                MyTextField {
                    title: i18n.tr("Extra routes")
                    text: extraRoutes
                    placeholder: "10.0.0.14/24"  // ИСПРАВЛЕНО: используем placeholder
                    onChanged: {
                        errorMsg = ""
                        extraRoutes = text
                    }
                }
                
                MyTextField {
                    title: i18n.tr("DNS Servers")
                    text: dnsServers
                    placeholder: "10.0.0.1"  // ИСПРАВЛЕНО: используем placeholder
                    onChanged: {
                        errorMsg = ""
                        dnsServers = text
                    }
                }
            }

            // Список пиров
            Repeater {
                model: listmodel
                delegate: Column {
                    width: parent.width
                    spacing: units.gu(2)

                    Rectangle {
                        width: parent.width
                        height: units.gu(6)
                        color: root.amneziaStyle.onyxBlack
                        radius: units.dp(8)
                        border.color: root.amneziaStyle.onyxBlack
                        border.width: 1

                        RowLayout {
                            anchors {
                                fill: parent
                                margins: units.gu(1)
                            }

                            UITK.Label {
                                Layout.fillWidth: true
                                text: i18n.tr("Peer #%1").arg(index + 1)
                                font.bold: true
                                color: root.amneziaStyle.onyxBlack
                                fontSize: "medium"
                            }

                            UITK.Icon {
                                name: "delete"
                                width: units.gu(3)
                                height: units.gu(3)
                                color: UITK.LomiriColors.red
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (index >= 0 && index < listmodel.count)
                                            listmodel.remove(index, 1)
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: units.gu(1.5)

                        MyTextField {
                            width: parent.width
                            title: i18n.tr("Name")
                            text: name
                            placeholder: i18n.tr("Peer name")  // ИСПРАВЛЕНО: placeholderText -> placeholder
                            onChanged: {
                                errorMsg = ""
                                name = text
                            }
                        }

                        MyTextField {
                            width: parent.width
                            title: i18n.tr("Public key")
                            placeholder: "c29tZSBzaWxseSBzdHVmZgo="  // ИСПРАВЛЕНО: используем placeholder
                            text: key
                            onChanged: {
                                errorMsg = ""
                                key = text
                            }
                        }

                        MyTextField {
                            width: parent.width
                            title: i18n.tr("Allowed IP prefixes")
                            text: allowedPrefixes
                            placeholder: "10.0.0.1/32, 192.168.1.0/24"  // ИСПРАВЛЕНО: используем placeholder
                            onChanged: {
                                errorMsg = ""
                                allowedPrefixes = text
                            }
                        }

                        MyTextField {
                            width: parent.width
                            title: i18n.tr("Endpoint with port")
                            text: endpoint
                            placeholder: "vpn.example.com:1234"  // ИСПРАВЛЕНО: используем placeholder
                            onChanged: {
                                errorMsg = ""
                                endpoint = text
                            }
                        }

                        MyTextField {
                            width: parent.width
                            title: i18n.tr("Preshared key")
                            placeholder: "c29tZSBzaWxseSBzdHVmZgo="  // ИСПРАВЛЕНО: используем placeholder
                            text: presharedKey
                            onChanged: {
                                errorMsg = ""
                                presharedKey = text
                            }
                        }
                    }
                }
            }

            // Кнопка добавления пира
            UITK.Button {
                id: addPeerButton
                width: parent.width
                text: i18n.tr("+ Add Peer")
                color: UITK.LomiriColors.blue
                onClicked: {
                    listmodel.append({
                        "name": "",
                        "key": "",
                        "allowedPrefixes": "",
                        "endpoint": "",
                        "presharedKey": ""
                    })
                }
            }

            // Сообщение об ошибке
            Rectangle {
                width: parent.width
                height: errorMsg ? units.gu(8) : 0
                visible: errorMsg
                color: UITK.LomiriColors.red
                radius: units.dp(4)
                opacity: 0.9

                UITK.Label {
                    anchors {
                        fill: parent
                        margins: units.gu(1)
                    }
                    text: errorMsg
                    color: "white"
                    wrapMode: Text.WordWrap
                    fontSize: "small"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            // Кнопка сохранения
            UITK.Button {
                id: saveButton
                width: parent.width
                height: units.gu(6)
                text: i18n.tr("Save AmneziaWG profile")
                color: UITK.LomiriColors.green
                enabled: listmodel.count &&
                         profileName &&
                         ipAddress &&
                         privateKey &&
                         jcField.text &&
                         jminField.text &&
                         jmaxField.text

                onClicked: {
                    errorMsg = ""

                    let _peers = []
                    for (var i = 0; i < listmodel.count; i++) {
                        const p = listmodel.get(i)
                        _peers.push({
                            "name": p.name,
                            "key": p.key,
                            "allowed_prefixes": p.allowedPrefixes,
                            "endpoint": p.endpoint,
                            "presharedKey": p.presharedKey
                        })
                    }

                    python.call(
                        "vpn.instance.save_profile",
                        [
                            profileName,
                            ipAddress,
                            privateKey,
                            interfaceName,
                            extraRoutes,
                            dnsServers,
                            _peers,
                            jcField.text,
                            jminField.text,
                            jmaxField.text,
                            "0", "0", "1", "2", "3", "4"
                        ],
                        function (res) {
                            if (typeof res === "string") {
                                if (!res || res === "Profile saved successfully") {
                                    toast.show("AmneziaWG profile saved with obfuscation!")
                                    if (!isEditing) {
                                        settings.interfaceNumber = settings.interfaceNumber + 1
                                    }
                                    stack.clear()
                                    stack.push(Qt.resolvedUrl("PickProfilePage.qml"))
                                } else {
                                    console.log("Save error:", res)
                                    errorMsg = res
                                }
                                return
                            }

                            if (!res || !res.ok) {
                                console.log("Save error:", res && res.message ? res.message : "Unknown error")
                                errorMsg = res && res.message ? res.message : "Unknown error"
                                return
                            }

                            toast.show(res.message)
                            if (!isEditing) {
                                settings.interfaceNumber = settings.interfaceNumber + 1
                            }
                            stack.clear()
                            stack.push(Qt.resolvedUrl("PickProfilePage.qml"))
                        }
                    )
                }
            }
        }
    }

    Component.onCompleted: {
        


        if (isEditing) {
            if (jc !== undefined && jc !== null && jc !== "")
                jcField.text = jc.toString()
            if (jmin !== undefined && jmin !== null && jmin !== "")
                jminField.text = jmin.toString()
            if (jmax !== undefined && jmax !== null && jmax !== "")
                jmaxField.text = jmax.toString()
        }

        if (!peers)
            return

        if (typeof peers.count === "number" && typeof peers.get === "function") {
            for (var i = 0; i < peers.count; i++) {
                const p = peers.get(i)
                listmodel.append({
                    "name": p.name,
                    "key": p.key,
                    "allowedPrefixes": p.allowed_prefixes,
                    "endpoint": p.endpoint,
                    "presharedKey": p.presharedKey
                })
            }
        } else if (peers.length !== undefined) {
            for (var j = 0; j < peers.length; j++) {
                const q = peers[j]
                listmodel.append({
                    "name": q.name,
                    "key": q.key,
                    "allowedPrefixes": q.allowed_prefixes,
                    "endpoint": q.endpoint,
                    "presharedKey": q.presharedKey
                })
            }
        }
    }

    Python {
        id: python
        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl("../../src/"))
            importModule("vpn", function () {
                python.call("vpn.instance.set_pwd", [root.pwd], function(result){})
            })
        }
    }
}