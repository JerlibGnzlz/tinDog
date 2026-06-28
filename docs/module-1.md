# Módulo 1 — Base & Auth

## Objetivo

Autenticación JWT, usuarios y perfiles básicos. Sin Docker, sin CI.

## API

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| POST | `/auth/register` | No | Registro email/password |
| POST | `/auth/login` | No | Login, devuelve JWT |
| POST | `/auth/forgot-password` | No | Solicitar código de reset (email) |
| POST | `/auth/reset-password` | No | Restablecer contraseña con código |
| GET | `/users/me` | Sí | Usuario + perfil |
| GET | `/profiles/me` | Sí | Perfil del usuario |
| PATCH | `/profiles/me` | Sí | Actualizar name, bio, location, avatarUrl |

### Ejemplo register

```json
POST /auth/register
{ "email": "user@example.com", "password": "password123" }

→ { "accessToken": "eyJ..." }
```

### Ejemplo forgot-password

```json
POST /auth/forgot-password
{ "email": "user@example.com" }

→ { "message": "Si el email está registrado, recibirás un código..." }
```

### Ejemplo reset-password

```json
POST /auth/reset-password
{ "email": "user@example.com", "code": "482913", "password": "nuevaPassword123" }

→ { "message": "Contraseña actualizada correctamente" }
```

### Ejemplo update profile

```json
PATCH /profiles/me
Authorization: Bearer <token>
{ "name": "Juan", "bio": "Amante de los perros", "location": "Madrid" }
```

## Base de datos

```sql
users:                 id, email, password_hash, created_at, updated_at
profiles:              id, user_id, name, bio, avatar_url, location, ...
password_reset_tokens: id, user_id, code_hash, attempts, expires_at, used_at, ...
```

Migración: `cd tindog-api && npm run db:migrate:dev`

### Email (reset de contraseña)

Variables en `.env.development` / `.env.production`:

- `PASSWORD_RESET_PEPPER` — secreto para hashear códigos
- `RESEND_API_KEY` — envío de correos (Resend)
- `MAIL_FROM` — remitente
- `PASSWORD_RESET_CODE_TTL_MINUTES` — default 15

En **dev** sin `RESEND_API_KEY`, el código se imprime en la consola de la API.

## App Flutter

- `/login`, `/register`, `/forgot-password`, `/reset-password` — rutas públicas
- `/home` — placeholder post-login
- `/profile` — editar perfil
- Token en `flutter_secure_storage`

## Criterios de aceptación

- [ ] Registro + login devuelven JWT
- [ ] Rutas protegidas rechazan sin token (401)
- [ ] Perfil editable desde la app
- [ ] Password nunca en responses
- [ ] Recuperación de contraseña con código por email

## Fuera de alcance

Docker, CI, likes, matches, chat, pagos, Firebase, Stream.
