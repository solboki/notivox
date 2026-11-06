import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: col.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem {
                text: app.t("Options avancées", "Advanced options")
                onClicked: pageStack.push(Qt.resolvedUrl("AdvancedPage.qml"))
            }
            MenuItem {
                text: app.t("Commandes pour Situations", "Commands for Situations")
                onClicked: pageStack.push(Qt.resolvedUrl("SituationsPage.qml"))
            }
            MenuItem {
                text: app.t("Écouter un essai", "Play a test")
                enabled: app.alive
                onClicked: py.call("notivox_ui.test_lang", [app.get(["language"], "fr")])
            }
        }

        Column {
            id: col
            width: parent.width

            PageHeader { title: "Notivox" }

            TextSwitch {
                id: master
                text: app.t("Lire les notifications", "Read notifications aloud")
                description: statusText()
                checked: app.st.enabled !== false
                automaticCheck: false
                onClicked: py.call("notivox_ui.set_enabled", [!checked],
                                   function(s) { app.st = s })

                function statusText() {
                    if (!app.ready) return ""
                    if (!app.alive)
                        return app.t("Le service est arrêté. Ouvrez les options avancées pour le démarrer.",
                                     "The service is stopped. Open the advanced options to start it.")
                    if (app.st.enabled === false)
                        return app.t("Rien n'est lu.", "Nothing is read.")
                    if (app.paused())
                        return app.t("En pause jusqu'à ", "Paused until ") + app.hhmm(app.st.pause_until)
                    var s = app.t("Sortie : ", "Output: ") + app.outputName(app.status.output)
                    if (app.status.blocked)
                        s += " · " + app.blockedName(app.status.blocked)
                    return s
                }
            }

            Item { width: 1; height: Theme.paddingMedium }

            ComboBox {
                id: pauseBox
                visible: app.st.enabled !== false
                label: app.paused() ? app.t("En pause", "Paused")
                                    : app.t("Suspendre", "Pause")
                value: app.paused() ? app.hhmm(app.st.pause_until)
                                    : app.t("non", "no")
                menu: ContextMenu {
                    MenuItem {
                        text: app.t("15 minutes", "15 minutes")
                        onClicked: py.call("notivox_ui.pause", [15], function(s) { app.st = s })
                    }
                    MenuItem {
                        text: app.t("1 heure", "1 hour")
                        onClicked: py.call("notivox_ui.pause", [60], function(s) { app.st = s })
                    }
                    MenuItem {
                        text: app.t("2 heures", "2 hours")
                        onClicked: py.call("notivox_ui.pause", [120], function(s) { app.st = s })
                    }
                    MenuItem {
                        text: app.t("Jusqu'à demain 7 h", "Until 7 am")
                        onClicked: py.call("notivox_ui.pause_until_morning", [7], function(s) { app.st = s })
                    }
                    MenuItem {
                        text: app.t("Reprendre maintenant", "Resume now")
                        visible: app.paused()
                        onClicked: py.call("notivox_ui.resume", [], function(s) { app.st = s })
                    }
                }
            }

            // Aucune voix : on propose tout de suite d'en télécharger une.
            BackgroundItem {
                visible: app.ready && app.voices.length === 0
                width: parent.width
                height: noVoice.height + 2 * Theme.paddingMedium
                onClicked: pageStack.push(Qt.resolvedUrl("CatalogPage.qml"),
                                          { lang: app.get(["language"], "fr") })
                Label {
                    id: noVoice
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2 * x
                    anchors.verticalCenter: parent.verticalCenter
                    wrapMode: Text.Wrap
                    color: Theme.highlightColor
                    text: app.t("Aucune voix n'est installée. Touchez ici pour télécharger une voix française (environ 60 Mo).",
                                "No voice is installed. Tap here to download a voice (about 60 MB).")
                }
            }

            SectionHeader { text: app.t("Réglages", "Settings") }

            NavItem {
                title: app.t("Applications", "Apps")
                subtitle: appsSummary()
                page: "AppsPage.qml"
                function appsSummary() {
                    var n = 0, on = 0
                    var apps = app.get(["apps"], {})
                    var names = {}
                    for (var a in app.seen) names[a] = true
                    for (var b in apps) names[b] = true
                    var def = app.get(["new_apps_default"], false)
                    for (var k in names) {
                        n++
                        var r = (apps[k] && apps[k].read !== undefined) ? apps[k].read : def
                        if (r) on++
                    }
                    if (n === 0)
                        return app.t("Aucune notification reçue pour l'instant", "No notification received yet")
                    return on + " / " + n + app.t(" lues", " read")
                }
            }
            NavItem {
                title: app.t("Appels entrants", "Incoming calls")
                subtitle: app.get(["calls", "enabled"], true)
                          ? app.t("Nom de l'appelant annoncé", "Caller name announced")
                          : app.t("Non annoncés", "Not announced")
                page: "CallsPage.qml"
            }
            NavItem {
                title: app.t("Voix et langues", "Voices and languages")
                subtitle: app.voices.length === 0 ? app.t("Aucune voix installée", "No voice installed")
                          : app.voices.length + app.t(" voix installée(s)", " voice(s) installed")
                page: "VoicesPage.qml"
            }
            NavItem {
                title: app.t("Plages de silence", "Quiet hours")
                subtitle: app.get(["schedule", "enabled"], false)
                          ? (app.status.quiet_hours ? app.t("Actives, silence en cours", "On, quiet now")
                                                    : app.t("Actives", "On"))
                          : app.t("Désactivées", "Off")
                page: "SchedulePage.qml"
            }

            Label {
                visible: app.status.last_error !== undefined && app.status.last_error !== ""
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                topPadding: Theme.paddingLarge
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.errorColor
                text: app.t("Dernière erreur : ", "Last error: ") + (app.status.last_error || "")
            }
        }
        VerticalScrollDecorator { }
    }
}
