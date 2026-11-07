import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Page {
    id: page
    property bool svcEnabled: false
    property string journal: ""

    Component.onCompleted: NV.py.call("notivox_ui.service_enabled", [], function(e) { page.svcEnabled = e })

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: col.height + Theme.paddingLarge

        Column {
            id: col
            width: parent.width
            PageHeader { title: NV.t("Options avancées", "Advanced options") }

            SectionHeader { text: NV.t("Quand lire", "When to read") }

            TextSwitch {
                text: NV.t("Seulement avec des écouteurs", "Only with headphones")
                description: NV.t("Bluetooth ou filaires. Sinon, rien n'est dit sur le haut-parleur.",
                                   "Bluetooth or wired. Otherwise nothing is spoken on the speaker.")
                checked: NV.get(["require_headphones"], true)
                automaticCheck: false
                onClicked: NV.setCfg(["require_headphones"], !checked)
            }
            TextSwitch {
                text: NV.t("Lire si la sortie n'est pas reconnue", "Read if the output is not recognised")
                description: NV.t("Utile si votre téléphone ne signale pas les écouteurs filaires. Sortie détectée maintenant : ",
                                   "Useful if your phone does not report wired headphones. Output detected now: ")
                             + NV.outputName(NV.status.output)
                enabled: NV.get(["require_headphones"], true)
                checked: NV.get(["speak_if_output_unknown"], false)
                automaticCheck: false
                onClicked: NV.setCfg(["speak_if_output_unknown"], !checked)
            }
            TextSwitch {
                text: NV.t("Mettre la musique en pause pendant la lecture", "Pause the music while reading")
                description: NV.t("La musique ou le podcast en cours s'arrête pendant que Notivox parle, puis reprend. Une application qui ne se laisse pas mettre en pause est rendue muette à la place.",
                                  "The music or podcast playing stops while Notivox speaks, then resumes. An app that cannot be paused is muted instead.")
                checked: NV.get(["pause_players"], true)
                automaticCheck: false
                onClicked: NV.setCfg(["pause_players"], !checked)
            }
            TextSwitch {
                text: NV.t("Interrompre avec le bouton du casque", "Stop with the headset button")
                description: NV.t("Pendant une lecture, un appui court sur le bouton lecture/pause l'arrête, résumé compris, et la musique mise en pause reprend.",
                                  "While reading, a short press on the play/pause button stops it, summary included, and the paused music resumes.")
                checked: NV.get(["headset_button"], true)
                automaticCheck: false
                onClicked: NV.setCfg(["headset_button"], !checked)
            }
            TextSwitch {
                text: NV.t("Se taire pendant un appel", "Stay quiet during a call")
                checked: NV.get(["skip_during_call"], true)
                automaticCheck: false
                onClicked: NV.setCfg(["skip_during_call"], !checked)
            }
            TextSwitch {
                text: NV.t("Respecter le profil silencieux", "Respect the silent profile")
                checked: NV.get(["respect_silent_profile"], false)
                automaticCheck: false
                onClicked: NV.setCfg(["respect_silent_profile"], !checked)
            }

            SectionHeader { text: NV.t("Ce qui est lu", "What is read") }

            TextSwitch {
                text: NV.t("Annoncer le nom de l'application", "Announce the app name")
                description: NV.t("Par exemple « WhatsApp. Alice. On se voit à midi ? »",
                                   "For example \"WhatsApp. Alice. Lunch at noon?\"")
                checked: NV.get(["announce_app"], true)
                automaticCheck: false
                onClicked: NV.setCfg(["announce_app"], !checked)
            }
            Slider {
                width: parent.width
                label: NV.t("Longueur maximale lue", "Maximum length read")
                minimumValue: 60; maximumValue: 1000; stepSize: 20
                value: NV.get(["max_chars"], 300)
                valueText: value + NV.t(" caractères", " characters")
                onReleased: NV.setCfg(["max_chars"], value)
            }

            SectionHeader { text: NV.t("Son", "Sound") }

            TextField {
                width: parent.width
                label: NV.t("Propriétés du flux des notifications", "Notification stream properties")
                text: NV.get(["audio", "notification_props"], "media.role=notification")
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: { NV.setCfg(["audio", "notification_props"], text); focus = false }
            }
            TextField {
                width: parent.width
                label: NV.t("Propriétés du flux des appels", "Call stream properties")
                text: NV.get(["audio", "call_props"], "media.role=notification")
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: { NV.setCfg(["audio", "call_props"], text); focus = false }
            }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
                text: NV.t("Ces propriétés indiquent au système audio comment traiter la voix, au format clé=valeur;clé=valeur. Ne les changez que si la voix ne sort pas dans les écouteurs, ou si elle coupe la sonnerie.",
                            "These properties tell the audio system how to handle the voice, as key=value;key=value. Only change them if the voice does not reach the headphones, or cuts the ringtone.")
            }

            SectionHeader { text: NV.t("Service", "Service") }

            TextSwitch {
                text: NV.t("Service actif", "Service on")
                description: (NV.alive ? NV.t("En marche, version ", "Running, version ") + (NV.status.version || "")
                                       : NV.t("Arrêté", "Stopped")) +
                             NV.t(". Il démarre avec le téléphone ; coupé, il reste arrêté même après un redémarrage.",
                                  ". It starts with the phone; when off, it stays stopped even after a restart.")
                checked: page.svcEnabled
                automaticCheck: false
                onClicked: NV.py.call("notivox_ui.service", [checked ? "disable" : "enable"], function() {
                    NV.py.call("notivox_ui.service_enabled", [], function(e) { page.svcEnabled = e })
                    NV.refresh()
                })
            }
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: NV.t("Redémarrer le service", "Restart the service")
                onClicked: NV.py.call("notivox_ui.service", ["restart"], function() { NV.refresh() })
            }
            TextSwitch {
                text: NV.t("Journal détaillé", "Verbose log")
                description: NV.t("Note chaque notification reçue, pour comprendre un oubli.",
                                   "Logs every notification received, to understand a miss.")
                checked: NV.get(["debug"], false)
                automaticCheck: false
                onClicked: NV.setCfg(["debug"], !checked)
            }
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: NV.t("Afficher le journal", "Show the log")
                onClicked: NV.py.call("notivox_ui.journal", [80], function(j) { page.journal = j })
            }
            TextArea {
                visible: page.journal !== ""
                width: parent.width
                readOnly: true
                font.pixelSize: Theme.fontSizeTiny
                font.family: "monospace"
                text: page.journal
            }

            SectionHeader { text: NV.t("À propos", "About") }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
                text: NV.t("Notivox (Notification vocale) lit vos notifications et vos appels entrants avec la synthèse vocale Piper, entièrement sur le téléphone, sans connexion. Logiciel libre (GPL 3), réalisé en « vibe coding » avec Claude Opus 5.5.",
                            "Notivox reads your notifications and incoming calls with the Piper speech engine, entirely on the phone, offline. Free software (GPL 3), vibe-coded with Claude Opus 5.5.")
            }
        }
        VerticalScrollDecorator { }
    }
}
