// SettingsPage.qml
import QtQuick 2.12
import Lomiri.Components 1.3 as UITK
import io.thp.pyotherside 1.3
import Qt.labs.settings 1.0

import "../components"
// import "../style"

UITK.Page {
    objectName: "settings"
    Settings {
        id: settings

        property bool finishedWizard: false
        property bool useUserspace: true
        property bool canUseKmod: false
    }
    header: UITK.PageHeader {
        id: header
        title: i18n.tr("Settings")
        
        leadingActionBar.actions: []
    }

    

    ListView {
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: units.gu(2)
        anchors.leftMargin: units.gu(2)
        anchors.rightMargin: units.gu(2)
        Column {
            spacing: units.gu(1)
            anchors.left: parent.left
            anchors.right: parent.right
            SettingsItem {
                title: i18n.tr("Use slow userspace implementation")
                description: i18n.tr("It will be buggy, slow and probably crash.")
                control: UITK.Switch {
                    enabled: settings.canUseKmod
                    checked: settings.useUserspace
                    onCheckedChanged: settings.useUserspace = checked
                }
            }
            UITK.Button {
                text: i18n.tr("Try validating the kernel module again")
                anchors.left: parent.left
                anchors.right: parent.right
                onClicked: {
                    stack.clear()
                    stack.push(Qt.resolvedUrl("WizardPage.qml"))
                }
            }
        }
    }
}
