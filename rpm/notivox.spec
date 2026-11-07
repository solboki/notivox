Name:       notivox
Version:    1.7.1
Release:    1
Summary:    Reads notifications and incoming calls aloud in your headphones
License:    GPL-3.0-or-later
URL:        https://github.com/solboki/notivox
Source0:    %{name}-%{version}.tar.gz
Source1:    piper-aarch64.tar.gz
Requires:   python3-base
Requires:   pyotherside-qml-plugin-python3-qt5
Requires:   sailfishsilica-qt5
Requires:   jolla-settings
# Piper et ses bibliothèques sont embarqués dans /usr/share/notivox/piper :
# ils ne doivent ni fournir ni réclamer de bibliothèques au système.
AutoReqProv: no

%define _userunitdir /usr/lib/systemd/user
%define _libexecdir /usr/libexec
%define _binary_payload w6.xzdio
%define _source_payload w6.xzdio
%define _build_id_links none
%global debug_package %{nil}
%global __os_install_post %{nil}

%description
Notivox reads aloud, in your headphones, the notifications of the apps you
choose and the name of the person calling you. Speech is produced on the
phone by the Piper neural text-to-speech engine, in many languages, with
the eSpeak NG voice as a fallback. Reading can be switched on and off from
the app, on a schedule, or by the Situations app.

Vibe-coded with Claude Opus 5.5.

%prep
%setup -q
mkdir piper-bin
tar -xzf %{SOURCE1} -C piper-bin

%build

%install
install -Dm755 sailfish/notivox-daemon %{buildroot}%{_bindir}/notivox-daemon
install -Dm755 sailfish/notivox-ctl %{buildroot}%{_bindir}/notivox-ctl
install -Dm755 build/notivox-helper %{buildroot}%{_libexecdir}/notivox/notivox-helper
install -Dm644 sailfish/notivox.service %{buildroot}%{_userunitdir}/notivox.service
mkdir -p %{buildroot}%{_userunitdir}/user-session.target.wants
ln -s ../notivox.service %{buildroot}%{_userunitdir}/user-session.target.wants/notivox.service
install -Dm644 data/voices-catalog.json %{buildroot}%{_datadir}/notivox/voices-catalog.json
# Page de l'application Paramètres : Paramètres › Notification vocale
P=%{buildroot}%{_datadir}/jolla-settings/pages/notivox
mkdir -p $P/pages $P/py
install -m644 app/qml/NV.qml app/qml/qmldir $P/
install -m644 app/qml/pages/*.qml $P/pages/
install -m644 app/py/notivox_ui.py $P/py/
install -Dm755 sailfish/notivox-place-entry %{buildroot}%{_libexecdir}/notivox/notivox-place-entry
# Icône au trait du thème Sailfish, recolorée par le système selon que
# l'ambiance est claire ou sombre.
for z in 1.0 1.25 1.5 1.5-large 1.75 2.0 2.5; do
    for d in icons icons-monochrome; do
        install -Dm644 icons/theme/icon-m-notivox-z$z.png \
            %{buildroot}%{_datadir}/themes/sailfish-default/silica/z$z/$d/icon-m-notivox.png
    done
done
install -Dm644 settings/notivox.json %{buildroot}%{_datadir}/jolla-settings/entries/notivox.json
mkdir -p %{buildroot}%{_datadir}/translations
for f in translations/*.qm; do
    b=$(basename $f .qm); l=${b#settings-notivox-}
    # Deux formes de nom, selon la façon dont le catalogue est cherché
    install -m644 $f %{buildroot}%{_datadir}/translations/settings-notivox-$l.qm
    install -m644 $f %{buildroot}%{_datadir}/translations/settings-notivox_$l.qm
done
mkdir -p %{buildroot}%{_datadir}/notivox/piper
cp -a piper-bin/piper/. %{buildroot}%{_datadir}/notivox/piper/

%post
# Place l'entrée des Paramètres juste après « Sons et retours ».
%{_libexecdir}/notivox/notivox-place-entry >/dev/null 2>&1 || :
# Démarre (ou redémarre) le service pour l'utilisateur du téléphone.
systemctl-user daemon-reload >/dev/null 2>&1 || :
systemctl-user try-restart notivox.service >/dev/null 2>&1 || :
systemctl-user start notivox.service >/dev/null 2>&1 || :

%preun
if [ "$1" -eq 0 ]; then
    systemctl-user stop notivox.service >/dev/null 2>&1 || :
fi

%postun
systemctl-user daemon-reload >/dev/null 2>&1 || :

%files
%license LICENSE
%doc README.md CHANGELOG.md
%{_bindir}/notivox-daemon
%{_bindir}/notivox-ctl
%dir %{_libexecdir}/notivox
%attr(2755,root,privileged) %{_libexecdir}/notivox/notivox-helper
%{_libexecdir}/notivox/notivox-place-entry
%{_userunitdir}/notivox.service
%{_userunitdir}/user-session.target.wants/notivox.service
%{_datadir}/notivox
%{_datadir}/jolla-settings/pages/notivox
%verify(not md5 size mtime) %{_datadir}/jolla-settings/entries/notivox.json
%{_datadir}/themes/sailfish-default/silica/z*/icons*/icon-m-notivox.png
%{_datadir}/translations/settings-notivox*.qm

