import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Page {
    id: page
    property string placeMessage: ""
    property bool searching: false

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
                text: NV.t("Le résumé annonce le nombre de notifications de la Vue Événements, puis, application par application, ce que vous avez choisi dans la page Applications : rien, le nombre, les titres ou tout le contenu.",
                           "The summary announces how many notifications the Events view holds, then, app by app, what you chose in the Apps page: nothing, the count, the titles or the full content.")
            }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: NV.t("Écouter le résumé", "Play the summary")
                enabled: NV.alive
                onClicked: NV.py.call("notivox_ui.summary", [true])
            }

            SectionHeader { text: NV.t("Introduction", "Introduction") }

            TextSwitch {
                text: NV.t("Annoncer la date et l'heure", "Announce the date and time")
                checked: NV.get(["summary", "date_time"], true)
                automaticCheck: false
                onClicked: NV.setCfg(["summary", "date_time"], !checked)
            }
            TextSwitch {
                id: weatherSwitch
                text: NV.t("Annoncer la météo", "Announce the weather")
                description: NV.t("Le temps et la température du lieu choisi, par exemple « Météo : nuageux, 17 degrés ». Demande une connexion à Internet (service Open-Meteo).",
                                  "The weather and temperature at the chosen place, for example \"Weather: cloudy, 17 degrees\". Needs an Internet connection (Open-Meteo service).")
                checked: NV.get(["summary", "weather"], false)
                automaticCheck: false
                onClicked: NV.setCfg(["summary", "weather"], !checked)
            }
            TextField {
                id: placeField
                width: parent.width
                visible: weatherSwitch.checked
                label: page.placeMessage !== "" ? page.placeMessage
                       : (NV.get(["summary", "place", "name"], "") || NV.t("Ville de la météo", "Weather town"))
                placeholderText: NV.t("Ville, par exemple Blois", "Town, for example Blois")
                text: ""
                enabled: !page.searching
                EnterKey.iconSource: "image://theme/icon-m-search"
                EnterKey.onClicked: {
                    page.searching = true
                    page.placeMessage = NV.t("Recherche…", "Searching…")
                    NV.py.call("notivox_ui.find_place", [text], function(name) {
                        page.searching = false
                        page.placeMessage = name !== "" ? name : NV.t("Lieu introuvable", "Place not found")
                        if (name !== "") { placeField.text = ""; NV.refresh() }
                        placeField.focus = false
                    })
                }
            }

            SectionHeader { text: NV.t("Lecture", "Reading") }

            TextSwitch {
                text: NV.t("Bips autour des notifications lues", "Beeps around the notifications read")
                description: NV.t("Un bip ouvre et ferme le bloc de chaque application, et sépare ses notifications. Sinon, une courte pause.",
                                  "A beep opens and closes each app's block, and separates its notifications. Otherwise, a short pause.")
                checked: NV.get(["summary", "beep"], true)
                automaticCheck: false
                onClicked: NV.setCfg(["summary", "beep"], !checked)
            }
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
                description: NV.t("Chaque notification lue en entier ou par son titre disparaît de la Vue Événements. Une lecture interrompue n'efface rien, et une notification seulement comptée reste en place.",
                                  "Each notification read in full or by its title is removed from the Events view. An interrupted reading clears nothing, and a notification only counted stays.")
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

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                topPadding: Theme.paddingLarge
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
                text: NV.t("Le bouton de cette page lit le résumé même sans écouteurs. Depuis Situations, « notivox-ctl events » ne le lit que dans les écouteurs, et « notivox-ctl events-speakers » le lit sur le haut-parleur s'il n'y a pas d'écouteurs.",
                           "The button on this page reads the summary even without headphones. From Situations, \"notivox-ctl events\" only reads it in headphones, and \"notivox-ctl events-speakers\" reads it on the speaker when there are no headphones.")
            }
        }
        VerticalScrollDecorator { }
    }
}
