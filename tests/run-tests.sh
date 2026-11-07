#!/bin/bash
# Teste le service sur un bus D-Bus temporaire, sans téléphone.
# Prérequis : dbus-daemon, dbus-monitor, python3, le module dbus-next
# (pip install dbus-next) et une version x86_64 de Piper avec une voix
# française (voir README) : PIPER_DIR=... VOICE=.../fr_FR-siwis-medium.onnx
set -u
HERE=$(cd "$(dirname "$0")" && pwd)
DAEMON="$HERE/../sailfish/notivox-daemon"
: "${PIPER_DIR:?indiquer PIPER_DIR}" "${VOICE:?indiquer VOICE}"
FAIL=0

run() {  # run scénario config.json durée
    W=$(mktemp -d)
    mkdir -p "$W/data/voices" "$W/conf" "$W/plog"
    ln -s "$VOICE" "$W/data/voices/fr_FR-siwis-medium.onnx"
    ln -s "$VOICE.json" "$W/data/voices/fr_FR-siwis-medium.onnx.json"
    printf '%s' "$2" > "$W/conf/config.json"
    cat > "$W/player.sh" <<'P'
#!/bin/sh
n=$(ls "$PLOG" | wc -l); cp "$1" "$PLOG/$n.wav"
[ -n "$PLAYDELAY" ] && sleep "$PLAYDELAY"
exit 0
P
    chmod +x "$W/player.sh"
    # Faux carnet d'adresses
    C="$W/home/.local/share/system/privileged/Contacts/qtcontacts-sqlite"
    mkdir -p "$C"
    python3 - "$C/contacts.db" <<'P'
import sqlite3, sys
db = sqlite3.connect(sys.argv[1])
db.execute("create table Contacts(contactId integer, displayLabel text)")
db.execute("create table PhoneNumbers(detailId integer, contactId integer, phoneNumber text)")
db.execute("insert into Contacts values (1, 'Jean Dupont')")
db.execute("insert into PhoneNumbers values (1, 1, '06 12 34 56 78')")
db.commit()
P
    python3 "$HERE/make_events_db.py" "$W/events.db"
    export DBUS_SESSION_BUS_ADDRESS=$(dbus-daemon --session --fork --print-address)
    HOME="$W/home" PLOG="$W/plog" NOTIVOX_PLAYER="$W/player.sh" \
    NOTIVOX_FORCE_OUTPUT="${OUTPUT:-bluetooth}" NOTIVOX_OFONO_BUS=session \
    NOTIVOX_PIPER_DIR="$PIPER_DIR" NOTIVOX_CONF_DIR="$W/conf" \
    NOTIVOX_DATA_DIR="$W/data" NOTIVOX_CACHE_DIR="$W/cache" \
    NOTIVOX_HELPER=/nonexistent NOTIVOX_EVENTS_DB="$W/events.db" \
        python3 "$DAEMON" > "$W/log" 2>&1 & local pid=$!
    python3 "$HERE/fake_bus.py" "$1" "$3" > "$W/bus.log"
    kill $pid; wait $pid 2>/dev/null
    LOG="$W/log"; cp "$W/log" /tmp/last-$1-${OUTPUT:-bt}.log; PLAYS=$(ls "$W/plog" | wc -l); WORK=$W
}

check() {  # check "description" motif [nombre attendu]
    local n
    n=$(grep -cF -- "$2" "$LOG")
    if [ "$n" -eq "${3:-1}" ]; then echo "ok    $1"
    else echo "ÉCHEC $1 (trouvé $n fois : $2)"; FAIL=1; fi
}
plays() {
    if [ "$PLAYS" -eq "$2" ]; then echo "ok    $1"
    else echo "ÉCHEC $1 ($PLAYS lectures au lieu de $2)"; FAIL=1; fi
}

echo "== sortie audio (pactl de Sailfish, sortie par défaut sink.null)"
FAKE=$(mktemp -d)
cat > "$FAKE/pactl" <<'P'
#!/bin/sh
if [ "$LC_ALL" != "C" ]; then
  printf 'Destination #0\n\tNom : sink.primary_output\n\tPort actif : output-speaker\n'; exit 0
