# tinDog

App de matching para mascotas — Flutter + NestJS + PostgreSQL.

## Estructura

```
.cursor/rules/   # Reglas persistentes para Cursor
docs/            # Alcance por módulo MVP
tindog-api/      # Backend NestJS
tindog-app/      # App Flutter
```

## Módulo 1 — Base & Auth

Ver [docs/module-1.md](docs/module-1.md).

## Inicio rápido

### 1. Bases de datos (Neon / Supabase)

Crea **dos proyectos o branches**: uno para `dev` y otro para `prod`.

### 2. API

```bash
cd tindog-api
cp .env.development.example .env.development
cp .env.production.example .env.production
# Edita DATABASE_URL en cada archivo
npm run db:migrate:dev
npm run db:seed:dev
npm run start:dev
```

Detalle de ambientes: [docs/environments.md](docs/environments.md).

### 3. App (emulador Android)

```bash
cd tindog-api && npm run start:dev   # terminal 1

cd tindog-app
./scripts/run_android.sh             # terminal 2
```

O desde Cursor: **Run and Debug → tinDog App (Android Emulator)**.

## Reglas Cursor

Las reglas en `.cursor/rules/` guían al agente sobre arquitectura, alcance del MVP y convenciones por stack.
