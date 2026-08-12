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
const SEED_USER_COUNT = 50;

/**
 * Subir a Cloudinary es lento con 50×2 imágenes.
 * Activá con: SEED_UPLOAD_CLOUDINARY=1 npm run db:seed:dev
 */
const UPLOAD_CLOUDINARY = process.env.SEED_UPLOAD_CLOUDINARY === '1';

/** Puntos en Argentina para probar Cerca / maxKm (referencia Obelisco). */
const LOCATIONS = [
  // ~0–3 km del Obelisco
  { label: 'Obelisco, CABA', lat: -34.6037, lng: -58.3816 },
  { label: 'San Nicolás, CABA', lat: -34.605, lng: -58.384 },
  { label: 'Monserrat, CABA', lat: -34.612, lng: -58.383 },
  { label: 'Retiro, CABA', lat: -34.592, lng: -58.375 },
  { label: 'Recoleta, CABA', lat: -34.5875, lng: -58.3974 },
  // ~3–8 km
  { label: 'Palermo, CABA', lat: -34.5735, lng: -58.4233 },
  { label: 'Belgrano, CABA', lat: -34.5627, lng: -58.4584 },
  { label: 'Caballito, CABA', lat: -34.6197, lng: -58.441 },
  { label: 'Almagro, CABA', lat: -34.606, lng: -58.42 },
  { label: 'Villa Crespo, CABA', lat: -34.598, lng: -58.44 },
  { label: 'Colegiales, CABA', lat: -34.574, lng: -58.449 },
  { label: 'Núñez, CABA', lat: -34.545, lng: -58.462 },
  // ~8–15 km
  { label: 'Villa Urquiza, CABA', lat: -34.5736, lng: -58.487 },
  { label: 'Flores, CABA', lat: -34.635, lng: -58.463 },
  { label: 'Liniers, CABA', lat: -34.639, lng: -58.522 },
  { label: 'Saavedra, CABA', lat: -34.554, lng: -58.488 },
  { label: 'Avellaneda, GBA', lat: -34.662, lng: -58.365 },
  { label: 'Vicente López, GBA', lat: -34.526, lng: -58.475 },
  // ~15–30 km
  { label: 'San Isidro, GBA', lat: -34.4739, lng: -58.5116 },
  { label: 'Morón, GBA', lat: -34.653, lng: -58.619 },
  { label: 'Quilmes, GBA', lat: -34.729, lng: -58.263 },
  { label: 'La Plata, BA', lat: -34.9205, lng: -57.9536 },
  { label: 'Tigre, GBA', lat: -34.426, lng: -58.58 },
  // ~50–100+ km (filtro distancia alto)
  { label: 'Mar del Plata, BA', lat: -38.0055, lng: -57.5426 },
  { label: 'Rosario, Santa Fe', lat: -32.9442, lng: -60.6505 },
  { label: 'Córdoba Capital', lat: -31.4201, lng: -64.1888 },
  { label: 'Mendoza Capital', lat: -32.8895, lng: -68.8458 },
] as const;

/** Alineadas con kSuggestedBreeds de la app (+ algunas extras). */
const BREEDS = [
  'Mestizo',
  'Labrador',
  'Golden Retriever',
  'Bulldog',
  'Poodle',
  'Beagle',
  'Pastor Alemán',
  'Chihuahua',
  'Yorkshire',
  'Boxer',
  'Dálmata',
  'Husky',
  'Caniche',
  'Pug',
  'Doberman',
  'Corgi',
  'Border Collie',
  'Schnauzer',
] as const;

const COLORS = [
  'Negro',
  'Blanco',
  'Marrón',
  'Dorado',
  'Gris',
  'Tricolor',
  'Atigrado',
  'Blanco y negro',
  'Naranja y blanco',
] as const;

const TOYS = [
  'Pelota',
  'Frisbee',
  'Cuerda',
  'Hueso de goma',
  'Peluche',
  'Kong',
] as const;

const FIRST_NAMES = [
  'Ana',
  'Lucas',
  'Sofía',
  'Diego',
  'Valentina',
  'Martín',
  'Camila',
  'Tomás',
  'Julieta',
  'Nicolás',
  'Florencia',
  'Mateo',
  'Agustina',
  'Facundo',
  'Lucía',
  'Santiago',
  'Martina',
  'Bruno',
  'Carolina',
  'Ignacio',
  'Paula',
  'Gonzalo',
  'Emilia',
  'Franco',
  'Romina',
  'Lautaro',
  'Bianca',
  'Federico',
  'Ailén',
  'Joaquín',
  'Micaela',
  'Ramiro',
  'Celeste',
  'Ezequiel',
  'Nadia',
  'Pablo',
  'Jimena',
  'Matías',
  'Rocío',
  'Sebastián',
  'Delfina',
  'Hernán',
  'Candela',
  'Andrés',
  'Melina',
  'Leandro',
  'Victoria',
  'Gastón',
  'Noelia',
  'Hernán',
] as const;

const LAST_NAMES = [
  'García',
  'Martínez',
  'López',
  'Ruiz',
  'Pérez',
  'Gómez',
  'Torres',
  'Vidal',
  'Fernández',
  'Rodríguez',
  'Sánchez',
  'Romero',
  'Díaz',
  'Álvarez',
  'Moreno',
  'Muñoz',
  'Castro',
  'Ortiz',
  'Silva',
  'Navarro',
  'Ramos',
  'Molina',
  'Suárez',
  'Blanco',
  'Gil',
] as const;

