#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

: "${SUPABASE_URL:?Define SUPABASE_URL antes de crear una release}"
: "${SUPABASE_PUBLISHABLE_KEY:?Define SUPABASE_PUBLISHABLE_KEY antes de crear una release}"

SUPABASE_AUTH_REDIRECT_URL="${SUPABASE_AUTH_REDIRECT_URL:-com.darkhmdda.orbitask://login-callback}"

if [ ! -f "$ROOT/android/key.properties" ]; then
  echo "Error: falta android/key.properties para firmar la release."
  exit 1
fi

cd "$ROOT"

flutter build apk --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY" \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL="$SUPABASE_AUTH_REDIRECT_URL"

echo
echo "APK creado:"
ls -lh build/app/outputs/flutter-apk/app-release.apk
