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
    readonly property var defaults: ({ messages: "full", calls: "full", email: "count",
                                       calendar: "full", system: "none", other: "count" })
    readonly property var modes: ["none", "count", "full"]

    function modeOf(key) {
        return NV.get(["summary", "modes", key], page.defaults[key])
    }
    function modeName(m) {
        return m === "none" ? NV.t("Ne pas annoncer", "Do not announce")
             : m === "count" ? NV.t("Annoncer le nombre", "Announce the count")
             : NV.t("Tout lire", "Read everything")
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
                text: NV.t("Le résumé donne la date et l'heure, puis, pour chaque application de la Vue Événements, le nombre de ses notifications et, selon le réglage de sa famille, leur contenu. Il se lance depuis cette page, depuis Situations, ou à la connexion des écouteurs.",
                           "The summary gives the date and time, then, for each app in the Events view, how many notifications it has and, depending on its family's setting, their content. Start it from this page, from Situations, or when headphones connect.")
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
                text: NV.t("Effacer les notifications lues", "Clear notifications once read")
                description: NV.t("Chaque notification lue en entier disparaît de la Vue Événements. Une lecture interrompue, par un appel ou par vous, n'efface rien.",
                                  "Each notification read in full is removed from the Events view. An interrupted reading, by a call or by you, clears nothing.")
                checked: NV.get(["summary", "clear_after"], false)
                automaticCheck: false
                onClicked: NV.setCfg(["summary", "clear_after"], !checked)
            }
            TextSwitch {
                text: NV.t("Bip entre deux notifications", "Beep between notifications")
                description: NV.t("Sinon, une courte pause.", "Otherwise, a short pause.")
                checked: NV.get(["summary", "beep"], true)
                automaticCheck: false
                onClicked: NV.setCfg(["summary", "beep"], !checked)
            }
            Slider {
                width: parent.width
                label: NV.t("Nombre maximal de notifications lues", "Maximum notifications read")
                minimumValue: 5; maximumValue: 60; stepSize: 5
                value: NV.get(["summary", "max_items"], 30)
                valueText: value
                onReleased: NV.setCfg(["summary", "max_items"], value)
            }

            SectionHeader { text: NV.t("Traitement de chaque famille", "Handling of each family") }

            Repeater {
                model: page.families
                ComboBox {
                    id: fam
                    property string key: modelData.key
                    label: NV.t(modelData.fr, modelData.en)
                    description: NV.t(modelData.dfr, modelData.den)
                    currentIndex: page.modes.indexOf(page.modeOf(key))
                    menu: ContextMenu {
                        Repeater {
                            model: page.modes
                            MenuItem {
                                text: page.modeName(modelData)
                                onClicked: NV.setCfg(["summary", "modes", fam.key], modelData)
                            }
                        }
                    }
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                topPadding: Theme.paddingLarge
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
                text: NV.t("Chaque application peut aussi avoir son propre mode, dans sa page de la liste Applications. Pour une application réglée sur « titre seulement », le résumé n'annonce que l'expéditeur. Le bouton de cette page lit le résumé même sans écouteurs ; la commande de Situations, elle, respecte les règles habituelles.",
                           "Each app can also have its own mode, in its page of the Apps list. For an app set to \"title only\", the summary only announces the sender. The button on this page reads the summary even without headphones; the Situations command follows the usual rules.")
            }
        }
        VerticalScrollDecorator { }
    }
}
