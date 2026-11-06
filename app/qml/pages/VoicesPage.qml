import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    id: page
    property var langs: app.installedLangs()
    property var uiLangs: ["fr", "en", "de", "es", "it", "pt", "nl", "fi", "sv", "pl", "ru"]

    // Voix utilisée pour une langue : celle choisie, sinon la première.
    function voiceFor(lang) {
        var want = app.get(["voices", lang], "")
        var first = ""
        for (var i = 0; i < app.voices.length; i++) {
            var v = app.voices[i]
            if (v.lang !== lang) continue
            if (v.key === want) return want
            if (!first) first = v.key
        }
        return first
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: col.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem {
                text: app.t("Télécharger une voix", "Download a voice")
                onClicked: pageStack.push(Qt.resolvedUrl("LanguagesPage.qml"))
            }
        }

        Column {
            id: col
            width: parent.width
            PageHeader { title: app.t("Voix et langues", "Voices and languages") }

            ComboBox {
                label: app.t("Langue principale", "Main language")
                description: app.t("Langue des annonces d'appel et des textes trop courts pour être reconnus.",
                                   "Language of call announcements and of texts too short to be recognised.")
                currentIndex: Math.max(0, page.uiLangs.indexOf(app.get(["language"], "fr")))
                menu: ContextMenu {
                    Repeater {
                        model: page.uiLangs
                        MenuItem {
                            text: app.langName(modelData)
                            onClicked: app.setCfg(["language"], modelData)
                        }
                    }
                }
            }

            TextSwitch {
                text: app.t("Reconnaître la langue de chaque message", "Detect the language of each message")
                description: app.t("Un message en anglais est lu par une voix anglaise, si elle est installée.",
                                   "A message in English is read by an English voice, if installed.")
                checked: app.get(["detect_language"], true)
                automaticCheck: false
                onClicked: app.setCfg(["detect_language"], !checked)
            }
            TextSwitch {
                text: app.t("Voix de secours eSpeak", "eSpeak fallback voice")
                description: app.t("Pour une langue sans voix Piper installée, utiliser la voix eSpeak, plus robotique mais disponible dans plus de cent langues.",
                                   "For a language without a Piper voice, use the eSpeak voice: more robotic, but available in over a hundred languages.")
                checked: app.get(["espeak_fallback"], true)
                automaticCheck: false
                onClicked: app.setCfg(["espeak_fallback"], !checked)
            }

            Slider {
                width: parent.width
                label: app.t("Vitesse", "Speed")
                minimumValue: 0.6; maximumValue: 1.8; stepSize: 0.05
                value: app.get(["speed"], 1.0)
                valueText: Math.round(value * 100) + " %"
                onReleased: app.setCfg(["speed"], Math.round(value * 100) / 100)
            }
            Slider {
                width: parent.width
                label: app.t("Volume de la voix", "Voice volume")
                minimumValue: 20; maximumValue: 150; stepSize: 5
                value: app.get(["volume"], 100)
                valueText: value + " %"
                onReleased: app.setCfg(["volume"], value)
            }

            SectionHeader { text: app.t("Voix installées", "Installed voices") }

            BackgroundItem {
                width: parent.width
                height: Theme.itemSizeMedium
                onClicked: pageStack.push(Qt.resolvedUrl("LanguagesPage.qml"))
                Icon {
                    id: dlIcon
                    x: Theme.horizontalPageMargin
                    anchors.verticalCenter: parent.verticalCenter
                    source: "image://theme/icon-m-add"
                    highlighted: parent.highlighted
                }
                Label {
                    anchors {
                        left: dlIcon.right
                        leftMargin: Theme.paddingMedium
                        right: parent.right
                        rightMargin: Theme.horizontalPageMargin
                        verticalCenter: parent.verticalCenter
                    }
                    truncationMode: TruncationMode.Fade
                    text: app.t("Télécharger une autre voix", "Download another voice")
                    color: parent.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
            }

            Label {
                visible: app.voices.length === 0
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                wrapMode: Text.Wrap
                color: Theme.secondaryHighlightColor
                text: app.t("Aucune voix. Tirez le menu vers le bas pour en télécharger.",
                            "No voice. Pull down the menu to download one.")
            }

            Repeater {
                model: app.voices
                ListItem {
                    id: vi
                    property bool isDefault: page.voiceFor(modelData.lang) === modelData.key
                    contentHeight: Theme.itemSizeMedium
                    onClicked: py.call("notivox_ui.test_voice", [modelData.key])
                    menu: ContextMenu {
                        MenuItem {
                            text: app.t("Écouter", "Listen")
                            onClicked: py.call("notivox_ui.test_voice", [modelData.key])
                        }
                        MenuItem {
                            text: app.t("Voix par défaut pour cette langue", "Default voice for this language")
                            visible: !vi.isDefault
                            onClicked: app.setCfg(["voices", modelData.lang], modelData.key)
                        }
                        MenuItem {
                            text: app.t("Supprimer", "Delete")
                            onClicked: vi.remorseDelete(function() {
                                py.call("notivox_ui.delete_voice", [modelData.key], function() { app.refresh() })
                            })
                        }
                    }
                    Column {
                        x: Theme.horizontalPageMargin
                        width: parent.width - 2 * x
                        anchors.verticalCenter: parent.verticalCenter
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            text: modelData.native + " · " + modelData.name + (vi.isDefault ? "  ✓" : "")
                            color: vi.highlighted ? Theme.highlightColor : Theme.primaryColor
                        }
                        Label {
                            width: parent.width
                            truncationMode: TruncationMode.Fade
                            font.pixelSize: Theme.fontSizeExtraSmall
                            color: Theme.secondaryColor
                            text: (modelData.country ? modelData.country + " · " : "") +
                                  modelData.quality + " · " + Math.round(modelData.size / 1048576) + app.t(" Mo", " MB")
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
                text: app.t("Touchez une voix pour l'entendre (sur la sortie active, même sans écouteurs). Appui long pour la choisir par défaut ou la supprimer.",
                            "Tap a voice to hear it (on the current output, even without headphones). Long press to make it the default or delete it.")
            }
        }
        VerticalScrollDecorator { }
    }
}
