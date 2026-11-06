import QtQuick 2.0
import Sailfish.Silica 1.0

// Ligne de menu menant à une sous-page : titre et résumé du réglage.
BackgroundItem {
    property alias title: titleLabel.text
    property alias subtitle: subLabel.text
    property string page

    width: parent ? parent.width : 0
    height: Math.max(Theme.itemSizeMedium, texts.height + 2 * Theme.paddingMedium)
    onClicked: pageStack.push(Qt.resolvedUrl(page))

    Column {
        id: texts
        x: Theme.horizontalPageMargin
        width: parent.width - 2 * x - arrow.width
        anchors.verticalCenter: parent.verticalCenter
        Label {
            id: titleLabel
            width: parent.width
            truncationMode: TruncationMode.Fade
            color: highlighted ? Theme.highlightColor : Theme.primaryColor
        }
        Label {
            id: subLabel
            width: parent.width
            wrapMode: Text.Wrap
            font.pixelSize: Theme.fontSizeExtraSmall
            color: highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
        }
    }
    Icon {
        id: arrow
        anchors {
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
            verticalCenter: parent.verticalCenter
        }
        source: "image://theme/icon-m-right"
    }
}
