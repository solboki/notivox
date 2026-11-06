import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Page {
    id: page
    property var rules: NV.get(["schedule", "rules"], [])

    function dayNames() {
        return NV.french ? ["lun", "mar", "mer", "jeu", "ven", "sam", "dim"]
                          : ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    }
    function daysText(days) {
        if (!days || days.length === 7) return NV.t("tous les jours", "every day")
        var d = days.slice().sort()
        if (d.join() === "0,1,2,3,4") return NV.t("du lundi au vendredi", "weekdays")
        if (d.join() === "5,6") return NV.t("le week-end", "weekends")
        var n = dayNames(), out = []
        for (var i = 0; i < d.length; i++) out.push(n[d[i]])
        return out.join(" ")
    }
    function save(list) {
        NV.py.call("notivox_ui.set_rules", [list], function(c) { NV.cfg = c })
    }
    function edit(index) {
        var r = index >= 0 ? page.rules[index]
                           : { days: [0, 1, 2, 3, 4, 5, 6], start: "22:00", end: "07:00" }
        var d = pageStack.push(Qt.resolvedUrl("RuleDialog.qml"),
                               { start: r.start, end: r.end, days: r.days.slice() })
        d.accepted.connect(function() {
            var list = page.rules.slice()
            var nr = { days: d.days, start: d.start, end: d.end }
            if (index >= 0) list[index] = nr
            else list.push(nr)
            page.save(list)
        })
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: col.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem {
                text: NV.t("Ajouter une plage", "Add a period")
                onClicked: page.edit(-1)
            }
        }

        Column {
            id: col
            width: parent.width
            PageHeader { title: NV.t("Plages de silence", "Quiet hours") }

            TextSwitch {
                text: NV.t("Appliquer les plages de silence", "Use quiet hours")
                description: NV.t("Pendant ces plages, aucune notification n'est lue. Les appels suivent leur propre réglage.",
                                   "During these periods no notification is read. Calls follow their own setting.")
                checked: NV.get(["schedule", "enabled"], false)
                automaticCheck: false
                onClicked: NV.setCfg(["schedule", "enabled"], !checked)
            }

            SectionHeader { text: NV.t("Plages", "Periods") }

            Repeater {
                model: page.rules
                ListItem {
                    id: ri
                    contentHeight: Theme.itemSizeMedium
                    onClicked: page.edit(index)
                    menu: ContextMenu {
                        MenuItem {
                            text: NV.t("Modifier", "Edit")
                            onClicked: page.edit(index)
                        }
                        MenuItem {
                            text: NV.t("Supprimer", "Delete")
                            onClicked: {
                                var i = index
                                ri.remorseDelete(function() {
                                    var list = page.rules.slice()
                                    list.splice(i, 1)
                                    page.save(list)
                                })
                            }
                        }
                    }
                    Column {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2 * x
                        anchors.verticalCenter: parent.verticalCenter
                        Label {
                            text: modelData.start + " → " + modelData.end
                            color: ri.highlighted ? Theme.highlightColor : Theme.primaryColor
                        }
                        Label {
                            text: page.daysText(modelData.days)
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: Theme.secondaryColor
                        }
                    }
                }
            }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                topPadding: Theme.paddingLarge
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
                text: NV.t("Une plage qui passe minuit, par exemple de 22:00 à 07:00, compte pour le jour où elle commence. Pour une coupure ponctuelle, utilisez plutôt « Suspendre » sur la page d'accueil, ou l'application Situations.",
                            "A period crossing midnight, such as 22:00 to 07:00, belongs to the day it starts. For a one-off break, use \"Pause\" on the main page, or the Situations NV.")
            }
        }
        VerticalScrollDecorator { }
    }
}
