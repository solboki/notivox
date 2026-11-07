import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Page {
    id: page
    property string appName

    property string arrival: NV.appCfg(appName, "arrival")
    property string summary: NV.appCfg(appName, "summary")
    property bool speaker: NV.appCfg(appName, "speaker")
    property string lang: NV.appCfg(appName, "lang")
    property var langs: ["auto"].concat(NV.installedLangs())

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: col.height + Theme.paddingLarge

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

            SectionHeader { text: NV.t("À l'arrivée d'une notification", "When a notification arrives") }

            ComboBox {
                property var modes: ["ignore", "titles", "full"]
                label: NV.t("Lecture", "Reading")
                currentIndex: Math.max(0, modes.indexOf(page.arrival))
                menu: ContextMenu {
                    MenuItem { text: NV.t("Ignorer", "Ignore"); onClicked: NV.setApp(page.appName, "arrival", "ignore") }
                    MenuItem { text: NV.t("Lire les titres", "Read the titles"); onClicked: NV.setApp(page.appName, "arrival", "titles") }
                    MenuItem { text: NV.t("Tout lire", "Read everything"); onClicked: NV.setApp(page.appName, "arrival", "full") }
                }
                description: NV.t("« Lire les titres » annonce l'expéditeur ou l'objet, sans le message.",
                                  "\"Read the titles\" announces the sender or subject, without the message.")
            }
            TextSwitch {
                text: NV.t("Lire sur le haut-parleur sans écouteurs", "Read on the speaker without headphones")
                description: NV.t("Sinon, les notifications de cette application ne sont lues que dans les écouteurs.",
                                  "Otherwise this app's notifications are only read in headphones.")
                enabled: page.arrival !== "ignore"
                checked: page.speaker
                automaticCheck: false
                onClicked: NV.setApp(page.appName, "speaker", !checked)
            }

            SectionHeader { text: NV.t("Dans le résumé vocal", "In the spoken summary") }

            ComboBox {
                property var modes: ["ignore", "count", "titles", "full"]
                label: NV.t("Lecture", "Reading")
                currentIndex: Math.max(0, modes.indexOf(page.summary))
                menu: ContextMenu {
                    MenuItem { text: NV.t("Ignorer", "Ignore"); onClicked: NV.setApp(page.appName, "summary", "ignore") }
                    MenuItem { text: NV.t("Indiquer le nombre", "Give the count"); onClicked: NV.setApp(page.appName, "summary", "count") }
                    MenuItem { text: NV.t("Lire les titres", "Read the titles"); onClicked: NV.setApp(page.appName, "summary", "titles") }
                    MenuItem { text: NV.t("Tout lire", "Read everything"); onClicked: NV.setApp(page.appName, "summary", "full") }
                }
            }

            SectionHeader { text: NV.t("Voix", "Voice") }

            ComboBox {
                label: NV.t("Langue", "Language")
                enabled: page.arrival !== "ignore" || page.summary === "titles" || page.summary === "full"
                currentIndex: Math.max(0, page.langs.indexOf(page.lang))
                menu: ContextMenu {
                    Repeater {
                        model: page.langs
                        MenuItem {
                            text: modelData === "auto" ? NV.t("Automatique", "Automatic") : NV.langName(modelData)
                            onClicked: NV.setApp(page.appName, "lang", modelData)
                        }
                    }
                }
                description: NV.t("En automatique, la langue est devinée pour chaque message.",
                                  "When automatic, the language is guessed for each message.")
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
