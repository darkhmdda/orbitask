#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BUNDLE="$ROOT/build/linux/x64/release/bundle"
STAGE="$ROOT/build/deb/orbitask"
PUBSPEC_VERSION="$(awk '/^version:/ {print $2; exit}' "$ROOT/pubspec.yaml")"
APP_VERSION="${PUBSPEC_VERSION%%+*}"
OUTPUT_DIR="$ROOT/installer/linux/output"
OUTPUT="$OUTPUT_DIR/Orbitask-v${APP_VERSION}-linux-amd64.deb"

if [ ! -x "$BUNDLE/orbitask" ]; then
  echo "Error: no existe una build release de Linux."
  echo "Ejecuta primero: flutter build linux --release ..."
  exit 1
fi

rm -rf "$STAGE"
mkdir -p "$OUTPUT_DIR"

mkdir -p "$STAGE/DEBIAN"
mkdir -p "$STAGE/opt/orbitask"
mkdir -p "$STAGE/usr/bin"
mkdir -p "$STAGE/usr/share/applications"
mkdir -p "$STAGE/usr/share/icons/hicolor/256x256/apps"

cp "$ROOT/installer/linux/DEBIAN/control" "$STAGE/DEBIAN/control"
sed -i "s/^Version:.*/Version: $APP_VERSION/" "$STAGE/DEBIAN/control"
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
