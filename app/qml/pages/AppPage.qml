import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Page {
    id: page
    property string appName

    property var s: {
        var apps = NV.get(["apps"], {})
        var x = apps[appName] || {}
        return {
            read: x.read !== undefined ? x.read : NV.get(["new_apps_default"], false),
            content: x.content || "full",
            lang: x.lang || "auto"
        }
    }
    property var langs: ["auto"].concat(NV.installedLangs())

    function setApp(key, value) {
        NV.py.call("notivox_ui.set_app", [appName, key, value], function(c) { NV.cfg = c })
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: col.height

        PullDownMenu {
            MenuItem {
                text: NV.t("Oublier cette application", "Forget this app")
                onClicked: Remorse.popupAction(page, NV.t("Application oubliée", "App forgotten"), function() {
                    NV.py.call("notivox_ui.forget_app", [page.appName], function() {
                        NV.refresh()
                        pageStack.pop()
                    })
                })
            }
        }

        Column {
            id: col
            width: parent.width
            PageHeader { title: page.appName }

            TextSwitch {
                text: NV.t("Lire ses notifications", "Read its notifications")
                checked: page.s.read
                automaticCheck: false
                onClicked: page.setApp("read", !checked)
            }

            ComboBox {
                label: NV.t("Contenu lu", "Content read")
                enabled: page.s.read
                currentIndex: page.s.content === "title" ? 1 : page.s.content === "app" ? 2 : 0
                menu: ContextMenu {
                    MenuItem { text: NV.t("Titre et texte", "Title and text"); onClicked: page.setApp("content", "full") }
                    MenuItem { text: NV.t("Titre seulement", "Title only"); onClicked: page.setApp("content", "title") }
                    MenuItem { text: NV.t("Nom de l'application seulement", "App name only"); onClicked: page.setApp("content", "app") }
                }
                description: NV.t("« Titre seulement » annonce l'expéditeur sans lire le message.",
                                   "\"Title only\" announces the sender without reading the message.")
            }

            ComboBox {
                label: NV.t("Langue", "Language")
                enabled: page.s.read
                currentIndex: Math.max(0, page.langs.indexOf(page.s.lang))
                menu: ContextMenu {
                    Repeater {
                        model: page.langs
                        MenuItem {
                            text: modelData === "auto" ? NV.t("Automatique", "Automatic") : NV.langName(modelData)
                            onClicked: page.setApp("lang", modelData)
                        }
                    }
                }
                description: NV.t("En automatique, la langue est devinée pour chaque message.",
                                   "When automatic, the language is guessed for each message.")
            }

            ComboBox {
                property var modes: ["family", "none", "count", "full"]
                property string cur: {
                    var a = NV.get(["apps"], {})[page.appName]
                    return a && a.summary ? a.summary : "family"
                }
                label: NV.t("Dans le résumé", "In the summary")
                currentIndex: Math.max(0, modes.indexOf(cur))
                menu: ContextMenu {
                    MenuItem { text: NV.t("Comme sa famille", "Like its family"); onClicked: page.setApp("summary", "family") }
                    MenuItem { text: NV.t("Ne pas annoncer", "Do not announce"); onClicked: page.setApp("summary", "none") }
                    MenuItem { text: NV.t("Annoncer le nombre", "Announce the count"); onClicked: page.setApp("summary", "count") }
                    MenuItem { text: NV.t("Tout lire", "Read everything"); onClicked: page.setApp("summary", "full") }
                }
                description: NV.t("Le résumé de la Vue Événements traite chaque application selon sa famille (messages, courriels…), sauf réglage contraire ici.",
                                  "The Events view summary handles each app according to its family (messages, emails…), unless set otherwise here.")
            }

            SectionHeader {
                text: NV.t("Dernière notification", "Last notification")
                visible: !!NV.seen[page.appName]
            }
            Label {
                visible: !!NV.seen[page.appName]
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.Wrap
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeSmall
                text: {
                    var x = NV.seen[page.appName]
                    if (!x) return ""
                    var d = new Date(x.last * 1000)
                    return x.sample + "\n" + Qt.formatDateTime(d, "d MMM hh:mm") +
                           (x.category ? " · " + x.category : "")
                }
            }
        }
        VerticalScrollDecorator { }
    }
}
