import QtQuick 2.0
import Sailfish.Silica 1.0
import ".."

Page {
    id: page
    property string lang
    property var items: []

    function reload() {
        NV.py.call("notivox_ui.catalog", [lang], function(l) { page.items = l })
    }
    Component.onCompleted: reload()

    Connections {
        target: NV
        onVoicesChanged: page.reload()
    }

    SilicaListView {
        id: list
        anchors.fill: parent
        model: page.items
        header: Column {
            width: list.width
            PageHeader {
                title: NV.langName(page.lang)
                description: NV.t("Voix Piper à télécharger", "Piper voices to download")
            }
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryHighlightColor
                bottomPadding: Theme.paddingMedium
                text: NV.t("« medium » donne la voix la plus naturelle ; « low » est plus légère et plus rapide. Le téléchargement vient du dépôt public des voix Piper.",
                            "\"medium\" sounds most natural; \"low\" is lighter and faster. Downloads come from the public Piper voices repository.")
            }
            Label {
                visible: NV.downloadError !== ""
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.Wrap
                color: Theme.errorColor
                font.pixelSize: Theme.fontSizeExtraSmall
                text: NV.t("Échec du téléchargement : ", "Download failed: ") + NV.downloadError
            }
        }
        delegate: ListItem {
            id: li
            property bool busy: NV.downloads[modelData.key] !== undefined
            contentHeight: Theme.itemSizeMedium + (busy ? bar.height : 0)
            onClicked: {
                if (modelData.installed)
                    NV.py.call("notivox_ui.test_voice", [modelData.key])
                else if (!busy) {
                    NV.downloadError = ""
                    NV.py.call("notivox_ui.download", [modelData.key])
                    var d = NV.downloads
                    d[modelData.key] = 0
                    NV.downloads = d
                    NV.downloadsChanged()
                }
            }
            Column {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                anchors.verticalCenter: parent.verticalCenter
                Label {
                    width: parent.width
                    truncationMode: TruncationMode.Fade
                    text: modelData.name + " · " + modelData.country
                    color: li.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Label {
                    width: parent.width
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: modelData.installed ? Theme.highlightColor : Theme.secondaryColor
                    text: modelData.quality + " · " + Math.round(modelData.size / 1048576) + NV.t(" Mo", " MB") +
                          (modelData.speakers > 1 ? " · " + modelData.speakers + NV.t(" voix", " speakers") : "") +
                          (modelData.installed ? NV.t(" · installée, touchez pour écouter", " · installed, tap to listen")
                                               : li.busy ? "" : NV.t(" · touchez pour télécharger", " · tap to download"))
                }
                ProgressBar {
                    id: bar
                    visible: li.busy
                    width: parent.width
                    leftMargin: 0; rightMargin: 0
                    minimumValue: 0; maximumValue: 1
                    value: NV.downloads[modelData.key] || 0
                }
            }
        }
        VerticalScrollDecorator { }
    }
}
