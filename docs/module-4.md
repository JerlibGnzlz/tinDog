# Módulo 4 — Matching & Discovery

## Entra en este módulo
| Área | Entregable |
|---|---|
| App | Pantalla discovery tipo swipe (`/discover`) |
| App | Mostrar otros: nombre, edad, ubicación, distancia |
| App | Acciones like / pass persistidas |
| API | `GET /discover` |
| API | `POST /likes`, `POST /passes` |
| DB | Tablas `likes`, `passes`, `matches` |

## Chat media (preparado para Stream)
- Mensajes: `type` = `text` | `image` | `video`
- Campos: `mediaUrl`, `mediaPublicId`, `thumbnailUrl`, `durationSec`
- Flujo app: subir a Cloudinary (`/media/upload` o `/media/upload-video`) → `POST /matches/:id/messages`
- Al migrar a Stream: mapear estos attachments al SDK; el upload puede seguir en Cloudinary o usar el de Stream

- `GET /matches` — threads con otherPet + lastMessage
- `GET/POST /matches/:id/messages` — chat propio (tabla `chat_messages`)
- App `/chats` (Matches nuevos + Mensajes) y `/chats/:matchId` (hilo)
- Bottom nav: Desliza · Likes · **Chats** · Perfil

## Cómo probar chat
1. Dos usuarios se dan like mutuo → match
2. Tab **Chats** → aparece en **Matches nuevos**
3. Tocá el match → escribí mensaje → pasa a **Mensajes**

## NO entra todavía
- Geolocalización real
- Rewind / super like / Top Picks real

## Chat realtime
Ver [module-5.md](./module-5.md) — Stream Chat (online, typing, adjuntos).

## Próximo slice
1. ~~Like back desde grilla de likes recibidos~~ (hecho en app)
2. Push — ver [module-6.md](./module-6.md)
3. Localización ES del SDK Stream
4. Geolocalización real / Rewind / Super like / Top Picks
