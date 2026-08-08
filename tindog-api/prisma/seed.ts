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

/** Coords aproximadas CABA / AMBA para probar modo Cerca. */
const BA = {
  obelisco: { lat: -34.6037, lng: -58.3816, label: 'Obelisco, Buenos Aires' },
  palermo: { lat: -34.5735, lng: -58.4233, label: 'Palermo, Buenos Aires' },
  villaUrquiza: {
    lat: -34.5736,
    lng: -58.487,
    label: 'Villa Urquiza, Buenos Aires',
  },
  recoleta: { lat: -34.5875, lng: -58.3974, label: 'Recoleta, Buenos Aires' },
  caballito: { lat: -34.6197, lng: -58.441, label: 'Caballito, Buenos Aires' },
  belgrano: { lat: -34.5627, lng: -58.4584, label: 'Belgrano, Buenos Aires' },
  sanIsidro: { lat: -34.4739, lng: -58.5116, label: 'San Isidro, Buenos Aires' },
} as const;

type SeedUser = {
  slug: string;
  email: string;
  profile: {
    name: string;
    bio: string;
    location: string;
    latitude?: number;
    longitude?: number;
    avatarSource: string;
  };
  pet: {
    name: string;
    age: number;
    breed: string;
    color: string;
    favoriteToy: string;
    photoSource: string;
  };
};

const seedUsers: SeedUser[] = [
  {
    slug: 'ana',
    email: `ana${SEED_DOMAIN}`,
    profile: {
      name: 'Ana García',
      bio: 'Dueña de Luna, una golden muy sociable. Buscamos playdates en el parque.',
      location: 'Madrid, España',
      latitude: 40.4168,
      longitude: -3.7038,
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
      bio: 'Rocky es un bulldog tranquilo. Nos gusta pasear por Palermo.',
      location: BA.palermo.label,
      latitude: BA.palermo.lat,
      longitude: BA.palermo.lng,
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
      bio: 'Mimi adora conocer otros peludos en Villa Urquiza.',
      location: BA.villaUrquiza.label,
      latitude: BA.villaUrquiza.lat,
      longitude: BA.villaUrquiza.lng,
      avatarSource: 'https://randomuser.me/api/portraits/women/44.jpg',
    },
    pet: {
      name: 'Mimi',
      age: 2,
      breed: 'Mestizo',
      color: 'Marrón',
      favoriteToy: 'Ratón de juguete',
      photoSource: 'https://placedog.net/800/1000?id=3',
    },
  },
  {
    slug: 'diego',
    email: `diego${SEED_DOMAIN}`,
    profile: {
      name: 'Diego Ruiz',
      bio: 'Thor necesita amigos para correr en Recoleta.',
      location: BA.recoleta.label,
      latitude: BA.recoleta.lat,
      longitude: BA.recoleta.lng,
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
      bio: 'Coco es un corgi curioso del barrio Caballito.',
      location: BA.caballito.label,
      latitude: BA.caballito.lat,
      longitude: BA.caballito.lng,
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
  {
    slug: 'martin',
    email: `martin${SEED_DOMAIN}`,
    profile: {
      name: 'Martín Gómez',
      bio: 'Firulais pasea todas las tardes por Belgrano.',
      location: BA.belgrano.label,
      latitude: BA.belgrano.lat,
      longitude: BA.belgrano.lng,
      avatarSource: 'https://randomuser.me/api/portraits/men/41.jpg',
    },
    pet: {
      name: 'Firulais',
      age: 6,
      breed: 'Labrador',
      color: 'Negro',
      favoriteToy: 'Pelota',
      photoSource: 'https://placedog.net/800/1000?id=6',
    },
  },
  {
    slug: 'camila',
    email: `camila${SEED_DOMAIN}`,
    profile: {
      name: 'Camila Torres',
      bio: 'Nala busca amigos cerca del Obelisco.',
      location: BA.obelisco.label,
      latitude: BA.obelisco.lat,
      longitude: BA.obelisco.lng,
      avatarSource: 'https://randomuser.me/api/portraits/women/12.jpg',
    },
    pet: {
      name: 'Nala',
      age: 2,
      breed: 'Beagle',
      color: 'Tricolor',
      favoriteToy: 'Cuerda',
      photoSource: 'https://placedog.net/800/1000?id=7',
    },
  },
  {
    slug: 'tomas',
    email: `tomas${SEED_DOMAIN}`,
    profile: {
      name: 'Tomás Vidal',
      bio: 'Kiwi vive en San Isidro; ideal para probar distancias ~15 km.',
      location: BA.sanIsidro.label,
      latitude: BA.sanIsidro.lat,
      longitude: BA.sanIsidro.lng,
      avatarSource: 'https://randomuser.me/api/portraits/men/22.jpg',
    },
    pet: {
      name: 'Kiwi',
      age: 3,
      breed: 'Border Collie',
      color: 'Negro y blanco',
      favoriteToy: 'Frisbee',
      photoSource: 'https://placedog.net/800/1000?id=8',
    },
  },
];

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

    const hasGps =
      user.profile.latitude != null && user.profile.longitude != null;

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
            ...(hasGps
              ? {
                  latitude: user.profile.latitude,
                  longitude: user.profile.longitude,
                  locationUpdatedAt: new Date(),
                }
              : {}),
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

    const gpsNote = hasGps
      ? ` [${user.profile.latitude}, ${user.profile.longitude}]`
      : '';
    console.log(
      `✓ ${created.email} — ${created.profile?.name} / ${created.pet?.name}${gpsNote}`,
    );
  }

  console.log('\nSeed completado.');
  console.log(`Contraseña de todos los usuarios: ${SEED_PASSWORD}`);
  console.log(
    'Usuarios: ana (Madrid), lucas/sofia/diego/valentina/martin/camila/tomas (BA) @tindog.test',
  );
  console.log(
    'Para probar Cerca: seteá GPS del emulador en -34.6037, -58.3816 (Obelisco).',
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
