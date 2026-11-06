# Changelog

## 1.1.1 (2026-11-06)

- The Settings entry sits right after "Sounds and feedback". Its position is computed at installation from that entry's own order number.
- New line icon in the style of the Sailfish theme: it is installed as a theme icon, so the system draws it black on light ambiences and white on dark ones, at the same size as the other icons.

## 1.1.0 (2026-11-06)

- The settings are no longer an app with its own icon: they are a page of the Settings app, named "Voice notifications" in the system language (Notification vocale, Sprachbenachrichtigung, etc.).
- The service starts with the phone by default. Switching it off in the advanced options keeps it stopped, even after a restart, until it is switched on again.

## 1.0.6 (2026-11-06)

- Fixed: on recent Sailfish versions, calls were announced with the number instead of the caller's name. The address book no longer stores the display name in its `Contacts` table; Notivox now looks for it, in order, in the display labels, the first and last names, the nickname and the organisation.
- Leftover temporary sound files are removed when the service starts.

## 1.0.5 (2026-11-06)

- Faster call announcements. The caller is looked up and the sentence synthesised as soon as the call arrives, while the headset is being woken. The main language's voice stays loaded, so no time is lost loading the model. The fixed delay before the first announcement is removed (settings saved by earlier versions are updated). Sentences already spoken for a caller are kept, so a repeated call is announced at once.
- New `notivox-ctl contact NUMBER` command, to check why a caller's name is not found in the address book.

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
