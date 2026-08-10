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

## Explorar
- Tab **Explorar** con dos bloques:
  1. **Buscar perros** — atajos a Desliza (`near`, `breed`, `play`, `for_you`)
  2. **Servicios cerca** — Veterinarias / Paseos / Refugios / PET shops (UI “próximamente”; sin Places aún)
- Atajo de perros → aplica `discoverFiltersProvider` y navega a `/discover`

## Matches & Chats (lista)
- `GET /matches` — threads con otherPet + lastMessage (preview desde **Stream**)
- `DELETE /matches/:id` — unmatch (borra match + canal Stream; no bloquea)
- App `/chats` (Matches nuevos + Mensajes) y `/chats/:matchId` (hilo Stream)
- App: swipe para eliminar conversación; menú ⋮ en el hilo
- Bottom nav: Desliza · Likes · **Chats** · Perfil

## Cómo probar
1. Dos usuarios se dan like mutuo → match
2. Tab **Chats** → aparece en **Matches nuevos**
3. Tocá el match → chat Stream

## Chat realtime
Ver [module-5.md](./module-5.md) — Stream Chat (única fuente de mensajes).

## NO entra todavía
- Rewind / super like / Top Picks real
