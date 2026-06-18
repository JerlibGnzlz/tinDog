# tinDog App

App Flutter del Módulo 1.

## Requisitos

- API corriendo: `cd ../tindog-api && npm run start:dev`
- Emulador Android iniciado (Android Studio → Device Manager) **o** Mac con Xcode (iOS)

## Levantar en emulador Android (recomendado en Linux)

```bash
./scripts/run_android.sh
```

Detecta el emulador automáticamente y usa `http://10.0.2.2:3000` para la API local.

## Levantar en iOS (requiere Mac + Xcode)

```bash
# Simulador (API en la misma Mac)
./scripts/run_ios.sh

# iPhone físico: copia y edita la IP de tu Mac en la red Wi‑Fi
cp dart_defines/ios_device_dev.example.json dart_defines/ios_device_dev.json
./scripts/run_ios.sh device
```

Manual:

```bash
flutter run -d ios --dart-define-from-file=dart_defines/ios_dev.json
```

> En iPhone físico usa `dart_defines/ios_device_dev.json` con `http://<IP-de-tu-Mac>:3000`.
> Mac e iPhone deben estar en la misma red Wi‑Fi.

## Desde Cursor / VS Code

Run and Debug → **tinDog App (Android Emulator)**

Selecciona el emulador cuando Flutter lo pida.

## Manual (Android)

```bash
flutter run -d emulator-5554 --dart-define-from-file=dart_defines/android_dev.json
```

> El id del emulador puede variar. Lista dispositivos: `flutter devices`

## URLs por plataforma

| Plataforma | API local |
|------------|-----------|
| Android emulator | `http://10.0.2.2:3000` |
| iOS simulator | `http://localhost:3000` |
| iPhone físico | `http://<IP-de-tu-Mac>:3000` |
| Linux desktop | `http://localhost:3000` |

Config en `dart_defines/android_dev.json`, `dart_defines/ios_dev.json` y `dart_defines/linux_dev.json`.
