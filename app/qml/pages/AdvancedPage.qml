import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    property bool svcEnabled: false
    property string journal: ""

    Component.onCompleted: py.call("notivox_ui.service_enabled", [], function(e) { page.svcEnabled = e })

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: col.height + Theme.paddingLarge

        Column {
            id: col
            width: parent.width
            PageHeader { title: app.t("Options avancées", "Advanced options") }

            SectionHeader { text: app.t("Quand lire", "When to read") }

            TextSwitch {
                text: app.t("Seulement avec des écouteurs", "Only with headphones")
                description: app.t("Bluetooth ou filaires. Sinon, rien n'est dit sur le haut-parleur.",
                                   "Bluetooth or wired. Otherwise nothing is spoken on the speaker.")
                checked: app.get(["require_headphones"], true)
                automaticCheck: false
                onClicked: app.setCfg(["require_headphones"], !checked)
            }
            TextSwitch {
                text: app.t("Lire si la sortie n'est pas reconnue", "Read if the output is not recognised")
                description: app.t("Utile si votre téléphone ne signale pas les écouteurs filaires. Sortie détectée maintenant : ",
                                   "Useful if your phone does not report wired headphones. Output detected now: ")
                             + app.outputName(app.status.output)
                enabled: app.get(["require_headphones"], true)
                checked: app.get(["speak_if_output_unknown"], false)
                automaticCheck: false
                onClicked: app.setCfg(["speak_if_output_unknown"], !checked)
            }
            TextSwitch {
                text: app.t("Se taire pendant un appel", "Stay quiet during a call")
                checked: app.get(["skip_during_call"], true)
                automaticCheck: false
                onClicked: app.setCfg(["skip_during_call"], !checked)
            }
            TextSwitch {
                text: app.t("Respecter le profil silencieux", "Respect the silent profile")
                checked: app.get(["respect_silent_profile"], false)
                automaticCheck: false
                onClicked: app.setCfg(["respect_silent_profile"], !checked)
            }

            SectionHeader { text: app.t("Ce qui est lu", "What is read") }

            TextSwitch {
                text: app.t("Annoncer le nom de l'application", "Announce the app name")
                description: app.t("Par exemple « WhatsApp. Alice. On se voit à midi ? »",
                                   "For example \"WhatsApp. Alice. Lunch at noon?\"")
                checked: app.get(["announce_app"], true)
                automaticCheck: false
                onClicked: app.setCfg(["announce_app"], !checked)
            }
            Slider {
                width: parent.width
                label: app.t("Longueur maximale lue", "Maximum length read")
                minimumValue: 60; maximumValue: 1000; stepSize: 20
                value: app.get(["max_chars"], 300)
                valueText: value + app.t(" caractères", " characters")
                onReleased: app.setCfg(["max_chars"], value)
            }

            SectionHeader { text: app.t("Son", "Sound") }

            TextField {
                width: parent.width
                label: app.t("Propriétés du flux des notifications", "Notification stream properties")
                text: app.get(["audio", "notification_props"], "media.role=notification")
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: { app.setCfg(["audio", "notification_props"], text); focus = false }
            }
            TextField {
                width: parent.width
                label: app.t("Propriétés du flux des appels", "Call stream properties")
                text: app.get(["audio", "call_props"], "media.name=notiftone")
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: { app.setCfg(["audio", "call_props"], text); focus = false }
            }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
                text: app.t("Ces propriétés indiquent au système audio comment traiter la voix, au format clé=valeur;clé=valeur. Ne les changez que si la voix ne sort pas dans les écouteurs, ou si elle coupe la sonnerie.",
                            "These properties tell the audio system how to handle the voice, as key=value;key=value. Only change them if the voice does not reach the headphones, or cuts the ringtone.")
            }

            SectionHeader { text: app.t("Service", "Service") }

            TextSwitch {
                text: app.t("Démarrer avec le téléphone", "Start with the phone")
                description: app.alive ? app.t("Service en marche, version ", "Service running, version ") + (app.status.version || "")
                                       : app.t("Service arrêté", "Service stopped")
                checked: page.svcEnabled
                automaticCheck: false
                onClicked: py.call("notivox_ui.service", [checked ? "disable" : "enable"], function() {
                    py.call("notivox_ui.service_enabled", [], function(e) { page.svcEnabled = e })
                    app.refresh()
                })
            }
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: app.t("Redémarrer le service", "Restart the service")
                onClicked: py.call("notivox_ui.service", ["restart"], function() { app.refresh() })
            }
            TextSwitch {
                text: app.t("Journal détaillé", "Verbose log")
                description: app.t("Note chaque notification reçue, pour comprendre un oubli.",
                                   "Logs every notification received, to understand a miss.")
                checked: app.get(["debug"], false)
                automaticCheck: false
                onClicked: app.setCfg(["debug"], !checked)
            }
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: app.t("Afficher le journal", "Show the log")
                onClicked: py.call("notivox_ui.journal", [80], function(j) { page.journal = j })
            }
            TextArea {
                visible: page.journal !== ""
                width: parent.width
                readOnly: true
                font.pixelSize: Theme.fontSizeTiny
                font.family: "monospace"
                text: page.journal
            }

            SectionHeader { text: app.t("À propos", "About") }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
                text: app.t("Notivox lit vos notifications et vos appels entrants avec la synthèse vocale Piper, entièrement sur le téléphone, sans connexion. Logiciel libre (GPL 3), réalisé en « vibe coding » avec Claude Opus 5.5.",
                            "Notivox reads your notifications and incoming calls with the Piper speech engine, entirely on the phone, offline. Free software (GPL 3), vibe-coded with Claude Opus 5.5.")
            }
        }
        VerticalScrollDecorator { }
    }
}
