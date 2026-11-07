"""Crée une fausse base d'agenda au format mkcal (Sailfish), pour tester
la lecture des rendez-vous du jour (samedi 7 novembre 2026).
Usage : python3 make_calendar_db.py base.db"""
import calendar
import datetime
import sqlite3
import sys


def utc(*a):
    return calendar.timegm(datetime.datetime(*a).timetuple())


db = sqlite3.connect(sys.argv[1])
db.execute("CREATE TABLE Calendars(CalendarId TEXT PRIMARY KEY, Name TEXT, Flags INTEGER)")
db.execute("CREATE TABLE Components(ComponentId INTEGER PRIMARY KEY, Notebook TEXT, Type TEXT, Summary TEXT,"
           " DateStart INTEGER, DateStartLocal INTEGER, StartTimeZone TEXT, UID TEXT, RecurId INTEGER,"
           " RecurIdLocal INTEGER, RecurIdTimeZone TEXT, DateDeleted INTEGER)")
db.execute("CREATE TABLE Recursive(ComponentId INTEGER, RuleType INTEGER, Frequency INTEGER, Until INTEGER,"
           " UntilLocal INTEGER, untilTimeZone TEXT, Count INTEGER, Interval INTEGER, BySecond TEXT, ByMinute TEXT,"
           " ByHour TEXT, ByDay TEXT, ByDayPos TEXT, ByMonthDay TEXT, ByYearDay TEXT, ByWeekNum TEXT, ByMonth TEXT,"
           " BySetPos TEXT, WeekStart INTEGER)")
db.execute("CREATE TABLE Rdates(ComponentId INTEGER, Type INTEGER, Date INTEGER, DateLocal INTEGER, TimeZone TEXT)")
db.execute("INSERT INTO Calendars VALUES ('perso', 'Perso', 129), ('cache', 'Masqué', 1)")


def ev(cid, title, local, tz="", nb="perso", uid=None, recur=None, deleted=0):
    db.execute("INSERT INTO Components VALUES (?,?,?,?,?,?,?,?,?,?,?,?)",
               (cid, nb, "Event", title, utc(*local), utc(*local), tz, uid or "u%d" % cid,
                0, utc(*recur) if recur else 0, "" if not recur else tz, deleted))


def rule(cid, freq, interval=1, byday="", bydaypos="", count=0, until=None, bymonthday=""):
    db.execute("INSERT INTO Recursive (ComponentId, RuleType, Frequency, Until, UntilLocal, untilTimeZone, Count,"
               " Interval, ByDay, ByDayPos, ByMonthDay, ByMonth) VALUES (?,1,?,?,?,?,?,?,?,?,?,'')",
               (cid, freq, utc(*until) if until else 0, utc(*until) if until else 0, "", count, interval,
                byday, bydaypos, bymonthday))


ev(1, "Déjeuner avec Alice", (2026, 11, 7, 12, 30))           # après midi : lu
ev(2, "Café du matin", (2026, 11, 7, 9, 0))                  # déjà passé
ev(3, "Anniversaire de papa", (2026, 11, 7, 0, 0), "FloatingDate")  # journée entière
ev(4, "Piscine", (2026, 9, 5, 18, 0)); rule(4, 5, byday="6")  # chaque samedi 18 h
ev(5, "Marché", (2026, 1, 3, 16, 0)); rule(5, 6, byday="6", bydaypos="1")  # 1er samedi du mois
ev(6, "Cours de guitare", (2026, 10, 3, 15, 0)); rule(6, 5, byday="6")
db.execute("INSERT INTO Rdates VALUES (6, 4, ?, ?, '')", (utc(2026, 11, 7, 15, 0), utc(2026, 11, 7, 15, 0)))  # annulé aujourd'hui
ev(7, "Réunion secrète", (2026, 11, 7, 17, 0), nb="cache")    # agenda masqué
ev(8, "Rendez-vous supprimé", (2026, 11, 7, 17, 0), deleted=1)
ev(9, "Kiné", (2026, 11, 1, 19, 0)); rule(9, 4, count=3)       # 1er au 3 novembre seulement
ev(10, "Chorale", (2026, 10, 10, 20, 0), uid="cho"); rule(10, 5, byday="6")
ev(11, "Chorale", (2026, 11, 7, 21, 0), uid="cho", recur=(2026, 11, 7, 20, 0))  # déplacée à 21 h
ev(12, "Tous les 15 jours", (2026, 10, 31, 14, 0)); rule(12, 5, interval=2, byday="6")  # pas ce samedi
db.commit()
