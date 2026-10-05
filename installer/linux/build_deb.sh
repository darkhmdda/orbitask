#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUNDLE="$ROOT/build/linux/x64/release/bundle"
STAGE="$ROOT/build/deb/orbitask"
OUTPUT="$ROOT/Orbitask-v0.9-linux-amd64.deb"

if [ ! -x "$BUNDLE/orbitask" ]; then
  echo "Error: no existe una build release de Linux."
  echo "Ejecuta primero: flutter build linux --release ..."
  exit 1
fi

rm -rf "$STAGE"

mkdir -p "$STAGE/DEBIAN"
mkdir -p "$STAGE/opt/orbitask"
mkdir -p "$STAGE/usr/bin"
mkdir -p "$STAGE/usr/share/applications"
mkdir -p "$STAGE/usr/share/icons/hicolor/256x256/apps"

cp "$ROOT/installer/linux/DEBIAN/control" "$STAGE/DEBIAN/control"
cp -a "$BUNDLE/." "$STAGE/opt/orbitask/"
cp "$ROOT/installer/linux/usr/share/applications/orbitask.desktop" \
   "$STAGE/usr/share/applications/orbitask.desktop"
cp "$ROOT/linux/runner/resources/orbitask.png" \
   "$STAGE/usr/share/icons/hicolor/256x256/apps/orbitask.png"

ln -s /opt/orbitask/orbitask "$STAGE/usr/bin/orbitask"

chmod 644 "$STAGE/DEBIAN/control"
chmod 755 "$STAGE/opt/orbitask/orbitask"
chmod 644 "$STAGE/usr/share/applications/orbitask.desktop"
chmod 644 "$STAGE/usr/share/icons/hicolor/256x256/apps/orbitask.png"

dpkg-deb --root-owner-group --build "$STAGE" "$OUTPUT"

echo
echo "Paquete creado:"
ls -lh "$OUTPUT"