fi
cat <<'T'
Sink #0
	Name: sink.primary_output
	Active Port: output-speaker
Sink #3
	Name: sink.null
Sink #4
	Name: bluez_sink.68_F2_1F_78_1C_19.a2dp_sink
	Active Port: headset-output
T
[ -n "$NOBT" ] && exit 0
P
chmod +x "$FAKE/pactl"
R=$(PATH="$FAKE:$PATH" python3 -c "
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('d', '$DAEMON').load_module()
print(m.audio_route())")
if [ "$R" = "('bluetooth', 'bluez_sink.68_F2_1F_78_1C_19.a2dp_sink')" ]; then
    echo "ok    casque Bluetooth reconnu et visé directement"
else echo "ÉCHEC sortie audio : $R"; FAIL=1; fi
sed -i 's/^\tName: bluez.*//; s/^\tActive Port: headset-output//' "$FAKE/pactl"
R=$(PATH="$FAKE:$PATH" NOTIVOX_CACHE_DIR="$FAKE" python3 -c "
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('d', '$DAEMON').load_module()
m.output_from_bluez = lambda: None
print(m.audio_route())")
if [ "$R" = "('speaker', 'sink.primary_output')" ]; then
    echo "ok    sans casque : haut-parleur, jamais sink.null"
else echo "ÉCHEC sortie sans casque : $R"; FAIL=1; fi

R=$(PATH="$FAKE:$PATH" NOTIVOX_CACHE_DIR="$FAKE" python3 -c "
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('d', '$DAEMON').load_module()
m.output_from_bluez = lambda: 'bluetooth'
print(m.audio_route())")
if [ "$R" = "('speaker', 'sink.primary_output')" ]; then
    echo "ok    pendant la sonnerie : casque connecté mais muet, donc haut-parleur"
else echo "ÉCHEC casque connecté sans sortie son : $R"; FAIL=1; fi

echo "== casque Bluetooth éteint par la sonnerie"
BT=$(mktemp -d); echo off > "$BT/profile"
cat > "$BT/pactl" <<P
#!/bin/sh
ST=$BT/profile
P
cat >> "$BT/pactl" <<'P'
case "$1 $2" in
  "set-card-profile bluez_card.68_F2_1F_78_1C_19") echo "$3" > "$ST"; exit 0 ;;
  "list cards")
    printf 'Card #0\n\tName: droid_card.primary\n\tActive Profile: default\n'
    printf 'Card #1\n\tName: bluez_card.68_F2_1F_78_1C_19\n\tProfiles:\n'
    printf '\t\ta2dp_sink: High Fidelity Playback (A2DP Sink) (sinks: 1, sources: 0, priority: 40, available: yes)\n'
    printf '\t\thandsfree_head_unit: Handsfree Head Unit (HFP) (sinks: 1, sources: 1, priority: 30, available: yes)\n'
    printf '\t\toff: Off (sinks: 0, sources: 0, priority: 0, available: yes)\n'
    printf '\tActive Profile: %s\n' "$(cat "$ST")" ;;
  "list sinks")
    printf 'Sink #0\n\tName: sink.primary_output\n\tActive Port: output-speaker\n'
    [ "$(cat "$ST")" = a2dp_sink ] && printf 'Sink #9\n\tName: bluez_sink.68_F2_1F_78_1C_19.a2dp_sink\n\tActive Port: headset-output\n'
    exit 0 ;;
