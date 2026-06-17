# Ambientes — tinDog API

## Archivos

| Archivo | Uso | Git |
|---------|-----|-----|
| `.env.development` | Base de datos y secrets de **desarrollo** | Ignorado |
| `.env.production` | Base de datos y secrets de **producción** | Ignorado |
| `.env.development.example` | Plantilla dev | Commiteado |
| `.env.production.example` | Plantilla prod | Commiteado |

NestJS carga `.env.{NODE_ENV}` según el ambiente.

## Setup inicial

```bash
cd tindog-api
cp .env.development.example .env.development
cp .env.production.example .env.production
# Edita cada archivo con su DATABASE_URL de Neon/Supabase
```

### Recomendación Neon

Crea **dos bases** en el mismo proyecto (o branches separados):

- **tindog_dev** → desarrollo local, migraciones, seed
- **tindog_prod** → solo `migrate deploy`, sin seed

En Neon, las bases se crean conectando a `neondb` y ejecutando:

```sql
CREATE DATABASE tindog_dev;
CREATE DATABASE tindog_prod;
```

### URLs de conexión (importante)

Neon requiere **dos URLs** en cada `.env`:

| Variable | Uso |
|----------|-----|
| `DATABASE_URL` | Host **con** `-pooler` → app en runtime |
| `DIRECT_URL` | Host **sin** `-pooler` → migraciones Prisma |

Ejemplo:

```env
DATABASE_URL="postgresql://...@ep-xxx-pooler.region.aws.neon.tech/tindog_dev?sslmode=require"
DIRECT_URL="postgresql://...@ep-xxx.region.aws.neon.tech/tindog_dev?sslmode=require"
```

## Comandos por ambiente

### Desarrollo

```bash
npm run start:dev              # API con .env.development
npm run db:migrate:dev         # Crear/aplicar migraciones
npm run db:seed:dev            # Datos de prueba (solo dev)
npm run db:studio:dev          # Prisma Studio
```

### Producción

```bash
npm run build
npm run db:migrate:prod        # Aplicar migraciones existentes (no crea nuevas)
npm run start:prod             # API con .env.production
```

> **Nunca** ejecutes `db:seed` ni `migrate dev` contra producción.

## Flujo de trabajo

1. Desarrollas y migras en **dev** (`db:migrate:dev`)
2. Commiteas la carpeta `prisma/migrations/`
3. En producción solo corres `db:migrate:prod` + `start:prod`

## Flutter

La app no usa estos archivos. Solo necesita la URL de la API:

```bash
# Dev local
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000

# Prod (cuando despliegues la API)
flutter build apk --dart-define=API_BASE_URL=https://api.tudominio.com
```
