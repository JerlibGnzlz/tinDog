#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

MODE="${1:-simulator}"

if [ "$MODE" = "device" ]; then
  DEFINES_FILE="dart_defines/ios_device_dev.json"
  if [ ! -f "$DEFINES_FILE" ]; then
    echo "Falta $DEFINES_FILE"
    echo "Copia el ejemplo y pon la IP de tu Mac en la red local:"
    echo "  cp dart_defines/ios_device_dev.example.json dart_defines/ios_device_dev.json"
    echo "  # edita API_BASE_URL → http://<IP-de-tu-Mac>:3000"
    exit 1
  fi
  DEVICE_ID=$(flutter devices 2>/dev/null | grep -i 'ios' | grep -v 'simulator' | awk -F '•' '{print $2}' | xargs | head -1 || true)
  if [ -z "$DEVICE_ID" ]; then
    echo "No se encontró iPhone físico conectado."
    echo "Conecta el iPhone por USB, confía en el Mac y vuelve a intentar."
    exit 1
  fi
  echo "Modo: iPhone físico"
else
  DEFINES_FILE="dart_defines/ios_dev.json"
  DEVICE_ID=$(flutter devices 2>/dev/null | grep -i 'simulator' | awk -F '•' '{print $2}' | xargs | head -1 || true)
  if [ -z "$DEVICE_ID" ]; then
    echo "No se encontró simulador iOS."
    echo "Abre Xcode → Open Developer Tool → Simulator, o:"
    echo "  open -a Simulator"
    exit 1
  fi
  echo "Modo: simulador iOS"
fi

echo "Dispositivo: $DEVICE_ID"
echo "Defines: $DEFINES_FILE"
echo "API debe estar corriendo: cd ../tindog-api && npm run start:dev"
echo ""

flutter run \
  -d "$DEVICE_ID" \
  --dart-define-from-file="$DEFINES_FILE"
