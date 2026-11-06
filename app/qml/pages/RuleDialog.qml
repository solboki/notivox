import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    id: dlg
    property string start: "22:00"
    property string end: "07:00"
    property var days: [0, 1, 2, 3, 4, 5, 6]
    canAccept: days.length > 0

    function pick(which) {
        var v = which === "start" ? start : end
        var p = v.split(":")
        var d = pageStack.push("Sailfish.Silica.TimePickerDialog", {
            hour: parseInt(p[0], 10), minute: parseInt(p[1], 10),
            hourMode: DateTime.TwentyFourHours
        })
        d.accepted.connect(function() {
            var s = (d.hour < 10 ? "0" : "") + d.hour + ":" + (d.minute < 10 ? "0" : "") + d.minute
            if (which === "start") dlg.start = s
            else dlg.end = s
        })
    }
    function toggleDay(i) {
        var list = days.slice()
        var k = list.indexOf(i)
        if (k >= 0) list.splice(k, 1)
        else list.push(i)
        list.sort()
        days = list
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: col.height + Theme.paddingLarge
    Column {
        id: col
        width: parent.width
        DialogHeader { acceptText: app.t("Enregistrer", "Save") }

        ValueButton {
            label: app.t("Début", "Start")
            value: dlg.start
            onClicked: dlg.pick("start")
        }
        ValueButton {
            label: app.t("Fin", "End")
            value: dlg.end
            onClicked: dlg.pick("end")
        }

        SectionHeader { text: app.t("Jours", "Days") }

        Repeater {
            model: app.french ? ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"]
                              : ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
            TextSwitch {
                text: modelData
                checked: dlg.days.indexOf(index) >= 0
                automaticCheck: false
                onClicked: dlg.toggleDay(index)
            }
        }
    }
        VerticalScrollDecorator { }
    }
}
