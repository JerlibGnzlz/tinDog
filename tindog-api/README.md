# tinDog API

Backend NestJS del Módulo 1.

## Ambientes

Usamos **dos bases de datos** separadas: desarrollo y producción.

Ver guía completa: [docs/environments.md](../docs/environments.md)

## Setup

```bash
cp .env.development.example .env.development
cp .env.production.example .env.production
# Cada archivo necesita DATABASE_URL (pooler) y DIRECT_URL (sin pooler)
npm install
npm run db:migrate:dev
npm run db:seed:dev
npm run start:dev
```

## Comandos

| Comando | Ambiente |
|---------|----------|
| `npm run start:dev` | API desarrollo |
| `npm run start:prod` | API producción |
| `npm run db:migrate:dev` | Migrar en dev |
| `npm run db:migrate:prod` | Migrar en prod |
| `npm run db:seed:dev` | Datos de prueba (solo dev) |

## Datos de prueba (solo dev)

```bash
npm run db:seed:dev
```

| Email | Contraseña |
|-------|------------|
| `ana@tindog.test` | `password123` |
| `lucas@tindog.test` | `password123` |
| `sofia@tindog.test` | `password123` |
| `diego@tindog.test` | `password123` |
| `valentina@tindog.test` | `password123` |

## Módulos

- `auth` — register, login, JWT
- `users` — GET /users/me
- `profiles` — GET/PATCH /profiles/me
- `prisma` — acceso a PostgreSQL
