import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

const nodeEnv = process.env.NODE_ENV ?? 'development';

if (nodeEnv === 'production') {
  console.error('El seed solo puede ejecutarse en desarrollo.');
  process.exit(1);
}

const SEED_PASSWORD = 'password123';
const SEED_DOMAIN = '@tindog.test';

const seedUsers = [
  {
    email: `ana${SEED_DOMAIN}`,
    profile: {
      name: 'Ana García',
      bio: 'Dueña de Luna, una golden muy sociable. Buscamos playdates en el parque.',
      location: 'Madrid, España',
      avatarUrl: 'https://i.pravatar.cc/300?u=ana-tindog',
    },
  },
  {
    email: `lucas${SEED_DOMAIN}`,
    profile: {
      name: 'Lucas Martínez',
      bio: 'Rocky es un bulldog tranquilo. Nos gusta pasear por la ribera.',
      location: 'Buenos Aires, Argentina',
      avatarUrl: 'https://i.pravatar.cc/300?u=lucas-tindog',
    },
  },
  {
    email: `sofia${SEED_DOMAIN}`,
    profile: {
      name: 'Sofía López',
      bio: 'Tengo dos gatos y un perro. Mimi adora conocer otros peludos.',
      location: 'Ciudad de México, México',
      avatarUrl: 'https://i.pravatar.cc/300?u=sofia-tindog',
    },
  },
  {
    email: `diego${SEED_DOMAIN}`,
    profile: {
      name: 'Diego Ruiz',
      bio: 'Entrenador canino aficionado. Thor necesita amigos para correr.',
      location: 'Barcelona, España',
      avatarUrl: 'https://i.pravatar.cc/300?u=diego-tindog',
    },
  },
  {
    email: `valentina${SEED_DOMAIN}`,
    profile: {
      name: 'Valentina Pérez',
      bio: 'Coco es un corgi curioso. Buscamos otros dueños responsables.',
      location: 'Santiago, Chile',
      avatarUrl: 'https://i.pravatar.cc/300?u=valentina-tindog',
    },
  },
];

async function main() {
  const passwordHash = await bcrypt.hash(SEED_PASSWORD, 10);

  const deleted = await prisma.user.deleteMany({
    where: { email: { endsWith: SEED_DOMAIN } },
  });

  if (deleted.count > 0) {
    console.log(`Eliminados ${deleted.count} usuarios de prueba anteriores.`);
  }

  for (const user of seedUsers) {
    const created = await prisma.user.create({
      data: {
        email: user.email,
        passwordHash,
        profile: { create: user.profile },
      },
      include: { profile: true },
    });

    console.log(`✓ ${created.email} — ${created.profile?.name}`);
  }

  console.log('\nSeed completado.');
  console.log(`Contraseña de todos los usuarios: ${SEED_PASSWORD}`);
}

main()
  .catch((error) => {
    console.error('Error en seed:', error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
