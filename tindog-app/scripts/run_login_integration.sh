#!/usr/bin/env bash
# Login real contra API local + seed (ana@tindog.test / password123).
# Requiere: API en :3000, seed aplicado, emulador/dispositivo.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DEVICE="${1:-emulator-5554}"

echo "→ Comprobando API + seed (ana@tindog.test)…"
BODY="$(curl -s -X POST "http://localhost:3000/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"ana@tindog.test\",\"password\":\"password123\"}" || true)"
if ! echo "$BODY" | grep -q accessToken; then
  echo "API no responde o seed ausente."
  echo "  cd ../tindog-api && npm run start:dev"
  echo "  cd ../tindog-api && npm run db:seed:dev"
  echo "Respuesta: $BODY"
  exit 1
fi

echo "→ Device: $DEVICE"
echo "→ dart_defines/android_dev.json (10.0.2.2 para emulador Android)"

flutter test integration_test/login_with_api_test.dart \
  -d "$DEVICE" \
  --dart-define-from-file=dart_defines/android_dev.json
