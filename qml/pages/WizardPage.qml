// WizardPage.qml
import QtQuick 2.12
import QtQuick.Controls 2.0
import Lomiri.Components 1.3 as UITK
import io.thp.pyotherside 1.3
import Qt.labs.settings 1.0

import "../components"
// import "../style"

UITK.Page {
    objectName: "wizard"
    property bool wizardRunning: true
    header: UITK.PageHeader {
        id: header
        title: "Amnezia Wizard"
    }
    UITK.ActivityIndicator {
        anchors.centerIn: parent
        visible: wizardRunning
        running: wizardRunning
    }

    Column {
        anchors.fill: parent
        anchors.topMargin: header.height + units.gu(3)
        anchors.margins: units.gu(3)
        spacing: units.gu(2)
        visible: !wizardRunning

        Rectangle {
            // color: '#EED202'
            color: root.amneziaStyle.burntOrange
            anchors.left: parent.left
            anchors.right: parent.right
            height: childrenRect.height + childrenRect.y + units.gu(2)
            radius: units.gu(1)

            Label {
                color: 'black'
                anchors.topMargin: units.gu(2)
                anchors.leftMargin: units.gu(2)
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                wrapMode: Text.WordWrap
                text: i18n.tr("Using AmneziaWG userspace (recommended for obfuscation)")
                                
                onLinkActivated: Qt.openUrlExternally(link)
            }
        }

        UITK.Label {
            anchors.left: parent.left
            anchors.right: parent.right
            wrapMode: Text.WordWrap
            text: i18n.tr("Please, <b>get in touch with your device porter</b> (or with me) to add support on your device; it takes a couple of minutes only.<br/>\
See <a href='https://gitlab.com/ubports/community-ports/android9/xiaomi-poco-f1/kernel-xiaomi-beryllium/-/merge_requests/1'>here</a> \
for an example change to the kernel.")
        }
        UITK.Button {
            anchors.left: parent.left
            anchors.right: parent.right
            text: i18n.tr("OK")
            onClicked: {
                root.activeTab = "home"
                settings.finishedWizard = true
                stack.clear()
                stack.push(Qt.resolvedUrl("PickProfilePage.qml"))
            }
        }
    }

    Settings {
        id: settings
        property bool finishedWizard: false
        property bool useUserspace: true
        property bool canUseKmod: false
    }

    Python {
        id: python
        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../../src/'))
            importModule('vpn', function () {
                python.call('vpn.instance.set_pwd', [root.pwd], function(result){});
                python.call('vpn.instance.can_use_kernel_module', [],
                            function (can_use_module) {
                                console.debug("can use kernel module::"+can_use_module);
                                settings.canUseKmod = can_use_module
                                settings.useUserspace = !can_use_module
                                wizardRunning = false
                                if (can_use_module) {
                                    settings.finishedWizard = true
                                    stack.clear()
                                    stack.push(Qt.resolvedUrl(
                                                   "PickProfilePage.qml"))
                                }
                            })
            })
        }
    }
}
