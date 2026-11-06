Name:       notivox
Version:    1.0.5
Release:    1
Summary:    Reads notifications and incoming calls aloud in your headphones
License:    GPL-3.0-or-later
URL:        https://github.com/solboki/notivox
Source0:    %{name}-%{version}.tar.gz
Source1:    piper-aarch64.tar.gz
Requires:   python3-base
Requires:   pyotherside-qml-plugin-python3-qt5
Requires:   sailfishsilica-qt5
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
install -Dm755 build/notivox-contacts %{buildroot}%{_libexecdir}/notivox/notivox-contacts
install -Dm644 sailfish/notivox.service %{buildroot}%{_userunitdir}/notivox.service
mkdir -p %{buildroot}%{_userunitdir}/user-session.target.wants
ln -s ../notivox.service %{buildroot}%{_userunitdir}/user-session.target.wants/notivox.service
install -Dm644 sailfish/notivox.desktop %{buildroot}%{_datadir}/applications/notivox.desktop
install -Dm644 data/voices-catalog.json %{buildroot}%{_datadir}/notivox/voices-catalog.json
mkdir -p %{buildroot}%{_datadir}/notivox/qml
cp -r app/qml/* %{buildroot}%{_datadir}/notivox/qml/
install -Dm644 app/py/notivox_ui.py %{buildroot}%{_datadir}/notivox/qml/py/notivox_ui.py
mkdir -p %{buildroot}%{_datadir}/notivox/piper
cp -a piper-bin/piper/. %{buildroot}%{_datadir}/notivox/piper/
for s in 86 108 128 172 256; do
    install -Dm644 icons/notivox-$s.png \
        %{buildroot}%{_datadir}/icons/hicolor/${s}x${s}/apps/notivox.png
done

%post
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
%attr(2755,root,privileged) %{_libexecdir}/notivox/notivox-contacts
%{_userunitdir}/notivox.service
%{_userunitdir}/user-session.target.wants/notivox.service
%{_datadir}/applications/notivox.desktop
%{_datadir}/notivox
%{_datadir}/icons/hicolor/*/apps/notivox.png

%changelog
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
