import QtQuick 2.12
import QtQuick.Layouts 1.12
import Lomiri.Components 1.3 as UITK
import "../Enums" as Enums
import "../Style" as Style

UITK.Page {
    id: pageHome
    
    property var amneziaStyle: Style.AmneziaStyle
    property var selectedProfile: null
    property int vpnState: Enums.Enums.VpnState.Disconnected
    property int tunnelMode: Enums.Enums.TunnelMode.FullTunnel
    
    UITK.PageHeader {
        id: header
        title: "AmneziaWG"
        trailingActionBar.actions: [
            UITK.Action {
                iconName: "settings"
                text: "Настройки"
                onTriggered: stack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }
        ]
    }
    
    ColumnLayout {
        anchors {
            top: header.bottom
            left: parent.left
            right: parent.left
            bottom: parent.bottom
            margins: units.gu(2)
        }
        spacing: units.gu(2)
        
        // 🔴🟡🟢 Статус VPN
        TunnelStatus {
            Layout.fillWidth: true
            Layout.preferredHeight: units.gu(8)
            vpnState: pageHome.vpnState
            amneziaStyle: amneziaStyle
        }
        
        // Выбор профиля
        UITK.ComboButton {
            Layout.fillWidth: true
            text: selectedProfile ? selectedProfile.name : "Выберите профиль"
            iconName: "contacts"
            onTriggered: profilePicker.open()
            
            ContentPicker {
                id: profilePicker
                // profiles из Python backend
            }
        }
        
        // Режим туннеля (Split Tunneling)
        RowLayout {
            Layout.fillWidth: true
            spacing: units.gu(1)
            
            UITK.Button {
                Layout.fillWidth: true
                text: "Полный туннель"
                checked: tunnelMode === Enums.Enums.TunnelMode.FullTunnel
                color: checked ? amneziaStyle.charcoalGray : amneziaStyle.mutedGray
                onClicked: tunnelMode = Enums.Enums.TunnelMode.FullTunnel
            }
            
            UITK.Button {
                Layout.fillWidth: true
                text: "Разделённый"
                checked: tunnelMode === Ennums.Enums.TunnelMode.SplitTunnel
                color: checked ? amneziaStyle.charcoalGray : amneziaStyle.mutedGray
                onClicked: tunnelMode = Enums.Enums.TunnelMode.SplitTunnel
            }
        }
        
        // Главная кнопка ПОДКЛЮЧИТЬ
        UITK.Button {
            Layout.fillWidth: true
            Layout.preferredHeight: units.gu(6)
            text: vpnState === Enums.Enums.VpnState.Connected ? "🔴 Отключить" : "🟢 Подключить"
            color: vpnState === Enums.Enums.VpnState.Connected 
                   ? amneziaStyle.vibrantRed 
                   : amneziaStyle.goldenApricot
            font.weight: Font.Bold
            onClicked: {
                if (vpnState === Enums.Enums.VpnState.Connected) {
                    root.python.call('vpn.disconnect', [], function(status) {
                        pageHome.vpnState = Enums.Enums.VpnState.Disconnected
                    })
                } else {
                    root.python.call('vpn.connect', [selectedProfile, tunnelMode], function(status) {
                        pageHome.vpnState = status
                    })
                }
            }
        }
        
        // Статистика подключения
        RowLayout {
            Layout.fillWidth: true
            spacing: units.gu(1)
            
            Item { Layout.fillWidth: true }
            
            ColumnLayout {
                Text { text: "TX"; color: amneziaStyle.mutedGray; font.pixelSize: units.gu(1.5) }
                Text { text: "0 MB"; color: amneziaStyle.charcoalGray; font.pixelSize: units.gu(2.5); font.weight: Font.Bold }
            }
            
            ColumnLayout {
                Text { text: "RX"; color: amneziaStyle.mutedGray; font.pixelSize: units.gu(1.5) }
                Text { text: "0 MB"; color: amneziaStyle.charcoalGray; font.pixelSize: units.gu(2.5); font.weight: Font.Bold }
            }
            
            Item { Layout.fillWidth: true }
        }
    }
}
