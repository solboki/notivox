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
            PageHeader { title: NV.t("Appels entrants", "Incoming calls") }

            TextSwitch {
                text: NV.t("Annoncer qui appelle", "Announce who is calling")
                description: NV.t("Pendant la sonnerie, le nom du contact est dit dans les écouteurs.",
                                   "While ringing, the contact name is spoken in the headphones.")
                checked: NV.get(["calls", "enabled"], true)
                automaticCheck: false
                onClicked: NV.setCfg(["calls", "enabled"], !checked)
            }

            TextSwitch {
                text: NV.t("Annoncer les numéros inconnus", "Announce unknown numbers")
                description: NV.t("Le numéro est lu quand il n'est pas dans le répertoire, ou « appel masqué ».",
                                   "The number is read when it is not in your contacts, or \"hidden number\".")
                checked: NV.get(["calls", "announce_unknown"], true)
                automaticCheck: false
                onClicked: NV.setCfg(["calls", "announce_unknown"], !checked)
            }

            TextSwitch {
                text: NV.t("Rallumer le casque Bluetooth pendant la sonnerie", "Wake the Bluetooth headset while ringing")
                description: NV.t("Pendant la sonnerie, Sailfish coupe le son du casque. Notivox le rallume le temps de l'annonce ; au décroché, la conversation passe dans le casque comme d'habitude.",
                                   "While ringing, Sailfish switches the headset sound off. Notivox switches it back on for the announcement; when you answer, the call goes to the headset as usual.")
                checked: NV.get(["calls", "bt_wakeup"], true)
                automaticCheck: false
                onClicked: NV.setCfg(["calls", "bt_wakeup"], !checked)
            }

            TextSwitch {
                text: NV.t("Haut-parleur si le casque est muet", "Speaker if the headset is silent")
                description: NV.t("Pendant la sonnerie, la plupart des casques Bluetooth ne reçoivent aucun son. Si le casque ne peut pas être rallumé, l'appel n'est pas annoncé ; avec cette option, le nom est dit sur le haut-parleur, audible par votre entourage.",
                                   "While ringing, most Bluetooth headsets receive no sound. If the headset cannot be woken, the call is not announced; with this option, the name is spoken on the loudspeaker, audible to people around you.")
                checked: NV.get(["calls", "speaker_fallback"], false)
                automaticCheck: false
                onClicked: NV.setCfg(["calls", "speaker_fallback"], !checked)
            }

            TextSwitch {
                text: NV.t("Respecter les plages de silence", "Obey quiet hours")
                description: NV.t("Si cette option est coupée, les appels sont annoncés même la nuit.",
                                   "When off, calls are announced even during quiet hours.")
                checked: NV.get(["calls", "obey_schedule"], false)
                automaticCheck: false
                onClicked: NV.setCfg(["calls", "obey_schedule"], !checked)
            }

            Slider {
                width: parent.width
                label: NV.t("Nombre d'annonces", "Number of announcements")
                minimumValue: 1; maximumValue: 6; stepSize: 1
                value: NV.get(["calls", "repeat"], 3)
                valueText: value
                onReleased: NV.setCfg(["calls", "repeat"], value)
            }
            Slider {
                width: parent.width
                label: NV.t("Intervalle entre deux annonces", "Interval between announcements")
                minimumValue: 3; maximumValue: 15; stepSize: 1
                value: NV.get(["calls", "interval"], 6)
                valueText: value + " s"
                onReleased: NV.setCfg(["calls", "interval"], value)
            }
            Slider {
                width: parent.width
                label: NV.t("Délai avant la première annonce", "Delay before the first announcement")
                minimumValue: 0; maximumValue: 5; stepSize: 0.5
                value: NV.get(["calls", "first_delay"], 0)
                valueText: value.toFixed(1) + " s"
                onReleased: NV.setCfg(["calls", "first_delay"], value)
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
                text: NV.t("Les annonces s'arrêtent dès que vous décrochez ou refusez l'appel. Avec des écouteurs filaires, elles arrivent dans les écouteurs. Avec un casque Bluetooth, le téléphone coupe le son du casque pendant la sonnerie ; l'option ci-dessus le rallume pour l'annonce. La sonnerie elle-même reste sur le haut-parleur : c'est une règle du système.",
                            "Announcements stop as soon as you answer or decline. With wired headphones they reach the headphones. With a Bluetooth headset the phone switches the headset sound off while ringing; the option above wakes it for the announcement. The ringtone itself stays on the loudspeaker: this is a system rule.")
            }
        }
        VerticalScrollDecorator { }
    }
}
