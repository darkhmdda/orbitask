#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

: "${SUPABASE_URL:?Define SUPABASE_URL antes de crear una release}"
: "${SUPABASE_PUBLISHABLE_KEY:?Define SUPABASE_PUBLISHABLE_KEY antes de crear una release}"

SUPABASE_AUTH_REDIRECT_URL="${SUPABASE_AUTH_REDIRECT_URL:-https://github.com/darkhmdda/orbitask}"

cd "$ROOT"

flutter build linux --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_PUBLISHABLE_KEY="$SUPABASE_PUBLISHABLE_KEY" \
  --dart-define=SUPABASE_AUTH_REDIRECT_URL="$SUPABASE_AUTH_REDIRECT_URL"

bash installer/linux/build_deb.sh
