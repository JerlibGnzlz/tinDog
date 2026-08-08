# Módulo 6 — Notificaciones push (FCM)

## Objetivo
Avisar al usuario cuando:
1. Hay un **match** nuevo
2. Llega un **mensaje** de chat (app en background / cerrada)

## Entra
| Área | Entregable |
|---|---|
| App | `firebase_core` + `firebase_messaging` (Android) |
| App | Pedir permiso; `POST /devices` con FCM token |
| App | Tap en notificación → `/chats/:matchId` (match o mensaje) |
| API | Tabla `device_tokens` |
| API | `POST /devices`, `DELETE /devices` |
| API | Push al crear match (Firebase Admin) |
| API | `POST /webhooks/stream` — Stream `message.new` → FCM |

## Env
```
# Nest (.env.development — no commitear)
FIREBASE_PROJECT_ID=
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY=
STREAM_API_KEY=
STREAM_API_SECRET=
```

## Estado
**En progreso.** Push de **match** y **mensaje** (vía webhook Stream) en Android. Falta iOS (APNs).

## Webhook Stream → Nest → FCM

1. API con `rawBody` + `POST /webhooks/stream` (sin JWT; verifica `X-Signature` con `STREAM_API_SECRET`).
2. Evento `message.new` → busca el match (`channel_id` = `match-{uuid}`) → push al otro usuario:
   - Título: `Nuevo mensaje de {nombre}`
   - Body: texto / preview de adjunto
   - Data: `type=message`, `matchId=…`
3. Tap en la app → deep link `/chats/:matchId`.
4. Si el destinatario tiene ese chat abierto, la app avisa con `PUT /devices/active-chat` y Nest **omite** el push.

### Configurar en Stream Dashboard (local)

Stream necesita una URL **pública** HTTPS. En local:

```bash
# Terminal 1 — API
cd tindog-api && npm run start:dev

# Terminal 2 — túnel (ejemplo ngrok)
ngrok http 3000
# Copiá la URL https://xxxx.ngrok-free.app
```

En [Stream Dashboard](https://dashboard.getstream.io/) → tu app → **Chat** → **Webhooks**:

| Campo | Valor |
|---|---|
| Webhook URL | `https://xxxx.ngrok-free.app/webhooks/stream` |
| Events | marcar **`message.new`** (mínimo) |
| | (opcional: dejar el resto desmarcado) |

Guardar. Stream firmará con el API secret del mismo app; Nest valida con `STREAM_API_SECRET`.

Si la firma falla → 401 en Nest y Stream reintenta. Revisá que el secret coincida y que no haya proxy que altere el body.

### Cómo probar mensaje (Android)

1. API con `FIREBASE_*` + `STREAM_*` + túnel + webhook configurado
2. Emulador **A**: login, aceptar notificaciones, ir a home y poner app en **background**
3. Emulador **B** (u otro usuario): abrir el chat del match con A y enviar un texto
4. En A debe llegar: “Nuevo mensaje de {nombre}”
5. Tap → abre ese chat

Logs útiles en Nest:
- `Firebase Admin listo`
- `Stream Chat client listo`
- Si falla firma: `Firma webhook inválida`

## Cómo probar match (Android)
1. API con `FIREBASE_*` y `npm run start:dev` → log `Firebase Admin listo`
2. App: full reinstall (plugin nativo) + login → aceptar notificaciones
3. En log: `FCM token registrado…`
4. Otro usuario hace like mutuo → push “¡Es un match!”
5. Tap en la notificación → abre el chat

## NO entra aún
- Marketing push / campañas
- Email / SMS
- Rich media complejas
- iOS APNs
