import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page

    // Liste des applications : celles qui ont déjà envoyé une notification
    // et celles réglées à la main, triées par nom.
    function appNames() {
        var names = {}
        var apps = app.get(["apps"], {})
        for (var a in app.seen) names[a] = true
        for (var b in apps) names[b] = true
        var out = []
        for (var k in names) out.push(k)
        out.sort(function(x, y) { return x.toLowerCase() < y.toLowerCase() ? -1 : 1 })
        return out
    }
    function setting(name) {
        var apps = app.get(["apps"], {})
        var s = apps[name] || {}
        return {
            read: s.read !== undefined ? s.read : app.get(["new_apps_default"], false),
            content: s.content || "full",
            lang: s.lang || "auto"
        }
    }

    SilicaListView {
        id: list
        anchors.fill: parent
        model: page.appNames()

        PullDownMenu {
            MenuItem {
                text: app.t("Ajouter une application", "Add an app")
                onClicked: {
                    var d = pageStack.push(Qt.resolvedUrl("AddAppDialog.qml"))
                    d.accepted.connect(function() {
                        py.call("notivox_ui.add_app", [d.name], function(c) { app.cfg = c })
                    })
                }
            }
            MenuItem {
                text: app.t("Tout couper", "Turn all off")
                onClicked: py.call("notivox_ui.set_all_apps", [false, page.appNames()],
                                   function(c) { app.cfg = c })
            }
            MenuItem {
                text: app.t("Tout lire", "Read all")
                onClicked: py.call("notivox_ui.set_all_apps", [true, page.appNames()],
                                   function(c) { app.cfg = c })
            }
        }

        header: Column {
            width: list.width
            PageHeader { title: app.t("Applications", "Apps") }
            TextSwitch {
                text: app.t("Lire les nouvelles applications", "Read new apps")
                description: app.t("Réglage appliqué à une application la première fois qu'elle envoie une notification.",
                                   "Applied to an app the first time it sends a notification.")
                checked: app.get(["new_apps_default"], false)
                automaticCheck: false
                onClicked: app.setCfg(["new_apps_default"], !checked)
            }
            SectionHeader { text: app.t("Applications connues", "Known apps") }
        }

        delegate: ListItem {
            id: item
            property var s: page.setting(modelData)
            contentHeight: Math.max(Theme.itemSizeMedium, texts.height + 2 * Theme.paddingSmall)
            onClicked: pageStack.push(Qt.resolvedUrl("AppPage.qml"), { appName: modelData })

            Column {
                id: texts
                x: Theme.horizontalPageMargin
                width: parent.width - x - sw.width - Theme.paddingMedium
                anchors.verticalCenter: parent.verticalCenter
                Label {
                    width: parent.width
                    text: modelData
                    truncationMode: TruncationMode.Fade
                    color: item.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Label {
                    width: parent.width
                    text: {
                        var c = item.s.content === "title" ? app.t("titre seulement", "title only")
                              : item.s.content === "app" ? app.t("nom de l'application seulement", "app name only")
                              : app.t("titre et texte", "title and text")
                        var seen = app.seen[modelData]
                        return seen && seen.sample ? c + " · " + seen.sample : c
                    }
                    truncationMode: TruncationMode.Fade
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: item.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
            }
            Switch {
                id: sw
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                checked: item.s.read
                automaticCheck: false
                onClicked: py.call("notivox_ui.set_app", [modelData, "read", !checked],
                                   function(c) { app.cfg = c })
            }
        }

        ViewPlaceholder {
            enabled: list.count === 0
            text: app.t("Aucune application pour l'instant", "No app yet")
            hintText: app.t("Les applications apparaissent ici dès leur première notification. Vous pouvez aussi en ajouter une par son nom.",
                            "Apps appear here with their first notification. You can also add one by name.")
        }
        VerticalScrollDecorator { }
    }
}
