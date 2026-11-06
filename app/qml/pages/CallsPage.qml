import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    SilicaFlickable {
        anchors.fill: parent
        contentHeight: col.height + Theme.paddingLarge

        Column {
            id: col
            width: parent.width
            PageHeader { title: app.t("Appels entrants", "Incoming calls") }

            TextSwitch {
                text: app.t("Annoncer qui appelle", "Announce who is calling")
                description: app.t("Pendant la sonnerie, le nom du contact est dit dans les écouteurs.",
                                   "While ringing, the contact name is spoken in the headphones.")
                checked: app.get(["calls", "enabled"], true)
                automaticCheck: false
                onClicked: app.setCfg(["calls", "enabled"], !checked)
            }

            TextSwitch {
                text: app.t("Annoncer les numéros inconnus", "Announce unknown numbers")
                description: app.t("Le numéro est lu quand il n'est pas dans le répertoire, ou « appel masqué ».",
                                   "The number is read when it is not in your contacts, or \"hidden number\".")
                checked: app.get(["calls", "announce_unknown"], true)
                automaticCheck: false
                onClicked: app.setCfg(["calls", "announce_unknown"], !checked)
            }

            TextSwitch {
                text: app.t("Respecter les plages de silence", "Obey quiet hours")
                description: app.t("Si cette option est coupée, les appels sont annoncés même la nuit.",
                                   "When off, calls are announced even during quiet hours.")
                checked: app.get(["calls", "obey_schedule"], false)
                automaticCheck: false
                onClicked: app.setCfg(["calls", "obey_schedule"], !checked)
            }

            Slider {
                width: parent.width
                label: app.t("Nombre d'annonces", "Number of announcements")
                minimumValue: 1; maximumValue: 6; stepSize: 1
                value: app.get(["calls", "repeat"], 3)
                valueText: value
                onReleased: app.setCfg(["calls", "repeat"], value)
            }
            Slider {
                width: parent.width
                label: app.t("Intervalle entre deux annonces", "Interval between announcements")
                minimumValue: 3; maximumValue: 15; stepSize: 1
                value: app.get(["calls", "interval"], 6)
                valueText: value + " s"
                onReleased: app.setCfg(["calls", "interval"], value)
            }
            Slider {
                width: parent.width
                label: app.t("Délai avant la première annonce", "Delay before the first announcement")
                minimumValue: 0; maximumValue: 5; stepSize: 0.5
                value: app.get(["calls", "first_delay"], 1.5)
                valueText: value.toFixed(1) + " s"
                onReleased: app.setCfg(["calls", "first_delay"], value)
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
                text: app.t("Les annonces s'arrêtent dès que vous décrochez ou refusez l'appel. Comme les notifications, elles ne passent que par les écouteurs si cette option est active.",
                            "Announcements stop as soon as you answer or decline. Like notifications, they only go to headphones when that option is on.")
            }
        }
        VerticalScrollDecorator { }
    }
}
