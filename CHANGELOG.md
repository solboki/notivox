# Changelog

## 1.0.4 (2026-11-06)

- Incoming calls are now announced in Bluetooth headsets. While the phone rings, Sailfish sets the headset's audio profile to "off" and opens nothing else until the call is answered. Notivox switches the headset back to its music profile (A2DP) for the announcement; when you answer, the system moves it to the call profile by itself, as before. This can be turned off in the Incoming calls page.

## 1.0.3 (2026-11-06)

- Fixed: calls were announced on the loudspeaker. While the phone rings, Sailfish switches a Bluetooth headset to its call mode, whose audio only opens when the call is answered: the headset is still connected but receives no sound, and everything plays on the loudspeaker. Notivox now trusts only the audio outputs that actually exist, and stays silent in that case.
- New option in the Incoming calls page: announce on the loudspeaker when the headset cannot receive sound (off by default).

## 1.0.2 (2026-11-06)

- Fixed: incoming calls were announced on the phone's loudspeaker instead of the headphones. The call announcement used the ringtone's stream type, which Sailfish always plays on the loudspeaker; it now uses the same stream as notifications. Settings saved by earlier versions are updated automatically.
- The Voices page has a visible "Download another voice" entry, in addition to the pull-down menu.

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
