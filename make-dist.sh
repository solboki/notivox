#!/bin/sh
# Construit le paquet Sailfish OS (aarch64) et l'archive des sources dans
# dist/. À lancer sur un ordinateur Debian ou Ubuntu :
#   sudo apt install rpm gcc-aarch64-linux-gnu curl qttools5-dev-tools
set -e
cd "$(dirname "$0")"
V=1.7.1
PIPER_URL=https://github.com/rhasspy/piper/releases/download/2023.11.14-2/piper_linux_aarch64.tar.gz
DEB=https://deb.debian.org/debian/pool/main/g/gcc-10
TOP=$(pwd)

# 1. Piper pour ARM 64 bits, avec une libstdc++ plus récente que celle de
#    Sailfish OS (libpiper_phonemize en demande la version 3.4.26).
mkdir -p vendor
if [ ! -f vendor/piper-aarch64.tar.gz ]; then
    W=$(mktemp -d)
    curl -fsSL "$PIPER_URL" | tar -xz -C "$W"
    for p in libstdc++6_10.2.1-6_arm64.deb libgcc-s1_10.2.1-6_arm64.deb; do
        curl -fsSL -o "$W/$p" "$DEB/$p"
        mkdir -p "$W/x" && dpkg-deb -x "$W/$p" "$W/x"
    done
    cp "$W/x/usr/lib/aarch64-linux-gnu/libstdc++.so.6.0.28" "$W/piper/libstdc++.so.6"
    cp "$W/x/lib/aarch64-linux-gnu/libgcc_s.so.1" "$W/piper/"
    rm -rf "$W/piper/pkgconfig" "$W/piper/piper_phonemize"
    chmod 755 "$W/piper/piper" "$W/piper/espeak-ng"
    tar -C "$W" -czf vendor/piper-aarch64.tar.gz piper
    rm -rf "$W"
fi

# 2. Assistant de lecture des bases protégées (carnet, notifications),
#    lié statiquement.
mkdir -p build
aarch64-linux-gnu-gcc -O2 -static -Wall -Wno-format-truncation \
    -o build/notivox-helper sailfish/notivox-helper.c
aarch64-linux-gnu-strip build/notivox-helper

# 3. Traductions du titre de la page des Paramètres.
LRELEASE=$(command -v lrelease-qt5 || ls /usr/lib/*/qt5/bin/lrelease 2>/dev/null | head -1 || command -v lrelease)
for f in translations/*.ts; do "$LRELEASE" -idbased -silent "$f" -qm "${f%.ts}.qm"; done

# 4. Archive des sources et paquet RPM.
rm -rf dist rpmbuild
mkdir -p dist rpmbuild/SOURCES rpmbuild/SPECS
tar --transform "s,^\.,notivox-$V," \
    --exclude=./dist --exclude=./rpmbuild --exclude=./vendor \
    --exclude=./.git --exclude='__pycache__' \
    -czf "rpmbuild/SOURCES/notivox-$V.tar.gz" .
cp vendor/piper-aarch64.tar.gz rpmbuild/SOURCES/
cp "rpmbuild/SOURCES/notivox-$V.tar.gz" dist/
rpmbuild --define "_topdir $TOP/rpmbuild" --target aarch64 \
    -bb rpm/notivox.spec
cp rpmbuild/RPMS/aarch64/notivox-$V-1.aarch64.rpm dist/
rm -rf rpmbuild
ls -l dist
