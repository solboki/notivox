# Changelog

## 1.0.1 (2026-11-06)

- Fixed: headphones were never detected when the phone is not set to English, because `pactl` translates its output. Nothing was therefore read.
- Fixed: no sound on phones whose default audio output is `sink.null`. The voice is now sent by name to the headphones, or to the speaker.
- The log is written to `~/.cache/notivox/notivox.log`, since Sailfish does not let the user read the system journal. It is shown in the app and by `notivox-ctl log`.

## 1.0.0 (2026-11-06)

First release.

- Reads aloud the notifications of the apps you choose, only in headphones (Bluetooth or wired) by default.
- Announces incoming calls with the contact's name, repeated while the phone rings.
- Piper neural voices, downloaded from the app in more than fifty languages, with automatic detection of each message's language and an eSpeak NG fallback voice.
- Per-app settings: on or off, full text or title only, forced language.
- Master switch, timed pause, quiet hours by day and time.
- `notivox-ctl` command and `org.notivox.Control` D-Bus signals for the Situations app.
