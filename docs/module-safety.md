# Módulo — Seguridad (bloquear / reportar)

## Objetivo
Permitir que un usuario **reporte** o **bloquee** a otro antes de publicar en tiendas.

## API
| Método | Ruta | Descripción |
|---|---|---|
| `POST` | `/safety/blocks` | `{ userId }` — bloquea; limpia likes/match |
| `DELETE` | `/safety/blocks/:userId` | Desbloquea |
| `GET` | `/safety/blocks` | Lista de bloqueados |
| `POST` | `/safety/reports` | `{ userId, reason, details?, matchId?, blockAlso? }` |

### Reasons
`spam` · `harassment` · `inappropriate` · `fake` · `other`

## Efectos del bloqueo
- No aparece en Desliza / Likes / Chats (ambos sentidos)
- Se elimina el match y likes entre sus mascotas
- Se crea un pass para quien bloqueó
- No se puede abrir canal Stream (`ensure`)

## App
- Escudo en lista **Chats** → info de seguridad
- Escudo en **hilo de chat** → Reportar / Bloquear
- Perfil → Ajustes → **Bloqueados** → listar / desbloquear

## DB
Tablas `user_blocks`, `user_reports` (migración `20260807223000_user_blocks_reports`).

## NO entra aún
- Panel admin para revisar reportes
- Moderación automática / ban global
