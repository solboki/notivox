"""Crée une fausse base de notifications au format de lipstick (Sailfish),
pour tester le résumé vocal. Usage : python3 make_events_db.py base.db"""
import sqlite3
import sys

db = sqlite3.connect(sys.argv[1])
db.execute("CREATE TABLE notifications (id INTEGER PRIMARY KEY, app_name TEXT,"
           " app_icon TEXT, summary TEXT, body TEXT, expire_timeout INTEGER,"
           " disambiguated_app_name TEXT, explicit_app_name TEXT,"
           " app_icon_origin INTEGER)")
db.execute("CREATE TABLE hints (id INTEGER, hint TEXT, value TEXT,"
           " PRIMARY KEY(id, hint))")
rows = [
    (11, "WhatsApp", "Alice Martin", "Tu es dispo pour déjeuner à midi ?", "x-nemo.messaging.im"),
    (12, "WhatsApp", "Alice Martin", "Sinon demain, ça marche aussi.", "x-nemo.messaging.im"),
    (13, "Messages", "Dr Lefèvre", "Votre rendez-vous de jeudi 14h est maintenu.", "x-nemo.messaging.sms"),
    (14, "Téléphone", "Appel manqué", "Jean Dupont", "x-nemo.call.missed"),
    (15, "Courriel", "Service RH", "La campagne d'entretiens se termine vendredi.", "x-nemo.email"),
    (16, "Signal", "Bob", "Are you coming to the meeting with the team this afternoon? I think it is at three.", ""),
    (17, "Système", "Batterie", "Batterie faible, 15 %", "x-nemo.battery"),
    (18, "Mises à jour", "Transfert", "Téléchargement en cours", "x-nemo.transfer"),
]
for nid, app, summary, body, cat in rows:
    db.execute("INSERT INTO notifications VALUES (?,?,?,?,?,?,?,?,?)",
               (nid, app, "", summary, body, -1, "", "", 0))
    if cat:
        db.execute("INSERT INTO hints VALUES (?,?,?)", (nid, "category", cat))
# Une notification éphémère (jamais affichée) et une non effaçable
db.execute("INSERT INTO notifications VALUES (19,'X','','Éphémère','',0,'','',0)")
db.execute("INSERT INTO hints VALUES (19,'transient','true')")
db.execute("INSERT INTO hints VALUES (14,'x-nemo-user-removable','false')")
db.commit()
