import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    id: cover
    property bool reading: app.st.enabled !== false && !app.paused()

    Column {
        anchors.centerIn: parent
        width: parent.width - 2 * Theme.paddingLarge
        spacing: Theme.paddingMedium
        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            source: "/usr/share/icons/hicolor/86x86/apps/notivox.png"
            opacity: cover.reading ? 1.0 : 0.4
        }
        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "Notivox"
        }
        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            font.pixelSize: Theme.fontSizeExtraSmall
            color: Theme.secondaryColor
            text: app.st.enabled === false ? app.t("Coupé", "Off")
                  : app.paused() ? app.t("Pause jusqu'à ", "Paused until ") + app.hhmm(app.st.pause_until)
                  : app.outputName(app.status.output)
        }
    }

    CoverActionList {
        CoverAction {
            iconSource: cover.reading ? "image://theme/icon-cover-pause" : "image://theme/icon-cover-play"
            onTriggered: {
                if (app.paused()) py.call("notivox_ui.resume", [], function(s) { app.st = s })
                else py.call("notivox_ui.set_enabled", [app.st.enabled === false], function(s) { app.st = s })
            }
        }
    }
}
