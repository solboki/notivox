import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Page {
    id: page

    // Familles de notifications proposées au résumé
    property var families: [
        { key: "messages", fr: "Messages", en: "Messages",
          dfr: "SMS et messageries (WhatsApp, Signal…)", den: "SMS and messaging apps" },
        { key: "calls", fr: "Appels manqués", en: "Missed calls",
          dfr: "", den: "" },
        { key: "email", fr: "Courriels", en: "Emails", dfr: "", den: "" },
        { key: "calendar", fr: "Agenda et rappels", en: "Calendar and reminders",
          dfr: "", den: "" },
        { key: "system", fr: "Système", en: "System",
          dfr: "Batterie, mises à jour, transferts…", den: "Battery, updates, transfers…" },
        { key: "other", fr: "Autres applications", en: "Other apps",
          dfr: "Notifications sans famille reconnue", den: "Notifications without a known family" }
    ]
    readonly property var defaults: ({ messages: true, calls: true, email: true,
                                       calendar: true, system: false, other: true })

    function typeOn(key) {
        return NV.get(["summary", "types", key], page.defaults[key])
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: col.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem {
                text: NV.t("Interrompre la lecture", "Stop reading")
                onClicked: NV.py.call("notivox_ui.stop", [])
            }
            MenuItem {
                text: NV.t("Écouter le résumé maintenant", "Play the summary now")
                enabled: NV.alive
                onClicked: NV.py.call("notivox_ui.summary", [true])
            }
        }

        Column {
            id: col
            width: parent.width
            PageHeader { title: NV.t("Résumé vocal", "Spoken summary") }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.highlightColor
                bottomPadding: Theme.paddingMedium
                text: NV.t("Le résumé lit les notifications présentes dans la Vue Événements : d'abord leur nombre pour chaque application, puis leur contenu. Il se lance depuis le menu du haut de cette page, depuis Situations, ou à la connexion des écouteurs.",
                           "The summary reads the notifications shown in the Events view: first how many each app has, then their content. Start it from the top menu of this page, from Situations, or when headphones connect.")
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: NV.t("Écouter le résumé", "Play the summary")
                enabled: NV.alive
                onClicked: NV.py.call("notivox_ui.summary", [true])
            }

            SectionHeader { text: NV.t("Lecture", "Reading") }

            TextSwitch {
                text: NV.t("Lire à la connexion des écouteurs", "Read when headphones connect")
                description: NV.t("Quand un casque Bluetooth se connecte ou que des écouteurs filaires sont branchés. Le même résumé n'est pas relu dans la demi-heure, et rien n'est lu après un appel.",
                                  "When a Bluetooth headset connects or wired headphones are plugged in. The same summary is not read again within half an hour, and nothing is read after a call.")
                checked: NV.get(["summary", "on_headset"], false)
                automaticCheck: false
                onClicked: NV.setCfg(["summary", "on_headset"], !checked)
            }
            TextSwitch {
                text: NV.t("Lire le contenu après le décompte", "Read the content after the count")
                description: NV.t("Sinon, seul le nombre de notifications par application est annoncé.",
                                  "Otherwise only the number of notifications per app is announced.")
                checked: NV.get(["summary", "detail"], true)
                automaticCheck: false
                onClicked: NV.setCfg(["summary", "detail"], !checked)
            }
            TextSwitch {
                text: NV.t("Effacer les notifications lues", "Clear notifications once read")
                description: NV.t("Chaque notification lue en entier disparaît de la Vue Événements. Une lecture interrompue, par un appel ou par vous, n'efface rien.",
                                  "Each notification read in full is removed from the Events view. An interrupted reading, by a call or by you, clears nothing.")
                checked: NV.get(["summary", "clear_after"], false)
                automaticCheck: false
                onClicked: NV.setCfg(["summary", "clear_after"], !checked)
            }
            Slider {
                width: parent.width
                label: NV.t("Nombre maximal de notifications lues", "Maximum notifications read")
                minimumValue: 5; maximumValue: 60; stepSize: 5
                value: NV.get(["summary", "max_items"], 30)
                valueText: value
                onReleased: NV.setCfg(["summary", "max_items"], value)
            }

            SectionHeader { text: NV.t("Notifications prises en compte", "Notifications included") }

            Repeater {
                model: page.families
                TextSwitch {
                    text: NV.t(modelData.fr, modelData.en)
                    description: NV.t(modelData.dfr, modelData.den)
                    checked: page.typeOn(modelData.key)
                    automaticCheck: false
                    onClicked: NV.setCfg(["summary", "types", modelData.key], !checked)
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                topPadding: Theme.paddingLarge
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
                text: NV.t("Pour une application réglée sur « titre seulement » dans la page Applications, le résumé n'annonce que l'expéditeur. Le bouton de cette page lit le résumé même sans écouteurs ; la commande de Situations, elle, respecte les règles habituelles.",
                           "For an app set to \"title only\" in the Apps page, the summary only announces the sender. The button on this page reads the summary even without headphones; the Situations command follows the usual rules.")
            }
        }
        VerticalScrollDecorator { }
    }
}
