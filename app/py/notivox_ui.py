# -*- coding: utf-8 -*-
"""Partie Python de l'application de réglages de Notivox (PyOtherSide).

L'application ne parle pas directement au service : elle écrit les
fichiers de réglages, que le service relit dès qu'ils changent, et
envoie des signaux D-Bus pour les essais de voix."""

import json
import os
import subprocess
import tempfile
import threading
import time
import urllib.request

try:
    import pyotherside
except ImportError:          # essais hors du téléphone
    pyotherside = None

HOME = os.path.expanduser("~")
CONF_DIR = os.path.join(HOME, ".config", "notivox")
VOICE_DIR = os.path.join(HOME, ".local", "share", "notivox", "voices")
CONFIG_FILE = os.path.join(CONF_DIR, "config.json")
STATE_FILE = os.path.join(CONF_DIR, "state.json")
SEEN_FILE = os.path.join(CONF_DIR, "apps-seen.json")
STATUS_FILE = os.path.join(HOME, ".cache", "notivox", "status.json")
CATALOG = os.path.join(os.environ.get("NOTIVOX_SHARE", "/usr/share/notivox"),
                       "voices-catalog.json")
VOICE_BASE = "https://huggingface.co/rhasspy/piper-voices/resolve/main/"
SERVICE = "notivox.service"

_downloads = {}


def send(*args):
    if pyotherside:
        pyotherside.send(*args)


def _load(path, default):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return default


def _save(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path), prefix=".tmp")
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=1)
    os.replace(tmp, path)


def _catalog():
    return _load(CATALOG, [])


def installed():
    out = []
    cat = {v["key"]: v for v in _catalog()}
    try:
        names = sorted(os.listdir(VOICE_DIR))
    except FileNotFoundError:
        names = []
    for n in names:
        if n.endswith(".onnx") and os.path.exists(
                os.path.join(VOICE_DIR, n + ".json")):
            key = n[:-5]
            c = cat.get(key, {})
            out.append({"key": key, "lang": key.split("_")[0],
                        "native": c.get("native", key.split("_")[0]),
                        "country": c.get("country", ""),
                        "name": c.get("name", key),
                        "quality": c.get("quality", ""),
                        "size": os.path.getsize(os.path.join(VOICE_DIR, n))})
    return out


def service_active():
    try:
        r = subprocess.run(["systemctl", "--user", "is-active", SERVICE],
                           capture_output=True, text=True, timeout=5)
        return r.stdout.strip() == "active"
    except Exception:
        return False


def load():
    """Tout ce que l'interface affiche, en un seul appel."""
    status = _load(STATUS_FILE, {})
    alive = bool(status) and time.time() - status.get("time", 0) < 20
    return {
        "config": _load(CONFIG_FILE, {}),
        "state": _load(STATE_FILE, {"enabled": True, "pause_until": 0}),
        "seen": _load(SEEN_FILE, {}),
        "status": status,
        "alive": alive,
        "voices": installed(),
        "now": time.time(),
        "downloads": dict(_downloads),
    }


def set_value(path, value):
    """Règle config[path[0]][path[1]]… = value."""
    cfg = _load(CONFIG_FILE, {})
    node = cfg
    for k in path[:-1]:
        if not isinstance(node.get(k), dict):
            node[k] = {}
        node = node[k]
    node[path[-1]] = value
    _save(CONFIG_FILE, cfg)
    return cfg


def set_app(app, key, value):
    cfg = _load(CONFIG_FILE, {})
    apps = cfg.setdefault("apps", {})
    apps.setdefault(app, {})[key] = value
    _save(CONFIG_FILE, cfg)
    return cfg


def set_all_apps(read, names):
    cfg = _load(CONFIG_FILE, {})
    apps = cfg.setdefault("apps", {})
    for n in names:
        apps.setdefault(n, {})["read"] = bool(read)
    _save(CONFIG_FILE, cfg)
    return cfg


def add_app(app):
    app = (app or "").strip()
    if not app:
        return _load(CONFIG_FILE, {})
    return set_app(app, "read", True)


def forget_app(app):
    cfg = _load(CONFIG_FILE, {})
    cfg.get("apps", {}).pop(app, None)
    _save(CONFIG_FILE, cfg)
    seen = _load(SEEN_FILE, {})
    if app in seen:
        seen.pop(app)
        _save(SEEN_FILE, seen)
    return True


def set_rules(rules):
    return set_value(["schedule", "rules"], rules)


def _state(change):
    st = _load(STATE_FILE, {"enabled": True, "pause_until": 0})
    change(st)
    _save(STATE_FILE, st)
    return st


def set_enabled(on):
    def c(st):
        st["enabled"] = bool(on)
        if on:
            st["pause_until"] = 0
    return _state(c)


def pause(minutes):
    return _state(lambda st: st.update(
        pause_until=int(time.time() + 60 * minutes)))


def pause_until_morning(hour=7):
    t = time.localtime()
    target = time.mktime((t.tm_year, t.tm_mon, t.tm_mday, hour, 0, 0,
                          0, 0, -1))
    if target <= time.time():
        target += 86400
    return _state(lambda st: st.update(pause_until=int(target)))


