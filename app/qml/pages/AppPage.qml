import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    property string appName

    property var s: {
        var apps = app.get(["apps"], {})
        var x = apps[appName] || {}
        return {
            read: x.read !== undefined ? x.read : app.get(["new_apps_default"], false),
            content: x.content || "full",
            lang: x.lang || "auto"
        }
    }
    property var langs: ["auto"].concat(app.installedLangs())

    function setApp(key, value) {
        py.call("notivox_ui.set_app", [appName, key, value], function(c) { app.cfg = c })
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: col.height

        PullDownMenu {
            MenuItem {
                text: app.t("Oublier cette application", "Forget this app")
                onClicked: Remorse.popupAction(page, app.t("Application oubliée", "App forgotten"), function() {
                    py.call("notivox_ui.forget_app", [page.appName], function() {
                        app.refresh()
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
                text: app.t("Lire ses notifications", "Read its notifications")
                checked: page.s.read
                automaticCheck: false
                onClicked: page.setApp("read", !checked)
            }

            ComboBox {
                label: app.t("Contenu lu", "Content read")
                enabled: page.s.read
                currentIndex: page.s.content === "title" ? 1 : page.s.content === "app" ? 2 : 0
                menu: ContextMenu {
                    MenuItem { text: app.t("Titre et texte", "Title and text"); onClicked: page.setApp("content", "full") }
                    MenuItem { text: app.t("Titre seulement", "Title only"); onClicked: page.setApp("content", "title") }
                    MenuItem { text: app.t("Nom de l'application seulement", "App name only"); onClicked: page.setApp("content", "app") }
                }
                description: app.t("« Titre seulement » annonce l'expéditeur sans lire le message.",
                                   "\"Title only\" announces the sender without reading the message.")
            }

            ComboBox {
                label: app.t("Langue", "Language")
                enabled: page.s.read
                currentIndex: Math.max(0, page.langs.indexOf(page.s.lang))
                menu: ContextMenu {
                    Repeater {
                        model: page.langs
                        MenuItem {
                            text: modelData === "auto" ? app.t("Automatique", "Automatic") : app.langName(modelData)
                            onClicked: page.setApp("lang", modelData)
                        }
                    }
                }
                description: app.t("En automatique, la langue est devinée pour chaque message.",
                                   "When automatic, the language is guessed for each message.")
            }

            SectionHeader {
                text: app.t("Dernière notification", "Last notification")
                visible: !!app.seen[page.appName]
            }
            Label {
                visible: !!app.seen[page.appName]
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.Wrap
                color: Theme.highlightColor
                font.pixelSize: Theme.fontSizeSmall
                text: {
                    var x = app.seen[page.appName]
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
