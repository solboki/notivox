# Notivox

Notivox reads aloud, in your headphones, the notifications of the Sailfish OS apps you choose, and tells you who is calling while the phone rings. Speech is produced on the phone itself by the [Piper](https://github.com/rhasspy/piper) neural text-to-speech engine. Nothing is sent over the network.

This project was vibe-coded with Claude Opus 5.5.

## What it does

The service listens to every notification posted on the phone, native or from Android App Support. Everything is set per app, in the Apps page: when a notification arrives, it is ignored, read by its title only (to know who wrote without hearing the message), or read in full, in headphones or, if you allow it for that app, on the loudspeaker. A new app is ignored, except Messages and calls.

For an incoming call, Notivox says the contact's name, or the number if it is not in your contacts, a few times while the phone rings. The announcements stop as soon as you answer or decline.

With a Bluetooth headset, Sailfish switches the headset's audio profile to "off" while the phone rings, and only opens the call profile once you answer: nothing, not even the ringtone, reaches the headset during the ringing. Notivox switches the headset back to its music profile (A2DP) for the announcement. When you answer, the system moves the headset to the call profile by itself. The ringtone itself still plays on the loudspeaker. If the headset cannot be woken, Notivox stays silent, unless you allow it to use the loudspeaker in the Incoming calls page.

By default nothing is ever spoken on the phone's loudspeaker. Notivox only talks when Bluetooth or wired headphones are in use.

Each message is read by a voice in its own language when one is installed: a message in English is read by an English voice, a message in French by a French voice. Voices are downloaded from the settings page, from the public Piper voice repository, in more than fifty languages. For a language without a Piper voice, the much more robotic but very wide eSpeak NG voice can step in.

A spoken summary reads the notifications still shown in the Events view. After a greeting, and optionally the date, time, weather and today's next appointments, it says how many notifications there are; then, app by app, according to that app's summary setting, it gives their count, their titles or their full content, framed by short beeps. It can be started from the settings, from Situations (`notivox-ctl events`, or `notivox-ctl events-speakers` to use the loudspeaker when no headphones are connected), or automatically when headphones connect. Notifications can optionally be cleared once read. The weather comes from the free Open-Meteo service and needs an Internet connection.

Reading can be controlled in four ways: the main switch, a timed pause (15 minutes, one hour, two hours, until tomorrow morning), quiet hours by day and time, and the [Situations](https://forum.sailfishos.org/t/situations-application-feedback/16333) app through a command or a D-Bus signal.

## Installing

Copy `notivox-1.5.0-1.aarch64.rpm` to the phone, then in a terminal:

```
devel-su pkcon install-local notivox-1.5.0-1.aarch64.rpm
```

The package is for 64-bit ARM phones (aarch64) and weighs about 21 MB, most of it being the Piper engine.

Notivox has no app icon: its settings are in **Settings › Voice notifications** (the name follows the system language). The background service starts with the phone. When you first open the page, it offers to download a voice in your language (about 60 MB for a "medium" voice, 28 MB for a "low" one). Then open **Apps**: apps appear there with their first notification, all switched off, and you switch on those you want to hear. You can change the default in the same page.

## Situations and the command line

`notivox-ctl` changes the same state as the main switch of the settings page:

```
notivox-ctl on              # turn reading on (and end a pause)
notivox-ctl off             # turn reading off
notivox-ctl toggle
notivox-ctl pause 60        # pause for 60 minutes
notivox-ctl resume
notivox-ctl status
notivox-ctl say "Some text"
notivox-ctl events          # read the Events view summary (headphones only)
notivox-ctl events-speakers # same, on the speaker if no headphones
notivox-ctl stop            # stop reading
```

In Situations, add a "run command" action with one of these lines. If you prefer D-Bus, the same orders exist as signals on the session bus, path `/org/notivox`, interface `org.notivox.Control`: `Enable`, `Disable`, `Toggle`, `Resume`, `Pause` (int32, minutes) and `Say` (string).

```
dbus-send --session --type=signal /org/notivox org.notivox.Control.Pause int32:30
```

## Points to check on your phone

Some parts depend on how each Sailfish device is set up and could only be tested on a simulated bus. If something does not work, switch on **Advanced options › Verbose log**, reproduce the problem, then use **Show the log** on the same page, or run `notivox-ctl log` in a terminal.

Headphone detection relies on `pactl` (run in English, whatever the phone's language), with a fallback that asks BlueZ whether an audio device is connected. If your wired headphones are not recognised, the option "Read if the output is not recognised" lets Notivox talk anyway.

The voice is played as a "notification" audio stream, sent by name to the headphones, for notifications and calls alike. (Version 1.0.0 used the ringtone's own stream type for calls, which Sailfish plays on the loudspeaker.) If the voice does not reach the headphones, these stream properties can be changed in the advanced options.

If calls are announced with the number instead of the name, `notivox-ctl contact NUMBER` shows how many numbers were read from the address book and the last error. The Sailfish address book is reserved for privileged programs. Notivox ships a tiny helper, `/usr/libexec/notivox/notivox-helper`, installed with that right, which copies your own address book to `~/.cache/notivox/`, readable by you only, at each incoming call. If it fails, calls are announced with the number.

## Uninstalling

```
devel-su pkcon remove notivox
```

Then delete `~/.config/notivox`, `~/.local/share/notivox` (the downloaded voices) and `~/.cache/notivox`.

## Building from source

Building is done on a Debian or Ubuntu computer:

```
sudo apt install rpm gcc-aarch64-linux-gnu curl qttools5-dev-tools
./make-dist.sh
```

The script downloads the Piper release for aarch64 and a newer libstdc++ from Debian 11 (Piper needs version 3.4.26, newer than the one shipped with Sailfish OS), compiles the address-book helper, then produces the RPM and a source archive in `dist/`.

To release a new version, change the number in three places: `V=` in `make-dist.sh`, `Version:` in `rpm/notivox.spec` and `VERSION` in `sailfish/notivox-daemon`. Add an entry to `CHANGELOG.md` and to the `%changelog` of the spec file.

## Tests

The service can be tested on a Linux computer without a phone. The test script starts a temporary D-Bus bus, sends notifications, incoming calls and Situations commands on it, and checks what the service would have said:

```
pip install dbus-next
PIPER_DIR=/path/to/piper_x86_64 VOICE=/path/to/fr_FR-siwis-medium.onnx ./tests/run-tests.sh
```

`PIPER_DIR` is the unpacked x86_64 Piper release, `VOICE` a French Piper voice (with its `.onnx.json` next to it).

## Source layout

| Folder | Content |
|---|---|
| `sailfish/` | The service (Python, needing only `python3`, `dbus-monitor` and `dbus-send`), the `notivox-ctl` command, the address-book helper, the systemd unit and the launcher. |
| `app/` | The settings page, shown in the Settings app: Silica interface (QML) and Python backend (PyOtherSide). |
| `settings/` | The entry that adds the page to the Settings app. |
| `translations/` | Translations of the page title in the Settings list. |
| `data/` | The list of Piper voices offered for download. |
| `icons/` | The project icon, and the icon of the Settings entry. |
| `rpm/` | The Sailfish package description. |
| `tests/` | Tests of the service on a simulated D-Bus bus. |

## License

Notivox is free software, released under the GNU GPL version 3 or later. The full text is in the `LICENSE` file.

The package also contains Piper and ONNX Runtime (MIT licence), eSpeak NG (GPL version 3) and the GCC runtime libraries (GPL version 3 with the GCC runtime library exception). Voices are downloaded separately and each comes with its own licence, shown in its model card on the Piper voices repository.