def resume():
    return _state(lambda st: st.update(pause_until=0))


def _signal(member, *args):
    subprocess.run(["dbus-send", "--session", "--type=signal",
                    "/org/notivox", "org.notivox.Control." + member]
                   + list(args), check=False)


def test_voice(key):
    _signal("TestVoice", "string:" + key)


def test_lang(lang):
    _signal("Test", "string:" + (lang or ""))


def say(text):
    _signal("Say", "string:" + text, "string:")


DISABLED_MARK = os.path.join(CONF_DIR, "service-disabled")


def ensure_started():
    """Au lancement de l'application : démarre le service s'il ne tourne
    pas, sauf si l'utilisateur a choisi de ne pas le démarrer."""
    if os.path.exists(DISABLED_MARK) or service_active():
        return service_active()
    return service("enable")


def service(action):
    if action == "enable":
        try:
            os.unlink(DISABLED_MARK)
        except FileNotFoundError:
            pass
    elif action == "disable":
        os.makedirs(CONF_DIR, exist_ok=True)
        open(DISABLED_MARK, "w").close()
    if action == "enable":
        cmds = [["enable", SERVICE], ["start", SERVICE]]
    elif action == "disable":
        cmds = [["disable", SERVICE], ["stop", SERVICE]]
    else:
        cmds = [[action, SERVICE]]
    for c in cmds:
        subprocess.run(["systemctl", "--user"] + c, timeout=15,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return service_active()


def service_enabled():
    try:
        r = subprocess.run(["systemctl", "--user", "is-enabled", SERVICE],
                           capture_output=True, text=True, timeout=5)
        return r.stdout.strip() in ("enabled", "static")
    except Exception:
        return False


def journal(lines=60):
    """Dernières lignes du journal de Notivox (le journal du système
    n'est pas lisible par l'utilisateur sur Sailfish)."""
    path = os.path.join(HOME, ".cache", "notivox", "notivox.log")
    try:
        with open(path, encoding="utf-8", errors="replace") as f:
            return "".join(f.readlines()[-lines:]).strip() or "(vide)"
    except FileNotFoundError:
        return "(vide)"


def languages():
    """Langues du catalogue, avec le nombre de voix de chacune."""
    by = {}
    for v in _catalog():
        e = by.setdefault(v["lang"], {"lang": v["lang"], "native": v["native"],
                                      "english": v["english"], "count": 0})
        e["count"] += 1
    return sorted(by.values(), key=lambda e: e["native"].lower())


def catalog(lang):
    have = set(v["key"] for v in installed())
    out = []
    for v in _catalog():
        if v["lang"] == lang:
            d = dict(v)
            d["installed"] = v["key"] in have
            out.append(d)
    return sorted(out, key=lambda v: (v["country"], v["quality"] != "medium",
                                      v["name"]))


def download(key):
    if key in _downloads:
        return
    entry = next((v for v in _catalog() if v["key"] == key), None)
    if not entry:
        send("download", key, -1, "unknown voice")
        return
    _downloads[key] = 0.0
    threading.Thread(target=_download, args=(entry,), daemon=True).start()


def _fetch(url, dest, size, key):
    tmp = dest + ".part"
    req = urllib.request.Request(url, headers={"User-Agent": "Notivox"})
    with urllib.request.urlopen(req, timeout=30) as r, open(tmp, "wb") as f:
        done = 0
        last = 0
        while True:
            chunk = r.read(256 * 1024)
            if not chunk:
                break
            f.write(chunk)
            done += len(chunk)
            if size and time.time() - last > 0.3:
                _downloads[key] = min(0.99, done / float(size))
                send("download", key, _downloads[key], "")
                last = time.time()
    os.replace(tmp, dest)


def _download(entry):
    key = entry["key"]
    os.makedirs(VOICE_DIR, exist_ok=True)
    onnx = os.path.join(VOICE_DIR, key + ".onnx")
    try:
        _fetch(VOICE_BASE + entry["path"] + ".json", onnx + ".json.dl", 0,
               key)
        _fetch(VOICE_BASE + entry["path"], onnx, entry["size"], key)
        os.replace(onnx + ".json.dl", onnx + ".json")
        _downloads.pop(key, None)
        send("download", key, 1.0, "")
    except Exception as exc:
        for p in (onnx, onnx + ".part", onnx + ".json.dl"):
            try:
                os.unlink(p)
            except FileNotFoundError:
                pass
        _downloads.pop(key, None)
        send("download", key, -1, str(exc))


def delete_voice(key):
    for ext in (".onnx", ".onnx.json"):
        try:
            os.unlink(os.path.join(VOICE_DIR, key + ext))
        except FileNotFoundError:
            pass
    cfg = _load(CONFIG_FILE, {})
    voices = cfg.get("voices", {})
    for lang in [k for k, v in voices.items() if v == key]:
        voices.pop(lang)
    _save(CONFIG_FILE, cfg)
    return True

