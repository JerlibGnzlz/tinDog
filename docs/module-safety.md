# Módulo — Seguridad (bloquear / reportar)

## Objetivo
Permitir que un usuario **reporte** o **bloquee** a otro antes de publicar en tiendas.

## API
| Método | Ruta | Descripción |
|---|---|---|
| `POST` | `/safety/blocks` | `{ userId }` — bloquea; limpia likes/match + canal Stream |
| `DELETE` | `/safety/blocks/:userId` | Desbloquea |
| `GET` | `/safety/blocks` | Lista de bloqueados |
| `POST` | `/safety/reports` | `{ userId, reason, details?, matchId?, blockAlso? }` |

### Reasons
`spam` · `harassment` · `inappropriate` · `fake` · `other`

## Efectos del bloqueo
- No aparece en Desliza / Likes / Chats (ambos sentidos)
- Se elimina el match y likes entre sus mascotas
- Se crea un pass para quien bloqueó
- Se **borra el canal Stream** del match (`messaging:match-{id}`) — best-effort
- No se puede volver a abrir canal Stream (`ensure` rechaza si hay bloqueo)
- En la app: se sale del hilo y se deja de watchar el canal

## App
- Escudo en lista **Chats** → info de seguridad
- Escudo en **hilo de chat** → Reportar / Bloquear
- **Desliza** → ficha del dueño → Reportar / Bloquear
- Perfil → Ajustes → **Bloqueados** / **Qué ven los demás**
- Tras eliminar un chat: feedback suave «¿Cómo fue el encuentro?» (no público)

## Confianza (señales)
- «Verificado con Google» si la cuenta tiene `google_sub`
- «Activo» solo si hubo actividad en los últimos 7 días
- Icebreakers orientados a lugares públicos
- Tip de parque seguro al matchear

## DB
Tablas `user_blocks`, `user_reports` (migración `20260807223000_user_blocks_reports`).

## NO entra aún
- Panel admin para revisar reportes
- Moderación automática / ban global
- Reviews públicas ni Places API (parques sugeridos: teaser UI)
