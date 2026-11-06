import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Page {
    id: page

    // Liste des applications : celles qui ont déjà envoyé une notification
    // et celles réglées à la main, triées par nom.
    function appNames() {
        var names = {}
        var apps = NV.get(["apps"], {})
        for (var a in NV.seen) names[a] = true
        for (var b in apps) names[b] = true
        var out = []
        for (var k in names) out.push(k)
        out.sort(function(x, y) { return x.toLowerCase() < y.toLowerCase() ? -1 : 1 })
        return out
    }
    function setting(name) {
        var apps = NV.get(["apps"], {})
        var s = apps[name] || {}
        return {
            read: s.read !== undefined ? s.read : NV.get(["new_apps_default"], false),
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
                text: NV.t("Ajouter une application", "Add an app")
                onClicked: {
                    var d = pageStack.push(Qt.resolvedUrl("AddAppDialog.qml"))
                    d.accepted.connect(function() {
                        NV.py.call("notivox_ui.add_app", [d.name], function(c) { NV.cfg = c })
                    })
                }
            }
            MenuItem {
                text: NV.t("Tout couper", "Turn all off")
                onClicked: NV.py.call("notivox_ui.set_all_apps", [false, page.appNames()],
                                   function(c) { NV.cfg = c })
            }
            MenuItem {
                text: NV.t("Tout lire", "Read all")
                onClicked: NV.py.call("notivox_ui.set_all_apps", [true, page.appNames()],
                                   function(c) { NV.cfg = c })
            }
        }

        header: Column {
            width: list.width
            PageHeader { title: NV.t("Applications", "Apps") }
            TextSwitch {
                text: NV.t("Lire les nouvelles applications", "Read new apps")
                description: NV.t("Réglage appliqué à une application la première fois qu'elle envoie une notification.",
                                   "Applied to an app the first time it sends a notification.")
                checked: NV.get(["new_apps_default"], false)
                automaticCheck: false
                onClicked: NV.setCfg(["new_apps_default"], !checked)
            }
            SectionHeader { text: NV.t("Applications connues", "Known apps") }
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
                        var c = item.s.content === "title" ? NV.t("titre seulement", "title only")
                              : item.s.content === "app" ? NV.t("nom de l'application seulement", "app name only")
                              : NV.t("titre et texte", "title and text")
                        var seen = NV.seen[modelData]
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
                onClicked: NV.py.call("notivox_ui.set_app", [modelData, "read", !checked],
                                   function(c) { NV.cfg = c })
            }
        }

        ViewPlaceholder {
            enabled: list.count === 0
            text: NV.t("Aucune application pour l'instant", "No app yet")
            hintText: NV.t("Les applications apparaissent ici dès leur première notification. Vous pouvez aussi en ajouter une par son nom.",
                            "Apps appear here with their first notification. You can also add one by name.")
        }
        VerticalScrollDecorator { }
    }
}
