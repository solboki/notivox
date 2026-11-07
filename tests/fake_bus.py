"""Simule sur un bus de session ce qu'émet Sailfish OS : appels à
org.freedesktop.Notifications.Notify, signaux d'oFono et commandes
org.notivox.Control. Utilisé par run-tests.sh."""
import asyncio
import sys
from dbus_next.aio import MessageBus
from dbus_next.service import ServiceInterface, method, signal
from dbus_next import Variant, Message, MessageType


class Notif(ServiceInterface):
    def __init__(self):
        super().__init__("org.freedesktop.Notifications")

    @method()
    def CloseNotification(self, nid: 'u'):
        print("fermeture", nid, flush=True)

    @method()
    def Notify(self, app: 's', rid: 'u', icon: 's', summary: 's', body: 's',
               actions: 'as', hints: 'a{sv}', timeout: 'i') -> 'u':
        return 1


async def notify(bus, app, summary, body, hints=None):
    msg = Message(destination="org.freedesktop.Notifications",
                  path="/org/freedesktop/Notifications",
                  interface="org.freedesktop.Notifications", member="Notify",
                  signature="susssasa{sv}i",
                  body=[app, 0, "", summary, body, ["default", ""],
                        hints or {}, -1])
    await bus.call(msg)


async def sig(bus, path, iface, member, signature, body):
    await bus.send(Message.new_signal(path, iface, member, signature, body))


async def main():
    bus = await MessageBus().connect()
    bus.export("/org/freedesktop/Notifications", Notif())
    await bus.request_name("org.freedesktop.Notifications")
    steps = sys.argv[1]
    await asyncio.sleep(1.5)
    if steps == "notif":
        await notify(bus, "WhatsApp", "Alice Martin",
                     'Salut, on dit "midi" ou\n"13h" demain ?',
                     {"category": Variant("s", "x-nemo.messaging.im")})
        await asyncio.sleep(0.3)
        await notify(bus, "WhatsApp", "Alice Martin",
                     'Salut, on dit "midi" ou\n"13h" demain ?')   # doublon
        await notify(bus, "Signal", "Bob", "Are you coming to the meeting "
                     "with the team this afternoon? I think it is at three.")
        await notify(bus, "Météo", "Pluie", "Averses en fin de journée")
        await notify(bus, "Messages", "Jean Dupont", "<b>Rappelle</b> moi "
                     "https://exemple.fr stp 😀",
                     {"x-nemo-preview-summary": Variant("s", "Jean Dupont"),
                      "x-nemo-preview-body": Variant("s", "Rappelle-moi stp")})
    elif steps == "call":
        await sig(bus, "/ril_0", "org.ofono.VoiceCallManager", "CallAdded",
                  "oa{sv}", ["/ril_0/voicecall01",
                             {"State": Variant("s", "incoming"),
                              "LineIdentification":
                                  Variant("s", "+33612345678")}])
        await asyncio.sleep(9)
        await sig(bus, "/ril_0/voicecall01", "org.ofono.VoiceCall",
                  "PropertyChanged", "sv", ["State", Variant("s", "active")])
        await notify(bus, "WhatsApp", "Alice Martin", "Pendant l'appel")
        await asyncio.sleep(1)
        await sig(bus, "/ril_0", "org.ofono.VoiceCallManager", "CallRemoved",
                  "o", ["/ril_0/voicecall01"])
        await sig(bus, "/ril_0", "org.ofono.VoiceCallManager", "CallAdded",
                  "oa{sv}", ["/ril_0/voicecall02",
                             {"State": Variant("s", "incoming"),
                              "LineIdentification": Variant("s", "")}])
        await asyncio.sleep(2.5)
        await sig(bus, "/ril_0", "org.ofono.VoiceCallManager", "CallRemoved",
                  "o", ["/ril_0/voicecall02"])
    elif steps == "summary":
        await sig(bus, "/org/notivox", "org.notivox.Control", "Summary", "",
                  [])
    elif steps == "summary-speaker":
        await sig(bus, "/org/notivox", "org.notivox.Control", "Summary", "s",
                  ["speaker"])
    elif steps == "control":
        await sig(bus, "/org/notivox", "org.notivox.Control", "Pause", "i",
                  [30])
        await asyncio.sleep(1.5)
        await notify(bus, "WhatsApp", "Alice Martin", "En pause")
        await sig(bus, "/org/notivox", "org.notivox.Control", "Resume", "",
                  [])
        await asyncio.sleep(1.5)
        await sig(bus, "/org/notivox", "org.notivox.Control", "Say", "ss",
                  ["Texte libre envoyé par Situations", ""])
    await asyncio.sleep(float(sys.argv[2]) if len(sys.argv) > 2 else 8)

asyncio.run(main())