%changelog
* Sat Nov 07 2026 Boris Solodki <solboki@solodki.fr> - 1.7.1-1
- Fix: after a headset button press, the summary went on with its next
  sentence.
- Audio streams are only muted when no pausable player was playing.
* Sat Nov 07 2026 Boris Solodki <solboki@solodki.fr> - 1.7.0-1
- Music and podcasts are paused while Notivox speaks and resume after.
- Headset button: Notivox stops and the paused playback resumes.
* Sat Nov 07 2026 Boris Solodki <solboki@solodki.fr> - 1.6.1-1
- Headset button: works even though Sailfish gives the button to another
  player; that player is paused again after the press.
* Sat Nov 07 2026 Boris Solodki <solboki@solodki.fr> - 1.6.0-1
- A short press on the headset play/pause button stops the reading.
- The weather announcement names the town.
* Sat Nov 07 2026 Boris Solodki <solboki@solodki.fr> - 1.5.0-1
- Summary option: today's next appointments from the Calendar.
- Weather town chosen from live suggestions; the chosen town stays in the
  field.
* Sat Nov 07 2026 Boris Solodki <solboki@solodki.fr> - 1.4.0-1
- Everything is set per app: on arrival (ignore, titles, everything, and
  optionally on the speaker) and in the summary (ignore, count, titles,
  everything). New apps are ignored, except Messages and calls.
- Lighter summary: total only, optional date and time, optional weather
  (Open-Meteo), beeps around and between the notifications read, no
  numbering.
* Sat Nov 07 2026 Boris Solodki <solboki@solodki.fr> - 1.3.0-1
- New summary form: greeting, date and time, total, count per app,
  numbered messages separated by a beep, closing sentence.
- For each family, and optionally each app: do not announce, announce
  the count, or read everything.
- "notivox-ctl events" (headphones only) and "notivox-ctl events-speakers"
  (speaker when no headphones).
* Sat Nov 07 2026 Boris Solodki <solboki@solodki.fr> - 1.2.0-1
- Spoken summary of the Events view: count per app, then full reading.
  Started from the settings, from Situations, or when headphones connect.
- Option to clear notifications once read, choice of notification families.
* Fri Nov 06 2026 Boris Solodki <solboki@solodki.fr> - 1.1.1-1
- Settings entry placed right after "Sounds and feedback".
- Line icon in the Sailfish theme style, black on light ambiences and
  white on dark ones, at the size of the other icons.
* Fri Nov 06 2026 Boris Solodki <solboki@solodki.fr> - 1.1.0-1
- The settings are now a page of the Settings app ("Voice notifications",
  translated in the system language) instead of an app icon.
- The service starts with the phone by default; switching it off in the
  advanced options keeps it stopped across restarts.
* Fri Nov 06 2026 Boris Solodki <solboki@solodki.fr> - 1.0.6-1
- Fix: the caller's name was never found on recent Sailfish versions,
  whose address book no longer stores the display name in the Contacts
  table. The name is now looked up wherever it is stored.
* Fri Nov 06 2026 Boris Solodki <solboki@solodki.fr> - 1.0.5-1
- Faster call announcements: the caller is looked up and the sentence is
  synthesised as soon as the call arrives, the main voice stays loaded,
  no fixed delay before the first announcement, finer headset polling.
- "notivox-ctl contact NUMBER" to diagnose address-book lookups.
* Fri Nov 06 2026 Boris Solodki <solboki@solodki.fr> - 1.0.4-1
- Incoming calls are now announced in Bluetooth headsets: the headset
  sound, switched off by Sailfish while ringing, is switched back on for
  the announcement.
* Fri Nov 06 2026 Boris Solodki <solboki@solodki.fr> - 1.0.3-1
- Fix: calls were announced on the loudspeaker while a Bluetooth headset
  was connected but silent (the phone switches it off while ringing).
- New call option: announce on the loudspeaker when the headset is silent.
* Fri Nov 06 2026 Boris Solodki <solboki@solodki.fr> - 1.0.2-1
- Fix: incoming calls were announced on the loudspeaker instead of the
  headphones; existing settings are updated automatically.
- Voices page: visible "Download another voice" entry.
* Fri Nov 06 2026 Boris Solodki <solboki@solodki.fr> - 1.0.1-1
- Fix: headphones were never detected when the phone is not in English
  (pactl translates its output).
- Fix: no sound on phones whose default audio output is sink.null; the
  voice is now sent to the headphones (or speaker) by name.
- The log is now written to ~/.cache/notivox/notivox.log, readable from
  the app and with "notivox-ctl log".
* Fri Nov 06 2026 Boris Solodki <solboki@solodki.fr> - 1.0.0-1
- First release: notifications and incoming calls read aloud with Piper,
  per-app settings, quiet hours, pause, Situations commands.
