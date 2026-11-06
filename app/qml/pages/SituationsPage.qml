import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Page {
    SilicaFlickable {
        anchors.fill: parent
        contentHeight: col.height + Theme.paddingLarge

        Column {
            id: col
            width: parent.width
            spacing: Theme.paddingMedium
            PageHeader { title: NV.t("Commandes pour Situations", "Commands for Situations") }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.Wrap
                color: Theme.highlightColor
                text: NV.t("Dans Situations, ajoutez à une situation l'action « exécuter une commande » avec l'une des lignes ci-dessous. Touchez une ligne pour la copier.",
                            "In Situations, add a \"run command\" action to a situation with one of the lines below. Tap a line to copy it.")
            }

            Repeater {
                model: [
                    { c: "notivox-ctl on", fr: "Activer la lecture", en: "Turn reading on" },
                    { c: "notivox-ctl off", fr: "Couper la lecture", en: "Turn reading off" },
                    { c: "notivox-ctl toggle", fr: "Inverser", en: "Toggle" },
                    { c: "notivox-ctl pause 60", fr: "Suspendre 60 minutes", en: "Pause for 60 minutes" },
                    { c: "notivox-ctl resume", fr: "Reprendre", en: "Resume" },
                    { c: "notivox-ctl say Bonjour", fr: "Lire un texte", en: "Speak a text" }
                ]
                BackgroundItem {
                    width: col.width
                    height: Theme.itemSizeMedium
                    onClicked: {
                        Clipboard.text = modelData.c
                        hint.text = NV.t("Copié : ", "Copied: ") + modelData.c
                    }
                    Column {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2 * x
                        anchors.verticalCenter: parent.verticalCenter
                        Label {
                            text: modelData.c
                            font.family: "monospace"
                            color: highlighted ? Theme.highlightColor : Theme.primaryColor
                        }
                        Label {
                            text: NV.t(modelData.fr, modelData.en)
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: Theme.secondaryColor
                        }
                    }
                }
            }

            Label {
                id: hint
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeSmall
            }

            SectionHeader { text: NV.t("Par D-Bus", "Over D-Bus") }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
                text: NV.t("Les mêmes ordres existent sous forme de signaux D-Bus sur le bus de session, interface org.notivox.Control, chemin /org/notivox : Enable, Disable, Toggle, Resume, Pause (int32, minutes) et Say (texte). Exemple :",
                            "The same orders exist as D-Bus signals on the session bus, interface org.notivox.Control, path /org/notivox: Enable, Disable, Toggle, Resume, Pause (int32, minutes) and Say (text). Example:")
            }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.WrapAnywhere
                font.family: "monospace"
                font.pixelSize: Theme.fontSizeExtraSmall
                text: "dbus-send --session --type=signal /org/notivox org.notivox.Control.Pause int32:30"
            }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
                text: NV.t("L'interrupteur et la pause de la page d'accueil reflètent aussitôt ces commandes : Situations et l'application agissent sur le même état.",
                            "The switch and pause on the main page reflect these commands at once: Situations and the app act on the same state.")
            }
        }
        VerticalScrollDecorator { }
    }
}
