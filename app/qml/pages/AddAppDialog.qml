import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Dialog {
    property alias name: field.text
    canAccept: field.text.trim().length > 0

    Column {
        width: parent.width
        DialogHeader { acceptText: NV.t("Ajouter", "Add") }
        TextField {
            id: field
            width: parent.width
            focus: true
            label: NV.t("Nom de l'application", "App name")
            placeholderText: label
            EnterKey.enabled: text.trim().length > 0
            EnterKey.iconSource: "image://theme/icon-m-enter-accept"
            EnterKey.onClicked: accept()
        }
        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - 2 * x
            wrapMode: Text.Wrap
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.secondaryHighlightColor
            text: NV.t("Indiquez le nom exact sous lequel l'application signe ses notifications, par exemple « WhatsApp » ou « Messages ».",
                        "Enter the exact name the app signs its notifications with, for example \"WhatsApp\" or \"Messages\".")
        }
    }
}
