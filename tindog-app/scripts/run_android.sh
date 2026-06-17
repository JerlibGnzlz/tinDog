#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

DEVICE_ID=$(flutter devices 2>/dev/null | grep -oE 'emulator-[0-9]+' | head -1 || true)

if [ -z "$DEVICE_ID" ]; then
  echo "No se encontró emulador Android."
  echo "Inicia uno en Android Studio → Device Manager y vuelve a intentar."
  exit 1
fi

echo "Dispositivo: $DEVICE_ID"
echo "API: http://10.0.2.2:3000 (host local desde el emulador)"
echo ""

flutter run \
  -d "$DEVICE_ID" \
  --dart-define-from-file=dart_defines/android_dev.json
