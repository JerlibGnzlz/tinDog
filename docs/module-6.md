# Módulo 6 — Notificaciones push (FCM)

## Objetivo
Avisar al usuario cuando:
1. Hay un **match** nuevo
2. Llega un **mensaje** de chat (app en background / cerrada)

## Entra (cuando se implemente)
| Área | Entregable |
|---|---|
| App | `firebase_core` + `firebase_messaging` (Android + iOS) |
| App | Pedir permiso; guardar FCM token |
| API | `POST /devices` — registrar token por `userId` |
| API | Tabla `device_tokens` (user_id, token, platform, updated_at) |
| API | Enviar push al crear match y/o vía webhook Stream → Nest → FCM |
| App | Tap en notificación → abrir `/chats/:matchId` |

## Env (placeholders)
```
# Nest
FIREBASE_PROJECT_ID=
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY=

# App (FlutterFire / google-services)
# android/app/google-services.json
# ios/Runner/GoogleService-Info.plist
```

## NO entra aún
- Marketing push / campañas
- Email / SMS
- Rich media notifications complejas

## Estado
**Pendiente.** El chat realtime (Stream) ya funciona con la app abierta; falta push en background.

## Orden sugerido
1. Proyecto Firebase + configs Android/iOS
2. Guardar tokens en Nest
3. Push de match (Nest al crear match)
4. Push de mensaje (Stream webhook o Nest)
