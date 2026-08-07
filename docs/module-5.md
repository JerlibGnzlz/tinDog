# Módulo 5 — Chat (Stream)

## Entra
| Área | Entregable |
|---|---|
| API | `GET /chat/token` — JWT Stream firmado con Secret |
| API | `POST /chat/channels/:matchId/ensure` — canal `messaging` / `match-{uuid}` |
| API | Al crear match → canal Stream (best-effort) |
| App | `stream_chat_flutter` — realtime, online, typing, adjuntos |
| App | Hilo `/chats/:matchId` con SDK Stream + icebreakers TinDog |

## Env
```
STREAM_API_KEY=...
STREAM_API_SECRET=...   # solo Nest
```
Flutter dart_defines: solo `STREAM_API_KEY` (opcional; la key también viene en `/chat/token`).

## Cómo probar
1. Reiniciar API (`npm run start:dev`) — log: `Stream Chat client listo`
2. App con sesión + `--dart-define-from-file=dart_defines/android_dev.json`
3. Abrir un match en Chats → debe conectar Stream
4. Dos emuladores: ver **Online** / **typing** y mensajes al instante
5. Adjuntar foto/video desde el composer de Stream

## Notas
- Usuario Stream = `user.id` de tinDog; `name`/`image` = mascota
- Listado Chats sigue en Nest (`GET /matches`); preview de último mensaje prioriza Stream
- Chat HTTP local (`chat_messages`) queda como legado; hilos nuevos usan Stream

## NO entra aún
- Push notifications Stream/Firebase — ver [module-6.md](./module-6.md)
- Traducciones ES del SDK (`stream_chat_localizations`)
- Migración masiva de `chat_messages` históricos a Stream

## Seguridad
Bloquear / reportar: [module-safety.md](./module-safety.md)
