import Lomiri.Components 1.3 as UITK
import QtQuick 2.12
import QtQuick.Layouts 1.12
UITK.Page {
    UITK.PageHeader {
    trailingActionBar {
        actions: [
            UITK.Action {
                iconName: "settings"
                text: "first"
            },
            UITK.Action {
                iconName: "info"
                text: "second"
            },
            UITK.Action {
                iconName: "toolkit_input-search"
                text: "third"
            }
       ]
       numberOfSlots: 2
    }
}
}
