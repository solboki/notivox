import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Page {
    id: page
    property var all: []
    property string filter: ""

    Component.onCompleted: NV.py.call("notivox_ui.languages", [], function(l) { page.all = l })

    SilicaListView {
        id: list
        anchors.fill: parent
        model: {
            var f = page.filter.toLowerCase(), out = []
            for (var i = 0; i < page.all.length; i++) {
                var l = page.all[i]
                if (!f || l.native.toLowerCase().indexOf(f) >= 0 ||
                    l.english.toLowerCase().indexOf(f) >= 0 || l.lang.indexOf(f) === 0)
                    out.push(l)
            }
            return out
        }
        header: Column {
            width: list.width
            PageHeader { title: NV.t("Choisir une langue", "Choose a language") }
            SearchField {
                width: parent.width
                placeholderText: NV.t("Rechercher", "Search")
                onTextChanged: page.filter = text
            }
        }
        delegate: BackgroundItem {
            width: list.width
            height: Theme.itemSizeSmall
            onClicked: pageStack.push(Qt.resolvedUrl("CatalogPage.qml"), { lang: modelData.lang })
            Label {
                x: Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 2 * x - countLabel.width
                truncationMode: TruncationMode.Fade
                text: modelData.native + (modelData.native !== modelData.english ? "  ·  " + modelData.english : "")
                color: highlighted ? Theme.highlightColor : Theme.primaryColor
            }
            Label {
                id: countLabel
                anchors {
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin
                    verticalCenter: parent.verticalCenter
                }
                text: modelData.count
                color: Theme.secondaryColor
            }
        }
        VerticalScrollDecorator { }
    }
}
