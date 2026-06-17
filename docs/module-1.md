# Módulo 1 — Base & Auth

## Objetivo

Autenticación JWT, usuarios y perfiles básicos. Sin Docker, sin CI.

## API

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| POST | `/auth/register` | No | Registro email/password |
| POST | `/auth/login` | No | Login, devuelve JWT |
| GET | `/users/me` | Sí | Usuario + perfil |
| GET | `/profiles/me` | Sí | Perfil del usuario |
| PATCH | `/profiles/me` | Sí | Actualizar name, bio, location, avatarUrl |

### Ejemplo register

```json
POST /auth/register
{ "email": "user@example.com", "password": "password123" }

→ { "accessToken": "eyJ..." }
```

### Ejemplo update profile

```json
PATCH /profiles/me
Authorization: Bearer <token>
{ "name": "Juan", "bio": "Amante de los perros", "location": "Madrid" }
```

## Base de datos

```sql
users:    id, email, password_hash, created_at, updated_at
profiles: id, user_id, name, bio, avatar_url, location, created_at, updated_at
```

Migración: `cd tindog-api && npx prisma migrate dev`

## App Flutter

- `/login`, `/register` — rutas públicas
- `/home` — placeholder post-login
- `/profile` — editar perfil
- Token en `flutter_secure_storage`

## Criterios de aceptación

- [ ] Registro + login devuelven JWT
- [ ] Rutas protegidas rechazan sin token (401)
- [ ] Perfil editable desde la app
- [ ] Password nunca en responses

## Fuera de alcance

Docker, CI, pets, likes, matches, chat, pagos, Cloudinary, Firebase, Stream.