esac
P
chmod +x "$BT/pactl"
R=$(PATH="$BT:$PATH" NOTIVOX_CACHE_DIR="$BT" python3 -c "
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('d', '$DAEMON').load_module()
m.output_from_bluez = lambda: 'bluetooth'
before = m.audio_route()
ok = m.wake_bt_headset()
print(before, ok, m.audio_route())")
if [ "$R" = "('speaker', 'sink.primary_output') True ('bluetooth', 'bluez_sink.68_F2_1F_78_1C_19.a2dp_sink')" ]; then
    echo "ok    casque rallumé en mode musique, annonce envoyée au casque"
else echo "ÉCHEC réveil du casque : $R"; FAIL=1; fi

echo "== notifications"
run notif '{"apps": {"WhatsApp": {"arrival": "full"}, "Signal": {"arrival": "full"}}, "debug": true}' 12
check "guillemets et retour à la ligne" 'Salut, on dit "midi" ou "13h" demain ?'
check "doublon ignoré" "doublon ignoré"
check "langue anglaise détectée (eSpeak de secours)" "lecture [en/espeak]"
check "application coupée non lue" "défaut : Météo" 0
check "aperçu Sailfish préféré au texte brut" "Jean Dupont. Rappelle-moi stp"
plays "trois annonces jouées" 3
grep -q '"Météo"' "$WORK/conf/apps-seen.json" && echo "ok    application coupée tout de même répertoriée" || { echo "ÉCHEC répertoire des applications"; FAIL=1; }

echo "== pas d'écouteurs"
OUTPUT=speaker run notif '{"apps": {"WhatsApp": {"arrival": "full"}, "Signal": {"arrival": "full"}}, "debug": true}' 8
check "rien n'est lu sur le haut-parleur" "pas d'écouteurs" 3
plays "aucune lecture" 0
OUTPUT=speaker run notif '{"apps": {"Signal": {"arrival": "titles", "speaker": true}}, "debug": true}' 8
check "application réglée sur le haut-parleur : titre seulement" "] vers défaut : Signal. Bob"
plays "seule cette application est lue" 1

echo "== appels"
run call '{"apps": {"WhatsApp": {"arrival": "full"}}, "debug": true, "calls": {"repeat": 2, "interval": 4, "first_delay": 1}}' 6
check "nom du contact trouvé" "] vers défaut : Appel de Jean Dupont" 2
check "notification ignorée pendant l'appel" "appel en cours"
check "appel masqué annoncé" "] vers défaut : Appel masqué"
plays "trois annonces d'appel" 3

echo "== commandes (Situations)"
run control '{"apps": {"WhatsApp": {"arrival": "full"}}, "debug": true}' 8
check "pause respectée" "notification non lue (en pause)"
check "texte libre lu" "défaut : Texte libre envoyé par Situations"

echo "== résumé de la Vue Événements"
run summary '{"debug": true, "summary": {"clear_after": true}, "apps": {"Signal": {"summary": "full"}, "WhatsApp": {"summary": "titles"}, "Courriel": {"summary": "count"}}}' 30
check "date et heure annoncées" "Bonjour. Nous sommes le"
check "total sans la liste des applications" "] vers défaut : Vous avez 6 notifications."
check "décompte d'une application" "Vous avez 2 notifications de WhatsApp."
check "pas de numéros" "1 : " 0
check "titres seulement" "] vers défaut : Alice Martin" 2
check "message anglais lu par une autre voix" "lecture [en/"
check "courriels : nombre seulement" "La campagne d'entretiens" 0
check "applications non réglées ignorées" "Batterie faible" 0
check "formule de fin" "Fin de vos notifications. À bientôt."
check "bips autour et entre les notifications" "] vers défaut : beep" 9
n=$(grep -c '^fermeture' "$WORK/bus.log")
if [ "$n" -eq 4 ]; then echo "ok    quatre notifications lues puis effacées (nombre seul et appel non effaçable gardés)"
else echo "ÉCHEC effacement : $n fermetures"; cat "$WORK/bus.log"; FAIL=1; fi

echo "== rendez-vous du jour"
W=$(mktemp -d); python3 "$HERE/make_calendar_db.py" "$W/c.db"
R=$(NOTIVOX_CALENDAR_DB="$W/c.db" NOTIVOX_CACHE_DIR="$W" python3 -c "
import time
from importlib.machinery import SourceFileLoader
m = SourceFileLoader('d', '$DAEMON').load_module()
m.CFG = m.merge(m.DEFAULT_CONFIG, {})
print(m.agenda_phrase('fr', time.mktime((2026, 11, 7, 12, 0, 0, 0, 0, -1))))")
E="Vos prochains rendez-vous aujourd'hui. Toute la journée, Anniversaire de papa. À 12 heures 30, Déjeuner avec Alice. À 16 heures, Marché. À 18 heures, Piscine. À 21 heures, Chorale."
if [ "$R" = "$E" ]; then echo "ok    rendez-vous restants (répétitions, exceptions, agenda masqué, occurrence déplacée)"
else echo "ÉCHEC rendez-vous : $R"; FAIL=1; fi

echo "== bouton du casque"
PLAYDELAY=0.8 run button '{"debug": true, "apps": {"WhatsApp": {"summary": "full"}, "Signal": {"summary": "full"}}}' 14
grep -q '^statut Playing Notivox' "$WORK/bus.log" && echo "ok    Notivox se présente comme lecteur pendant la lecture" || { echo "ÉCHEC lecteur absent"; cat "$WORK/bus.log"; FAIL=1; }
check "appui court : lecture interrompue" "bouton du casque : lecture interrompue"
check "la suite du résumé est abandonnée" "Fin de vos notifications" 0
grep -q 'lecteur encore présent : False' "$WORK/bus.log" && echo "ok    bouton rendu au lecteur de musique après la lecture" || { echo "ÉCHEC nom MPRIS non rendu"; cat "$WORK/bus.log"; FAIL=1; }

echo "== bouton du casque donné par Sailfish à un autre lecteur"
PLAYDELAY=0.8 run button2 '{"debug": true, "apps": {"WhatsApp": {"summary": "full"}, "Signal": {"summary": "full"}}}' 12
check "ordre au lecteur de podcasts repéré, lecture interrompue" "bouton du casque (ordre Play"
check "état du lecteur noté au début" "alors Paused"
check "la suite du résumé est abandonnée" "Fin de vos notifications" 0
grep -q '^podcast Pause' "$WORK/bus.log" && echo "ok    lecteur de podcasts remis en pause" || { echo "ÉCHEC podcast non remis en pause"; cat "$WORK/bus.log"; FAIL=1; }

echo "== musique en cours : pause pendant la lecture, reprise ensuite"
PLAYDELAY=0.2 run music '{"debug": true, "apps": {"WhatsApp": {"summary": "full"}}}' 22
if [ "$(grep '^podcast' "$WORK/bus.log" | tr '\n' ' ')" = "podcast Pause podcast Play " ]; then
    echo "ok    podcast mis en pause puis relancé"
else echo "ÉCHEC pause et reprise : $(grep '^podcast' "$WORK/bus.log" | tr '\n' ' ')"; FAIL=1; fi
PLAYDELAY=0.8 run music-button '{"debug": true, "apps": {"WhatsApp": {"summary": "full"}, "Signal": {"summary": "full"}}}' 14
if [ "$(grep '^podcast' "$WORK/bus.log" | tr '\n' ' ')" = "podcast Pause podcast PlayPause " ]; then
    echo "ok    appui : Notivox se tait et le podcast reprend, sans coupure supplémentaire"
else echo "ÉCHEC appui avec musique : $(grep '^podcast' "$WORK/bus.log" | tr '\n' ' ')"; FAIL=1; fi
check "lecture interrompue par l'appui" "bouton du casque (ordre PlayPause"

echo "== résumé sans écouteurs"
OUTPUT=speaker run summary '{"debug": true}' 6
plays "events : rien n'est lu sans écouteurs" 0
OUTPUT=speaker run summary-speaker '{"debug": true}' 25
if [ "$PLAYS" -gt 5 ]; then echo "ok    events-speakers : lu sur le haut-parleur"
else echo "ÉCHEC events-speakers : $PLAYS lectures"; FAIL=1; fi

exit $FAIL
