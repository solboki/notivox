/*
 * notivox-contacts : copie le carnet d'adresses de Sailfish OS dans
 * ~/.cache/notivox/, pour que le service Notivox puisse y chercher le nom
 * de la personne qui appelle.
 *
 * Le carnet est réservé au groupe « privileged ». Ce programme est installé
 * avec ce groupe (setgid). Il n'accepte aucun argument : il ouvre
 * uniquement le carnet de l'utilisateur qui le lance, abandonne aussitôt
 * le droit « privileged », puis écrit la copie, lisible par cet
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

#define SRC "/.local/share/system/privileged/Contacts/qtcontacts-sqlite/"
#define DST "/.cache/notivox/"

static const char *names[] = { "contacts.db", "contacts.db-wal" };

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

int main(void)
{
    char home[1024];
    int in[2], i, ok = 0;
    char path[4096];

    if (home_of(getuid(), home, sizeof home) != 0)
        return 1;

    for (i = 0; i < 2; i++) {
        snprintf(path, sizeof path, "%s" SRC "%s", home, names[i]);
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

        snprintf(fin, sizeof fin, "%s" DST "%s", home, names[i]);
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
