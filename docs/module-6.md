# Módulo 6 — Notificaciones push (FCM)

## Objetivo
Avisar al usuario cuando:
1. Hay un **match** nuevo
2. Llega un **mensaje** de chat (app en background / cerrada) — pendiente

## Entra
| Área | Entregable |
|---|---|
| App | `firebase_core` + `firebase_messaging` (Android) |
| App | Pedir permiso; `POST /devices` con FCM token |
| App | Tap en notificación de match → `/chats/:matchId` |
| API | Tabla `device_tokens` |
| API | `POST /devices`, `DELETE /devices` |
| API | Push al crear match (Firebase Admin) |

## Env
```
# Nest (.env.development — no commitear)
FIREBASE_PROJECT_ID=
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY=

# App
# android/app/google-services.json
```

## Estado
**En progreso.** Push de **match** listo en Android. Falta push de **mensaje** (Stream webhook → Nest → FCM) e iOS (APNs).

## Cómo probar (Android)
1. API con `FIREBASE_*` y `npm run start:dev` → log `Firebase Admin listo`
2. App: full reinstall (plugin nativo) + login → aceptar notificaciones
3. En log: `FCM token registrado…`
4. Otro usuario hace like mutuo → push “¡Es un match!”
5. Tap en la notificación → abre el chat

## NO entra aún
- Marketing push / campañas
- Email / SMS
- Rich media complejas
