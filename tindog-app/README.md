# tinDog App

App Flutter del Módulo 1.

## Requisitos

- API corriendo: `cd ../tindog-api && npm run start:dev`
- Emulador Android iniciado (Android Studio → Device Manager)

## Levantar en emulador Android (recomendado)

```bash
./scripts/run_android.sh
```

Detecta el emulador automáticamente y usa `http://10.0.2.2:3000` para la API local.

## Desde Cursor / VS Code

Run and Debug → **tinDog App (Android Emulator)**

Selecciona el emulador cuando Flutter lo pida.

## Manual

```bash
flutter run -d emulator-5554 --dart-define-from-file=dart_defines/android_dev.json
```

> El id del emulador puede variar. Lista dispositivos: `flutter devices`

## URLs por plataforma

| Plataforma | API local |
|------------|-----------|
| Android emulator | `http://10.0.2.2:3000` |
| Linux / iOS simulator | `http://localhost:3000` |

Config en `dart_defines/android_dev.json` y `dart_defines/linux_dev.json`.
