# Changelog

## 1.7.0 (2026-11-07, not published)

- Music and podcasts no longer play under the voice. When Notivox starts speaking (a notification or the summary), the players that are playing are paused; they resume when it falls silent. Audio streams that cannot be paused (some Android apps) are muted instead. During a summary, playback is paused once and resumed once, at the end. Can be turned off in the advanced options.
- Headset button: a press while Notivox speaks stops it, and the playback it had paused resumes. If the press restarted a player that was not playing before, that player is paused again.

## 1.6.1 (2026-11-07, not published)

- Headset button, second approach. Sailfish does not hand the button to Notivox: it sends the command to another player, usually the first one started (a podcast app in the test). While it speaks, Notivox now watches the commands sent to media players; when one passes, it stops reading and, if the press restarted that player, pauses it again within a fraction of a second.

## 1.6.0 (2026-11-07, not published)

- A short press on the headset's play/pause button stops the reading in progress, including the rest of the summary; "next track" skips to the next notification. While it speaks, Notivox presents itself to Sailfish as a media player (MPRIS), and withdraws as soon as it falls silent, so the button goes back to the music player. If music is already playing, the button keeps controlling the music. Can be turned off in the advanced options.
- The weather announcement names the town: "Météo à Blois, brouillard et 7 degrés."

## 1.5.0 (2026-11-07, not published)

- New summary option: today's next appointments, with their start time and title, read from the Sailfish Calendar. Repeating events (daily, weekly, monthly, yearly), cancelled and moved occurrences and hidden calendars are taken into account. All-day events are announced first.
- The weather town is chosen from a list of suggestions shown while typing, and the chosen town stays in the field. A town chosen with the previous version is kept.
- The privileged helper also copies the calendar database.

## 1.4.0 (2026-11-07, not published)

- All settings are made per app, in the Apps page. On arrival of a notification: ignore, read the titles, or read everything, with an option to read on the loudspeaker when no headphones are connected. In the summary: ignore, give the count, read the titles, or read everything. A new app is ignored in both cases, except Messages and calls, read in full. The notification families and their settings are gone; existing settings are converted.
- Lighter summary. After the greeting, the date and time (optional) and the weather (optional, from Open-Meteo for a town chosen in the settings), it only says how many notifications there are, without listing the apps. Notifications are no longer numbered: a beep opens and closes each app's block and separates its notifications.
- "Titles" mode: the sender or subject; when the title is only the app name (as with Facebook), the first sentence of the text is used.
- Links starting with "www." are no longer read aloud.

## 1.3.0 (2026-11-07, not published)

- New form of the spoken summary: a greeting with the date and time; the total number of notifications and the apps they come from; then, for each app, its number of notifications and, when it is read in full, each one numbered and separated by a short beep; a closing sentence. Short pauses separate the parts. Available in French, English, German, Spanish and Italian.
- Each notification family can be set to "do not announce", "announce the count" or "read everything", and any app can override its family's setting from its own page.
- `notivox-ctl events` reads the summary in headphones only; `notivox-ctl events-speakers` reads it on the loudspeaker when no headphones are connected. `notivox-ctl preview` shows what would be read.
- Phrases are synthesised one after the other while the previous one plays, so the summary starts quickly and flows without gaps.

## 1.2.0 (2026-11-07, not published)

- New spoken summary of the Events view. It announces how many notifications each app has, then reads them in full, each in its own language. It reads every notification still shown, not only new ones.
- It can be started from the new "Spoken summary" settings page, with `notivox-ctl summary` (for Situations), or automatically when headphones connect (optional, off by default). The same summary is not repeated within half an hour, and headset changes caused by a call are ignored.
- Option to clear from the Events view each notification read in full.
- Choice of notification families included: messages, missed calls, emails, calendar and reminders, system, other apps.
- `notivox-ctl stop` interrupts the reading; `notivox-ctl events` shows what the summary would read.
- The privileged helper is renamed `notivox-helper` and also copies the notification store.
- Better language detection between neighbouring languages (French text no longer read in Spanish).

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
