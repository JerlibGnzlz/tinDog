import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

function orderedPair(a: string, b: string): [string, string] {
  return a < b ? [a, b] : [b, a];
}

async function main() {
  const pets = await prisma.pet.findMany({
    where: {
      OR: [
        { name: { equals: 'Doberman', mode: 'insensitive' } },
        { name: { equals: 'firulais', mode: 'insensitive' } },
      ],
    },
    select: {
      id: true,
      name: true,
      user: { select: { email: true } },
    },
  });

  console.log('PETS:', pets);

  const doberman = pets.find((p) => p.name?.toLowerCase() === 'doberman');
  const firulais = pets.find((p) => p.name?.toLowerCase() === 'firulais');

  if (!doberman || !firulais) {
    throw new Error('No encontré ambas mascotas Doberman y firulais');
  }

  // Likes mutuos (idempotente)
  await prisma.like.upsert({
    where: {
      fromPetId_toPetId: {
        fromPetId: doberman.id,
        toPetId: firulais.id,
      },
    },
    create: { fromPetId: doberman.id, toPetId: firulais.id },
    update: {},
  });
  console.log('OK like: Doberman → firulais');

  await prisma.like.upsert({
    where: {
      fromPetId_toPetId: {
        fromPetId: firulais.id,
        toPetId: doberman.id,
      },
    },
    create: { fromPetId: firulais.id, toPetId: doberman.id },
    update: {},
  });
  console.log('OK like: firulais → Doberman');

  // Borrar passes previos entre ellos (si hubiera)
  await prisma.pass.deleteMany({
    where: {
      OR: [
        { fromPetId: doberman.id, toPetId: firulais.id },
        { fromPetId: firulais.id, toPetId: doberman.id },
      ],
    },
  });

  const [petAId, petBId] = orderedPair(doberman.id, firulais.id);
  const match = await prisma.match.upsert({
    where: { petAId_petBId: { petAId, petBId } },
    create: { petAId, petBId },
    update: {},
  });
  console.log('OK match:', match.id);
  console.log(
    '(Mensajes solo en Stream: abrí el chat desde la app para crear el canal.)',
  );

  console.log('\nLISTO. En ambos teléfonos: pull-to-refresh en Chats.');
  console.log('Doberman:', doberman.user.email);
  console.log('firulais:', firulais.user.email);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
