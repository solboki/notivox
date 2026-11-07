import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Page {
    id: page

    // Applications ayant déjà envoyé une notification ou réglées à la main,
    // triées par nom.
    function appNames() {
        var out = []
        for (var k in NV.effective) out.push(k)
        out.sort(function(x, y) { return x.toLowerCase() < y.toLowerCase() ? -1 : 1 })
        return out
    }

    Component.onCompleted: NV.watchers++
    Component.onDestruction: NV.watchers--

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
                        NV.py.call("notivox_ui.add_app", [d.name], function(c) { NV.cfg = c; NV.refresh() })
                    })
                }
            }
            MenuItem {
                text: NV.t("Tout ignorer dans le résumé", "Ignore all in the summary")
                onClicked: NV.py.call("notivox_ui.set_all_apps", ["summary", "ignore", page.appNames()],
                                      function(c) { NV.cfg = c; NV.refresh() })
            }
            MenuItem {
                text: NV.t("Tout ignorer à l'arrivée", "Ignore all on arrival")
                onClicked: NV.py.call("notivox_ui.set_all_apps", ["arrival", "ignore", page.appNames()],
                                      function(c) { NV.cfg = c; NV.refresh() })
            }
        }

        header: Column {
            width: list.width
            PageHeader { title: NV.t("Applications", "Apps") }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
                bottomPadding: Theme.paddingMedium
                text: NV.t("Pour chaque application, choisissez ce qui est lu à l'arrivée d'une notification et dans le résumé vocal. Une nouvelle application est ignorée, sauf Messages et les appels, lus en entier.",
                           "For each app, choose what is read when a notification arrives and in the spoken summary. A new app is ignored, except Messages and calls, read in full.")
            }
        }

        delegate: ListItem {
            id: item
            property var e: NV.effective[modelData] || {}
            contentHeight: Math.max(Theme.itemSizeMedium, texts.height + 2 * Theme.paddingSmall)
            onClicked: pageStack.push(Qt.resolvedUrl("AppPage.qml"), { appName: modelData })

            Column {
                id: texts
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                anchors.verticalCenter: parent.verticalCenter
                Label {
                    width: parent.width
                    text: modelData
                    truncationMode: TruncationMode.Fade
                    color: item.e.arrival === "ignore" && item.e.summary === "ignore"
                           ? (item.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor)
                           : (item.highlighted ? Theme.highlightColor : Theme.primaryColor)
                }
                Label {
                    width: parent.width
                    text: NV.t("Arrivée : ", "Arrival: ") + NV.arrivalName(item.e.arrival) +
                          (item.e.speaker && item.e.arrival !== "ignore" ? NV.t(" (haut-parleur)", " (speaker)") : "") +
                          NV.t(" · Résumé : ", " · Summary: ") + NV.summaryName(item.e.summary)
                    truncationMode: TruncationMode.Fade
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: item.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
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