const PET_NAMES = [
  'Luna',
  'Rocky',
  'Mimi',
  'Thor',
  'Coco',
  'Firulais',
  'Nala',
  'Kiwi',
  'Toby',
  'Lola',
  'Max',
  'Bella',
  'Simba',
  'Nina',
  'Duke',
  'Maya',
  'Bobby',
  'Kira',
  'Zeus',
  'Daisy',
  'Otto',
  'Chloe',
  'Rex',
  'Lila',
  'Bruno',
  'Mora',
  'Jack',
  'Canela',
  'Leo',
  'Pipa',
  'Tango',
  'Frida',
  'Ollie',
  'Mora',
  'Chester',
  'Greta',
  'Pancho',
  'Olivia',
  'Rocco',
  'Sasha',
  'Milo',
  'India',
  'Teo',
  'Uma',
  'Baloo',
  'Cleo',
  'Dino',
  'Emma',
  'Fito',
  'Greta',
] as const;

type SeedUser = {
  slug: string;
  email: string;
  profile: {
    name: string;
    bio: string;
    location: string;
    latitude: number;
    longitude: number;
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

function slugify(value: string): string {
  return value
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '')
    .slice(0, 24);
}

/** Edades 0–12 con sesgo a 1–8 (rango típico de filtros). */
function ageForIndex(i: number): number {
  const ages = [0, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 5, 5, 6, 6, 7, 8, 9, 10, 12];
  return ages[i % ages.length];
}

function buildSeedUsers(count: number): SeedUser[] {
  const users: SeedUser[] = [];
  const usedSlugs = new Set<string>();

  for (let i = 0; i < count; i++) {
    const first = FIRST_NAMES[i % FIRST_NAMES.length];
    const last = LAST_NAMES[i % LAST_NAMES.length];
    const petName = PET_NAMES[i % PET_NAMES.length];
    const breed = BREEDS[i % BREEDS.length];
    const loc = LOCATIONS[i % LOCATIONS.length];
    const age = ageForIndex(i);
    const color = COLORS[i % COLORS.length];
    const toy = TOYS[i % TOYS.length];

    // Primer usuario fijo: compatible con integration_test login.
    const slug =
      i === 0
        ? 'ana'
        : (() => {
            let s = slugify(`${first}${i + 1}`);
            if (usedSlugs.has(s)) s = `${s}${i}`;
            return s;
          })();
    usedSlugs.add(slug);

    const gender = i % 2 === 0 ? 'women' : 'men';
    const portrait = 10 + (i % 80);

    users.push({
      slug,
      email: `${slug}${SEED_DOMAIN}`,
      profile: {
        name: i === 0 ? 'Ana García' : `${first} ${last}`,
        bio: `Me gusta pasear por ${loc.label} y armar playdates tranquilos.`,
        location: loc.label,
        latitude: loc.lat,
        longitude: loc.lng,
        avatarSource: `https://randomuser.me/api/portraits/${gender}/${portrait}.jpg`,
      },
      pet: {
        name: petName,
        age,
        breed,
        color,
        favoriteToy: toy,
        photoSource: `https://placedog.net/800/1000?id=${(i % 100) + 1}`,
      },
    });
  }

  return users;
}

const seedUsers = buildSeedUsers(SEED_USER_COUNT);

let cloudinaryReady = false;

function configureCloudinary(): boolean {
  if (!UPLOAD_CLOUDINARY) return false;

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
  } else if (UPLOAD_CLOUDINARY) {
    console.warn(
      'SEED_UPLOAD_CLOUDINARY=1 pero faltan credenciales. Usando URLs externas.',
    );
  } else {
    console.log(
      'Usando URLs externas (rápido). Para Cloudinary: SEED_UPLOAD_CLOUDINARY=1',
    );
  }

  const passwordHash = await bcrypt.hash(SEED_PASSWORD, 10);

  const deleted = await prisma.user.deleteMany({
    where: { email: { endsWith: SEED_DOMAIN } },
  });

  if (deleted.count > 0) {
    console.log(`Eliminados ${deleted.count} usuarios de prueba anteriores.`);
  }

  const breedCounts = new Map<string, number>();

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
            latitude: user.profile.latitude,
            longitude: user.profile.longitude,
            locationUpdatedAt: new Date(),
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

    breedCounts.set(
      user.pet.breed,
      (breedCounts.get(user.pet.breed) ?? 0) + 1,
    );

    console.log(
      `✓ ${created.email} — ${created.pet?.name} (${created.pet?.breed}, ${created.pet?.age}a) @ ${created.profile?.location}`,
    );
  }

  console.log('\nSeed completado.');
  console.log(`Usuarios: ${seedUsers.length} en Argentina (@tindog.test)`);
  console.log(`Contraseña de TODOS: ${SEED_PASSWORD}`);
  console.log(
    `Ejemplo: ${seedUsers[0]?.email} / ${SEED_PASSWORD}`,
  );
  console.log('\nCredenciales (email / password):');
  for (const u of seedUsers) {
    console.log(`  ${u.email}  /  ${SEED_PASSWORD}`);
  }
  console.log('\nRazas (para filtro):');
  for (const [breed, n] of [...breedCounts.entries()].sort((a, b) =>
    a[0].localeCompare(b[0]),
  )) {
    console.log(`  ${breed}: ${n}`);
  }
  console.log(
    '\nGPS sugerido (emulador / tu perfil): -34.6037, -58.3816 (Obelisco).',
  );
  console.log(
    'Probá: Cerca 5–15–50 km · raza Labrador/Mestizo · edad 1–4 / 8–12.',
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
