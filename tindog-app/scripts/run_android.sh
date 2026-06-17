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
adb reverse tcp:3000 tcp:3000 2>/dev/null || true

# Liberar espacio en el emulador (evita INSTALL_FAILED_INSUFFICIENT_STORAGE)
adb shell pm trim-caches 999999M 2>/dev/null || true
adb uninstall com.tindog.tindog_app 2>/dev/null || true

FREE_KB=$(adb shell df /data 2>/dev/null | awk 'NR==2 {print $4}' | tr -d '\r')
if [ -n "$FREE_KB" ] && [ "$FREE_KB" -lt 200000 ] 2>/dev/null; then
  echo ""
  echo "⚠ Poco espacio en el emulador (~$((FREE_KB / 1024)) MB libres)."
  echo "  Android Studio → Device Manager → tu AVD → Wipe Data"
  echo "  o desinstala apps que no uses en el emulador."
  echo ""
fi

echo "API: http://10.0.2.2:3000 (host local desde el emulador)"
echo "Reinicio completo requerido si cambiaste la URL (no uses hot reload)."
echo ""

flutter run \
  -d "$DEVICE_ID" \
  --dart-define-from-file=dart_defines/android_dev.json
