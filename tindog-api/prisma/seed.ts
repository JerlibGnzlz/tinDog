import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { v2 as cloudinary } from 'cloudinary';

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
    slug: 'ana',
    email: `ana${SEED_DOMAIN}`,
    profile: {
      name: 'Ana García',
      bio: 'Dueña de Luna, una golden muy sociable. Buscamos playdates en el parque.',
      location: 'Madrid, España',
      avatarSource: 'https://randomuser.me/api/portraits/women/65.jpg',
    },
    pet: {
      name: 'Luna',
      age: 3,
      breed: 'Golden Retriever',
      color: 'Dorado',
      favoriteToy: 'Cuerda para tirar',
      photoSource: 'https://placedog.net/800/1000?id=1',
    },
  },
  {
    slug: 'lucas',
    email: `lucas${SEED_DOMAIN}`,
    profile: {
      name: 'Lucas Martínez',
      bio: 'Rocky es un bulldog tranquilo. Nos gusta pasear por la ribera.',
      location: 'Buenos Aires, Argentina',
      avatarSource: 'https://randomuser.me/api/portraits/men/32.jpg',
    },
    pet: {
      name: 'Rocky',
      age: 4,
      breed: 'Bulldog',
      color: 'Blanco y negro',
      favoriteToy: 'Pelota de tenis',
      photoSource: 'https://placedog.net/800/1000?id=2',
    },
  },
  {
    slug: 'sofia',
    email: `sofia${SEED_DOMAIN}`,
    profile: {
      name: 'Sofía López',
      bio: 'Tengo dos gatos y un perro. Mimi adora conocer otros peludos.',
      location: 'Ciudad de México, México',
      avatarSource: 'https://randomuser.me/api/portraits/women/44.jpg',
    },
    pet: {
      name: 'Mimi',
      age: 2,
      breed: 'Siamés',
      color: 'Crema',
      favoriteToy: 'Ratón de juguete',
      photoSource: 'https://placedog.net/800/1000?id=3',
    },
  },
  {
    slug: 'diego',
    email: `diego${SEED_DOMAIN}`,
    profile: {
      name: 'Diego Ruiz',
      bio: 'Entrenador canino aficionado. Thor necesita amigos para correr.',
      location: 'Barcelona, España',
      avatarSource: 'https://randomuser.me/api/portraits/men/75.jpg',
    },
    pet: {
      name: 'Thor',
      age: 5,
      breed: 'Husky',
      color: 'Gris',
      favoriteToy: 'Frisbee',
      photoSource: 'https://placedog.net/800/1000?id=4',
    },
  },
  {
    slug: 'valentina',
    email: `valentina${SEED_DOMAIN}`,
    profile: {
      name: 'Valentina Pérez',
      bio: 'Coco es un corgi curioso. Buscamos otros dueños responsables.',
      location: 'Santiago, Chile',
      avatarSource: 'https://randomuser.me/api/portraits/women/28.jpg',
    },
    pet: {
      name: 'Coco',
      age: 1,
      breed: 'Corgi',
      color: 'Naranja y blanco',
      favoriteToy: 'Hueso de goma',
      photoSource: 'https://placedog.net/800/1000?id=5',
    },
  },
] as const;

let cloudinaryReady = false;

function configureCloudinary(): boolean {
  const cloudName = process.env.CLOUDINARY_CLOUD_NAME;
  const apiKey = process.env.CLOUDINARY_API_KEY;
  const apiSecret = process.env.CLOUDINARY_API_SECRET;

  if (!cloudName || !apiKey || !apiSecret) {
    return false;
  }

  cloudinary.config({
    cloud_name: cloudName,
    api_key: apiKey,
    api_secret: apiSecret,
  });

  return true;
}

async function uploadSeedImage(
  sourceUrl: string,
  folder: string,
  publicId: string,
  width: number,
  height: number,
): Promise<string> {
  if (!cloudinaryReady) {
    return sourceUrl;
  }

  try {
    const result = await cloudinary.uploader.upload(sourceUrl, {
      folder,
      public_id: publicId,
      overwrite: true,
      resource_type: 'image',
      transformation: [
        { width, height, crop: 'fill', gravity: 'auto', quality: 'auto' },
      ],
    });

    return result.secure_url;
  } catch (error) {
    const message =
      typeof error === 'object' &&
        error !== null &&
        'message' in error &&
        typeof (error as { message: unknown }).message === 'string'
        ? (error as { message: string }).message
        : String(error);
    console.warn(`  ⚠ No se pudo subir ${publicId} a Cloudinary: ${message}`);
    console.warn('  → Usando URL externa como respaldo.');
    return sourceUrl;
  }
}

async function main() {
  cloudinaryReady = configureCloudinary();

  if (cloudinaryReady) {
    console.log('Subiendo imágenes de prueba a Cloudinary...');
  } else {
    console.warn(
      'Cloudinary no configurado. Se usarán URLs externas (pueden fallar en la app).',
    );
  }

  const passwordHash = await bcrypt.hash(SEED_PASSWORD, 10);

  const deleted = await prisma.user.deleteMany({
    where: { email: { endsWith: SEED_DOMAIN } },
  });

  if (deleted.count > 0) {
    console.log(`Eliminados ${deleted.count} usuarios de prueba anteriores.`);
  }

  for (const user of seedUsers) {
    const avatarUrl = await uploadSeedImage(
      user.profile.avatarSource,
      'tindog/seed/avatars',
      user.slug,
      400,
      400,
    );

    const photoUrl = await uploadSeedImage(
      user.pet.photoSource,
      'tindog/pets/seed',
      user.slug,
      800,
      1000,
    );

    const created = await prisma.user.create({
      data: {
        email: user.email,
        passwordHash,
        profile: {
          create: {
            name: user.profile.name,
            bio: user.profile.bio,
            location: user.profile.location,
            avatarUrl,
          },
        },
        pet: {
          create: {
            name: user.pet.name,
            age: user.pet.age,
            breed: user.pet.breed,
            color: user.pet.color,
            favoriteToy: user.pet.favoriteToy,
            photoUrl,
          },
        },
      },
      include: { profile: true, pet: true },
    });

    console.log(
      `✓ ${created.email} — ${created.profile?.name} / ${created.pet?.name}`,
    );
  }

  console.log('\nSeed completado.');
  console.log(`Contraseña de todos los usuarios: ${SEED_PASSWORD}`);
  console.log(
    'Usuarios de prueba: ana, lucas, sofia, diego, valentina @tindog.test',
  );
}

main()
  .catch((error) => {
    console.error('Error en seed:', error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
