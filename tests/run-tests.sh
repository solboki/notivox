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
    export DBUS_SESSION_BUS_ADDRESS=$(dbus-daemon --session --fork --print-address)
    HOME="$W/home" PLOG="$W/plog" NOTIVOX_PLAYER="$W/player.sh" \
    NOTIVOX_FORCE_OUTPUT="${OUTPUT:-bluetooth}" NOTIVOX_OFONO_BUS=session \
    NOTIVOX_PIPER_DIR="$PIPER_DIR" NOTIVOX_CONF_DIR="$W/conf" \
    NOTIVOX_DATA_DIR="$W/data" NOTIVOX_CACHE_DIR="$W/cache" \
    NOTIVOX_CONTACTS_HELPER=/nonexistent \
        python3 "$DAEMON" > "$W/log" 2>&1 & local pid=$!
    python3 "$HERE/fake_bus.py" "$1" "$3"
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

echo "== notifications"
run notif '{"new_apps_default": true, "apps": {"Météo": {"read": false}}, "debug": true}' 12
check "guillemets et retour à la ligne" 'Salut, on dit "midi" ou "13h" demain ?'
check "doublon ignoré" "doublon ignoré"
check "langue anglaise détectée (eSpeak de secours)" "lecture [en/espeak]"
check "application coupée non lue" "défaut : Météo" 0
check "aperçu Sailfish préféré au texte brut" "Jean Dupont. Rappelle-moi stp"
plays "trois annonces jouées" 3
grep -q '"Météo"' "$WORK/conf/apps-seen.json" && echo "ok    application coupée tout de même répertoriée" || { echo "ÉCHEC répertoire des applications"; FAIL=1; }

echo "== pas d'écouteurs"
OUTPUT=speaker run notif '{"new_apps_default": true, "debug": true}' 8
check "rien n'est lu sur le haut-parleur" "pas d'écouteurs" 4
plays "aucune lecture" 0

echo "== appels"
run call '{"new_apps_default": true, "debug": true, "calls": {"repeat": 2, "interval": 4, "first_delay": 1}}' 6
check "nom du contact trouvé" "Appel de Jean Dupont" 2
check "notification ignorée pendant l'appel" "appel en cours"
check "appel masqué annoncé" "Appel masqué"
plays "trois annonces d'appel" 3

echo "== commandes (Situations)"
run control '{"new_apps_default": true, "debug": true}' 8
check "pause respectée" "notification non lue (en pause)"
check "texte libre lu" "défaut : Texte libre envoyé par Situations"

exit $FAIL
