// Main.qml
import QtQuick 2.12
import QtQuick.Layouts 1.3
import Qt.labs.settings 1.0
import io.thp.pyotherside 1.3
import Lomiri.Components 1.3 as UITK
import Lomiri.Components.Popups 1.3
import Ubuntu.Content 1.3

import "./pages"
import "./components"
import "./style"

UITK.MainView {
    property string pwd

    id: root
    
    objectName: 'mainView'
    applicationName: 'amneziawg.sysadmin'
    automaticOrientation: true
    anchorToKeyboard: true

    property real footerHeight: units.gu(7)

    width: units.gu(45)
    height: units.gu(75)

    Settings {
        id: settings
        property bool finishedWizard: false
    }

    Toast {
        id: toast
    }
    // UITK.PageStack {
    //     anchors.fill: parent
    //     id: stack
    // }
    UITK.PageStack {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: globalFooter.top  // ← PageStack до футера
        }
        id: stack
        z: 1
    }



    Rectangle {
        id: globalFooter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        height: units.gu(7)
        z: 10

        color: "#1e1e1e"
        opacity: 0.96

        RowLayout {
            anchors.fill: parent
            anchors.margins: units.gu(1.5)
            spacing: units.gu(2)

            FooterIcon {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                icon: "../../assets/controls/home.svg"
                active: stack.currentItem ? (stack.currentItem.objectName === "home") : false
                onClicked: {
                    while (stack.depth > 1)
                        stack.pop()
                }
            }

            FooterIcon {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                icon: "../../assets/controls/settings.svg"
                active: stack.currentItem ? (stack.currentItem.objectName === "settings") : false
                onClicked: {
                    stack.push(Qt.resolvedUrl("pages/SettingsPage.qml"))
                }
            }

            FooterIcon {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                icon: "../../assets/controls/plus.svg"
                active: stack.currentItem ? (stack.currentItem.objectName === "configSource") : false
                onClicked: {
                    stack.push(Qt.resolvedUrl("pages/PageSetupWizardConfigSource.qml"))//,
                            // { interfaceName: "wg0" })
                }
            }
        }
    }



    // Component {
    //     id: passwordPopup
    //     Dialog {
    //         id: passwordDialog
    //         title: i18n.tr("Enter password")
    //         text: i18n.tr("Your password is required to use the wireguard kernel modules.")

    //         signal accepted(string password)
    //         signal rejected()

    //         UITK.TextField {
    //             id: passwordTextField
    //             echoMode: TextInput.Password
    //         }
    //         UITK.Button {
    //             text: i18n.tr("OK")
    //             color: UITK.LomiriColors.green
    //             onClicked: {
    //                 python.call('test.test_sudo',
    //                             [passwordTextField.text],
    //                             function(result){
    //                                 if(result) {
    //                                     passwordDialog.accepted(passwordTextField.text)
    //                                     PopupUtils.close(passwordDialog)
    //                                 }
    //                                 else {
    //                                     console.log("Passwordcheck failed")
    //                                 }
    //                             });
    //             }
    //         }
    //         UITK.Button {
    //             text: i18n.tr("Cancel")
    //             onClicked: {
    //                 passwordDialog.rejected();
    //                 PopupUtils.close(passwordDialog)
    //             }
    //         }
    //     }
    // }

    Component.onCompleted: {
        // check if user has set a sudo pwd and show password prompt if so:
        stack.push(Qt.resolvedUrl("pages/PickProfilePage.qml"));
        // python.call('test.test_sudo',
        //             [""], // check with empty password
        //             function(result) {
        //                 if(!result) {
        //                     var popup = PopupUtils.open(passwordPopup)
        //                     popup.accepted.connect(function(password) {
        //                         root.pwd = password;
        //                         checkFinished();
        //                     });
        //                     popup.rejected.connect(function() {
        //                         console.log("canceled!");
        //                         Qt.quit();
        //                     });
        //                 } else {
        //                     checkFinished();
        //                 }
        //             });

        // function checkFinished()
        // {
        //     if (settings.finishedWizard) {
        //         stack.push(Qt.resolvedUrl("pages/PickProfilePage.qml"));
        //     } else {
        //         stack.push(Qt.resolvedUrl("pages/WizardPage.qml"));
        //     }
        // }
    }

    Python {
        id: python
        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../src/'))
            importModule('test', function () {})
        }
    }
}
