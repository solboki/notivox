/*
 * notivox-helper : copie dans ~/.cache/notivox/ une base protégée de
 * Sailfish OS, pour que le service Notivox puisse la lire :
 *   notivox-helper contacts       le carnet d'adresses (nom de l'appelant)
 *   notivox-helper notifications  les notifications de la Vue Événements
 *   notivox-helper calendar       l'agenda (rendez-vous du jour)
 * Sans argument, c'est le carnet d'adresses.
 *
 * Ces bases sont réservées au groupe « privileged ». Ce programme est
 * installé avec ce groupe (setgid). Il n'accepte que ces deux mots : il
 * ouvre uniquement la base de l'utilisateur qui le lance, abandonne
 * aussitôt le droit « privileged », puis écrit la copie, lisible par cet
 * utilisateur seul.
 *
 * Licence : GPL-3.0-or-later.
 */
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#define DST "/.cache/notivox/"

struct base {
    const char *word;     /* argument accepté */
    const char *dir;      /* dossier de la base, sous le dossier personnel */
    const char *names[2]; /* la base et son journal (mode WAL) */
    const char *copies[2]; /* noms des copies dans ~/.cache/notivox */
};

static const struct base bases[] = {
    { "contacts", "/.local/share/system/privileged/Contacts/qtcontacts-sqlite/",
      { "contacts.db", "contacts.db-wal" },
      { "contacts.db", "contacts.db-wal" } },
    { "notifications", "/.local/share/system/privileged/Notifications/",
      { "notifications.db", "notifications.db-wal" },
      { "notifications.db", "notifications.db-wal" } },
    { "calendar", "/.local/share/system/privileged/Calendar/mkcal/",
      { "db", "db-wal" },
      { "calendar.db", "calendar.db-wal" } },
};

/* Dossier personnel de l'utilisateur réel, lu dans /etc/passwd. On ne se
 * fie pas à $HOME, que l'appelant contrôle, et on évite getpwuid(), qui
 * fonctionne mal dans un programme lié statiquement. */
static int home_of(uid_t uid, char *out, size_t len)
{
    FILE *f = fopen("/etc/passwd", "r");
    char line[1024];

    if (!f)
        return -1;
    while (fgets(line, sizeof line, f)) {
        char *field[7];
        char *p = line;
        int i;

        for (i = 0; i < 7 && p; i++) {
            field[i] = p;
            p = strchr(p, ':');
            if (p)
                *p++ = 0;
        }
        if (i < 6)
            continue;
        if ((uid_t)strtoul(field[2], NULL, 10) == uid) {
            snprintf(out, len, "%s", field[5]);
            fclose(f);
            return out[0] == '/' ? 0 : -1;
        }
    }
    fclose(f);
    return -1;
}

int main(int argc, char **argv)
{
    char home[1024];
    int in[2], i, ok = 0;
    char path[4096];
    const struct base *b = &bases[0];
    const char *const *names;

    if (argc > 1) {
        b = NULL;
        for (i = 0; i < (int)(sizeof bases / sizeof bases[0]); i++)
            if (strcmp(argv[1], bases[i].word) == 0)
                b = &bases[i];
        if (!b)
            return 2;
    }
    names = b->names;

    if (home_of(getuid(), home, sizeof home) != 0)
        return 1;

    for (i = 0; i < 2; i++) {
        snprintf(path, sizeof path, "%s%s%s", home, b->dir, names[i]);
        in[i] = open(path, O_RDONLY | O_NOFOLLOW);
    }

    /* Plus besoin du droit « privileged » : on le rend. */
    if (setgid(getgid()) != 0)
        return 1;

    snprintf(path, sizeof path, "%s/.cache", home);
    mkdir(path, 0700);
    snprintf(path, sizeof path, "%s" DST, home);
    mkdir(path, 0700);

    for (i = 0; i < 2; i++) {
        char tmp[4400], fin[4200];
        char buf[65536];
        ssize_t n;
        int out;

        snprintf(fin, sizeof fin, "%s" DST "%s", home, b->copies[i]);
        if (in[i] < 0) {
            unlink(fin);
            continue;
        }
        snprintf(tmp, sizeof tmp, "%s.tmp", fin);
        out = open(tmp, O_WRONLY | O_CREAT | O_TRUNC | O_NOFOLLOW, 0600);
        if (out < 0)
            continue;
        while ((n = read(in[i], buf, sizeof buf)) > 0)
            if (write(out, buf, n) != n)
                break;
        close(out);
        close(in[i]);
        if (rename(tmp, fin) == 0 && i == 0)
            ok = 1;
    }
    return ok ? 0 : 1;
}
