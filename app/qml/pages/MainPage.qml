import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Page {
    id: page

    // Les fichiers du service ne sont relus que pendant que ces réglages
    // sont ouverts.
    Component.onCompleted: NV.watchers++
    Component.onDestruction: NV.watchers--

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: col.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem {
                text: NV.t("Options avancées", "Advanced options")
                onClicked: pageStack.push(Qt.resolvedUrl("AdvancedPage.qml"))
            }
            MenuItem {
                text: NV.t("Commandes pour Situations", "Commands for Situations")
                onClicked: pageStack.push(Qt.resolvedUrl("SituationsPage.qml"))
            }
            MenuItem {
                text: NV.t("Écouter un essai", "Play a test")
                enabled: NV.alive
                onClicked: NV.py.call("notivox_ui.test_lang", [NV.get(["language"], "fr")])
            }
        }

        Column {
            id: col
            width: parent.width

            PageHeader {
                title: NV.t("Notification vocale", "Voice notifications")
                description: "Notivox"
            }

            TextSwitch {
                id: master
                text: NV.t("Lire les notifications", "Read notifications aloud")
                description: statusText()
                checked: NV.st.enabled !== false
                automaticCheck: false
                onClicked: NV.py.call("notivox_ui.set_enabled", [!checked],
                                   function(s) { NV.st = s })

                function statusText() {
                    if (!NV.ready) return ""
                    if (!NV.alive)
                        return NV.t("Le service est arrêté. Ouvrez les options avancées (menu du haut) pour le démarrer.",
                                     "The service is stopped. Open the advanced options (top menu) to start it.")
                    if (NV.st.enabled === false)
                        return NV.t("Rien n'est lu.", "Nothing is read.")
                    if (NV.paused())
                        return NV.t("En pause jusqu'à ", "Paused until ") + NV.hhmm(NV.st.pause_until)
                    var s = NV.t("Sortie : ", "Output: ") + NV.outputName(NV.status.output)
                    if (NV.status.blocked)
                        s += " · " + NV.blockedName(NV.status.blocked)
                    return s
                }
            }

            Item { width: 1; height: Theme.paddingMedium }

            ComboBox {
                id: pauseBox
                visible: NV.st.enabled !== false
                label: NV.paused() ? NV.t("En pause", "Paused")
                                    : NV.t("Suspendre", "Pause")
                value: NV.paused() ? NV.hhmm(NV.st.pause_until)
                                    : NV.t("non", "no")
                menu: ContextMenu {
                    MenuItem {
                        text: NV.t("15 minutes", "15 minutes")
                        onClicked: NV.py.call("notivox_ui.pause", [15], function(s) { NV.st = s })
                    }
                    MenuItem {
                        text: NV.t("1 heure", "1 hour")
                        onClicked: NV.py.call("notivox_ui.pause", [60], function(s) { NV.st = s })
                    }
                    MenuItem {
                        text: NV.t("2 heures", "2 hours")
                        onClicked: NV.py.call("notivox_ui.pause", [120], function(s) { NV.st = s })
                    }
                    MenuItem {
                        text: NV.t("Jusqu'à demain 7 h", "Until 7 am")
                        onClicked: NV.py.call("notivox_ui.pause_until_morning", [7], function(s) { NV.st = s })
                    }
                    MenuItem {
                        text: NV.t("Reprendre maintenant", "Resume now")
                        visible: NV.paused()
                        onClicked: NV.py.call("notivox_ui.resume", [], function(s) { NV.st = s })
                    }
                }
            }

            // Aucune voix : on propose tout de suite d'en télécharger une.
            BackgroundItem {
                visible: NV.ready && NV.voices.length === 0
                width: parent.width
                height: noVoice.height + 2 * Theme.paddingMedium
                onClicked: pageStack.push(Qt.resolvedUrl("CatalogPage.qml"),
                                          { lang: NV.get(["language"], "fr") })
                Label {
                    id: noVoice
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * x
                    anchors.verticalCenter: parent.verticalCenter
                    wrapMode: Text.Wrap
                    color: Theme.highlightColor
                    text: NV.t("Aucune voix n'est installée. Touchez ici pour télécharger une voix française (environ 60 Mo).",
                                "No voice is installed. Tap here to download a voice (about 60 MB).")
                }
            }

            SectionHeader { text: NV.t("Réglages", "Settings") }

            NavItem {
                title: NV.t("Applications", "Apps")
                subtitle: appsSummary()
                page: "AppsPage.qml"
                function appsSummary() {
                    var n = 0, on = 0
                    var apps = NV.get(["apps"], {})
                    var names = {}
                    for (var a in NV.seen) names[a] = true
                    for (var b in apps) names[b] = true
                    var def = NV.get(["new_apps_default"], false)
                    for (var k in names) {
                        n++
                        var r = (apps[k] && apps[k].read !== undefined) ? apps[k].read : def
                        if (r) on++
                    }
                    if (n === 0)
                        return NV.t("Aucune notification reçue pour l'instant", "No notification received yet")
                    return on + " / " + n + NV.t(" lues", " read")
                }
            }
            NavItem {
                title: NV.t("Résumé vocal", "Spoken summary")
                subtitle: NV.get(["summary", "on_headset"], false)
                          ? NV.t("Lu à la connexion des écouteurs", "Read when headphones connect")
                          : NV.t("Sur demande", "On demand")
                page: "SummaryPage.qml"
            }
            NavItem {
                title: NV.t("Appels entrants", "Incoming calls")
                subtitle: NV.get(["calls", "enabled"], true)
                          ? NV.t("Nom de l'appelant annoncé", "Caller name announced")
                          : NV.t("Non annoncés", "Not announced")
                page: "CallsPage.qml"
            }
            NavItem {
                title: NV.t("Voix et langues", "Voices and languages")
                subtitle: NV.voices.length === 0 ? NV.t("Aucune voix installée", "No voice installed")
                          : NV.voices.length + NV.t(" voix installée(s)", " voice(s) installed")
                page: "VoicesPage.qml"
            }
            NavItem {
                title: NV.t("Plages de silence", "Quiet hours")
                subtitle: NV.get(["schedule", "enabled"], false)
                          ? (NV.status.quiet_hours ? NV.t("Actives, silence en cours", "On, quiet now")
                                                    : NV.t("Actives", "On"))
                          : NV.t("Désactivées", "Off")
                page: "SchedulePage.qml"
            }

            Label {
                visible: NV.status.last_error !== undefined && NV.status.last_error !== ""
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                topPadding: Theme.paddingLarge
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.errorColor
                text: NV.t("Dernière erreur : ", "Last error: ") + (NV.status.last_error || "")
            }
        }
        VerticalScrollDecorator { }
    }
}
