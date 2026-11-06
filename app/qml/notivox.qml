import QtQuick 2.0
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import "pages"
import "cover"

ApplicationWindow {
    id: app

    // Données lues dans les fichiers du service
    property var cfg: ({})
    property var st: ({ enabled: true, pause_until: 0 })
    property var seen: ({})
    property var status: ({})
    property bool alive: false
    property var voices: []
    property var downloads: ({})
    property real now: 0
    property bool ready: false

    readonly property bool french: Qt.locale().name.indexOf("fr") === 0
    function t(fr, en) { return french ? fr : en }

    // Valeur d'un réglage, avec sa valeur par défaut si le service n'a pas
    // encore écrit le fichier.
    function get(path, def) {
        var node = cfg
        for (var i = 0; i < path.length; i++) {
            if (node === undefined || node === null || !(path[i] in node))
                return def
            node = node[path[i]]
        }
        return node
    }

    function setCfg(path, value) {
        py.call("notivox_ui.set_value", [path, value], function(c) { cfg = c })
    }

    function refresh() {
        py.call("notivox_ui.load", [], function(r) {
            cfg = r.config
            st = r.state
            seen = r.seen
            status = r.status
            alive = r.alive
            voices = r.voices
            downloads = r.downloads
            now = r.now
            ready = true
        })
    }

    function paused() { return st.pause_until && st.pause_until > now }

    function hhmm(ts) {
        var d = new Date(ts * 1000)
        return Qt.formatTime(d, "hh:mm")
    }

    function outputName(o) {
        if (o === "bluetooth") return t("écouteurs Bluetooth", "Bluetooth headphones")
        if (o === "wired") return t("écouteurs filaires", "wired headphones")
        if (o === "speaker") return t("haut-parleur du téléphone", "phone speaker")
        return t("inconnue", "unknown")
    }

    function blockedName(b) {
        var m = {
            "désactivé": t("lecture coupée", "reading off"),
            "en pause": t("en pause", "paused"),
            "plage de silence": t("plage de silence en cours", "quiet hours"),
            "appel en cours": t("appel en cours", "call in progress"),
            "pas d'écouteurs": t("pas d'écouteurs branchés", "no headphones"),
            "sortie audio inconnue": t("sortie audio non reconnue", "audio output unknown"),
            "profil silencieux": t("profil silencieux", "silent profile")
        }
        return m[b] || b
    }

    // Nom lisible d'une langue à partir de son code (fr, en…)
    function langName(code) {
        var names = {
            fr: "Français", en: "English", de: "Deutsch", es: "Español",
            it: "Italiano", pt: "Português", nl: "Nederlands", fi: "Suomi",
            sv: "Svenska", da: "Dansk", no: "Norsk", pl: "Polski",
            cs: "Čeština", ru: "Русский", uk: "Українська", ca: "Català",
            ro: "Română", hu: "Magyar", tr: "Türkçe", el: "Ελληνικά"
        }
        return names[code] || code
    }

    function installedLangs() {
        var seenL = {}, out = []
        for (var i = 0; i < voices.length; i++) {
            var l = voices[i].lang
            if (!seenL[l]) { seenL[l] = true; out.push(l) }
        }
        return out
    }

    Python {
        id: py
        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl("py"))
            setHandler("download", function(key, fraction, error) {
                var d = app.downloads
                if (fraction < 0) {
                    delete d[key]
                    app.downloadError = error
                } else if (fraction >= 1) {
                    delete d[key]
                } else {
                    d[key] = fraction
                }
                app.downloads = d
                app.downloadsChanged()
                if (fraction < 0 || fraction >= 1)
                    app.refresh()
            })
            importModule("notivox_ui", function() {
                app.refresh()
                py.call("notivox_ui.ensure_started", [], function() { app.refresh() })
            })
        }
        onError: console.log("python: " + traceback)
    }
    property string downloadError: ""

    Timer {
        interval: 4000
        repeat: true
        running: Qt.application.active && app.ready
        onTriggered: app.refresh()
    }

    initialPage: Component { MainPage { } }
    cover: Component { CoverPage { } }
    allowedOrientations: defaultAllowedOrientations
}
