import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
  forwardRef,
} from '@nestjs/common';
import { PetMediaType, Prisma, ChatMessageType } from '@prisma/client';
import { ChatService } from '../chat/chat.service';
import { PrismaService } from '../prisma/prisma.service';
import { PushService } from '../devices/push.service';
import { SafetyService } from '../safety/safety.service';
import { SendMessageDto } from './dto/send-message.dto';

export type DiscoverMode = 'for_you' | 'near' | 'breed' | 'play';

export type DiscoverOptions = {
  limit?: number;
  mode?: DiscoverMode;
  breed?: string;
  minAge?: number;
  maxAge?: number;
  /** Radio máximo en km para modo near (default 50). */
  maxKm?: number;
};

export type DiscoverCandidateDto = {
  id: string;
  name: string;
  age: number | null;
  breed: string | null;
  bio: string | null;
  location: string | null;
  distanceKm: number | null;
  isActive: boolean;
  photoUrls: string[];
  /** Dueño (user.id) — para presencia Stream */
  ownerUserId: string;
};

export type LikeListItemDto = DiscoverCandidateDto & {
  likedAt: string;
  matched: boolean;
};

export type LikesSummaryDto = {
  receivedCount: number;
  sentCount: number;
};

export type MatchThreadDto = {
  id: string;
  matchedAt: string;
  otherPet: DiscoverCandidateDto;
  lastMessage: {
    id: string;
    body: string;
    type: 'text' | 'image' | 'video';
    createdAt: string;
    fromMe: boolean;
  } | null;
  hasMessages: boolean;
};

export type ChatMessageDto = {
  id: string;
  type: 'text' | 'image' | 'video';
  body: string;
  mediaUrl: string | null;
  mediaPublicId: string | null;
  thumbnailUrl: string | null;
  durationSec: number | null;
  createdAt: string;
  fromMe: boolean;
  fromPetId: string;
};

@Injectable()
export class MatchingService {
  constructor(
    private readonly prisma: PrismaService,
    @Inject(forwardRef(() => ChatService))
    private readonly chatService: ChatService,
    private readonly safetyService: SafetyService,
    private readonly pushService: PushService,
  ) {}

  async discover(
    userId: string,
    options: DiscoverOptions = {},
  ): Promise<DiscoverCandidateDto[]> {
    const myPet = await this.requireMyPet(userId);
    const take = Math.min(Math.max(options.limit ?? 20, 1), 50);
    const mode = options.mode ?? 'for_you';
    const maxKm = Math.min(Math.max(options.maxKm ?? 50, 1), 500);

    const [liked, passed, blockedUserIds, myProfile] = await Promise.all([
      this.prisma.like.findMany({
        where: { fromPetId: myPet.id },
        select: { toPetId: true },
      }),
      this.prisma.pass.findMany({
        where: { fromPetId: myPet.id },
        select: { toPetId: true },
      }),
      this.safetyService.relatedBlockedUserIds(userId),
      this.prisma.profile.findUnique({
        where: { userId },
        select: {
          location: true,
          latitude: true,
          longitude: true,
        },
      }),
    ]);

    const excludedIds = [
      myPet.id,
      ...liked.map((l) => l.toPetId),
      ...passed.map((p) => p.toPetId),
    ];

    const ageFilter: Prisma.IntFilter = {};
    if (options.minAge != null) ageFilter.gte = options.minAge;
    if (options.maxAge != null) ageFilter.lte = options.maxAge;

    const breedQuery =
      (options.breed?.trim() ||
        (mode === 'breed' ? myPet.breed?.trim() : undefined)) ||
      undefined;

    const myLat = myProfile?.latitude ?? null;
    const myLng = myProfile?.longitude ?? null;
    const hasGps =
      myLat != null &&
      myLng != null &&
      Number.isFinite(myLat) &&
      Number.isFinite(myLng);

    // Cerca: requiere GPS propio.
    if (mode === 'near' && !hasGps) {
      return [];
    }

    // Razas: sin raza propia ni filtro → vacío (la app pide elegir).
    if (mode === 'breed' && !breedQuery) {
      return [];
    }

    const where: Prisma.PetWhereInput = {
      id: { notIn: excludedIds },
      ...(blockedUserIds.length > 0
        ? { userId: { notIn: blockedUserIds } }
        : {}),
      name: { not: null },
      NOT: { name: '' },
      OR: [
        { photoUrl: { not: null } },
        { media: { some: { type: PetMediaType.photo } } },
      ],
      ...(Object.keys(ageFilter).length > 0 ? { age: ageFilter } : {}),
      ...(breedQuery
        ? { breed: { contains: breedQuery, mode: 'insensitive' } }
        : {}),
      ...(mode === 'near'
        ? {
            user: {
              profile: {
                latitude: { not: null },
                longitude: { not: null },
              },
            },
          }
        : {}),
    };

    let pets = await this.prisma.pet.findMany({
      where,
      include: {
        media: {
          where: { type: PetMediaType.photo },
          orderBy: [{ isPrimary: 'desc' }, { sortOrder: 'asc' }],
          select: { url: true },
        },
        user: {
          select: {
            profile: {
              select: {
                location: true,
                bio: true,
                latitude: true,
                longitude: true,
              },
            },
          },
        },
      },
      orderBy: { updatedAt: 'desc' },
      take: mode === 'near' || mode === 'play' ? Math.min(take * 3, 80) : take,
    });

    type PetRow = (typeof pets)[number];
    type Scored = { pet: PetRow; distanceKm: number | null };

    let scored: Scored[] = pets.map((pet) => {
      const lat = pet.user.profile?.latitude ?? null;
      const lng = pet.user.profile?.longitude ?? null;
      let distanceKm: number | null = null;
      if (
        hasGps &&
        lat != null &&
        lng != null &&
        Number.isFinite(lat) &&
        Number.isFinite(lng)
      ) {
        distanceKm = this.haversineKm(myLat!, myLng!, lat, lng);
      }
      return { pet, distanceKm };
    });

    if (mode === 'near') {
      scored = scored
        .filter(
          (s) => s.distanceKm != null && s.distanceKm <= maxKm,
        )
        .sort((a, b) => (a.distanceKm ?? 0) - (b.distanceKm ?? 0));
    } else if (mode === 'play') {
      scored = this.shuffle(scored);
    }

    scored = scored.slice(0, take);

    return scored
      .map(({ pet, distanceKm }) => this.toCandidate(pet, distanceKm))
      .filter((c): c is DiscoverCandidateDto => c !== null);
  }

  /** Distancia en km entre dos puntos WGS84. */
  private haversineKm(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number,
  ): number {
    const toRad = (d: number) => (d * Math.PI) / 180;
    const r = 6371;
    const dLat = toRad(lat2 - lat1);
    const dLon = toRad(lon2 - lon1);
    const a =
      Math.sin(dLat / 2) ** 2 +
      Math.cos(toRad(lat1)) *
        Math.cos(toRad(lat2)) *
        Math.sin(dLon / 2) ** 2;
    return r * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  }

  private shuffle<T>(items: T[]): T[] {
    const copy = [...items];
    for (let i = copy.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [copy[i], copy[j]] = [copy[j], copy[i]];
    }
    return copy;
  }

  async like(userId: string, toPetId: string) {
    const myPet = await this.requireMyPet(userId);
    if (myPet.id === toPetId) {
      throw new BadRequestException('No podés darte like a vos mismo.');
    }

    const target = await this.requireTargetPet(toPetId);
    await this.safetyService.assertNotBlocked(userId, target.userId);

    const existing = await this.prisma.like.findUnique({
      where: {
        fromPetId_toPetId: { fromPetId: myPet.id, toPetId },
      },
    });

    if (existing) {
      const match = await this.findMatchBetween(myPet.id, toPetId);
      return { liked: true, matched: match != null, match };
    }

    await this.prisma.pass.deleteMany({
      where: { fromPetId: myPet.id, toPetId },
    });

    const like = await this.prisma.like.create({
      data: { fromPetId: myPet.id, toPetId },
    });

    const reciprocal = await this.prisma.like.findUnique({
      where: {
        fromPetId_toPetId: { fromPetId: toPetId, toPetId: myPet.id },
      },
    });

    let match = null;
    if (reciprocal) {
      match = await this.createMatch(myPet.id, toPetId);
    }

    return {
      liked: true,
      matched: match != null,
      like,
      match,
    };
  }

  async pass(userId: string, toPetId: string) {
    const myPet = await this.requireMyPet(userId);
    if (myPet.id === toPetId) {
      throw new BadRequestException('No podés pasar tu propio perfil.');
    }

    const target = await this.requireTargetPet(toPetId);
    await this.safetyService.assertNotBlocked(userId, target.userId);

    const alreadyLiked = await this.prisma.like.findUnique({
      where: {
        fromPetId_toPetId: { fromPetId: myPet.id, toPetId },
      },
    });
    if (alreadyLiked) {
      throw new ConflictException(
        'Ya le diste like a esta mascota; no se puede pasar.',
      );
    }

    const pass = await this.prisma.pass.upsert({
      where: {
        fromPetId_toPetId: { fromPetId: myPet.id, toPetId },
      },
      create: { fromPetId: myPet.id, toPetId },
      update: {},
    });

    return { passed: true, pass };
  }

  async listSentLikes(userId: string): Promise<LikeListItemDto[]> {
    const myPet = await this.requireMyPet(userId);
    const blocked = new Set(
      await this.safetyService.relatedBlockedUserIds(userId),
    );
    const likes = await this.prisma.like.findMany({
      where: { fromPetId: myPet.id },
      orderBy: { createdAt: 'desc' },
      include: {
        toPet: {
          include: this.petCardInclude,
        },
      },
    });

    const items: LikeListItemDto[] = [];
    for (const like of likes) {
      if (blocked.has(like.toPet.userId)) continue;
      const candidate = this.toCandidate(like.toPet);
      if (!candidate) continue;
      const match = await this.findMatchBetween(myPet.id, like.toPetId);
      items.push({
        ...candidate,
        likedAt: like.createdAt.toISOString(),
        matched: match != null,
      });
    }
    return items;
  }

  async listReceivedLikes(userId: string): Promise<LikeListItemDto[]> {
    const myPet = await this.requireMyPet(userId);
    const blocked = new Set(
      await this.safetyService.relatedBlockedUserIds(userId),
    );
    const likes = await this.prisma.like.findMany({
      where: { toPetId: myPet.id },
      orderBy: { createdAt: 'desc' },
      include: {
        fromPet: {
          include: this.petCardInclude,
        },
      },
    });

    const myOutgoing = await this.prisma.like.findMany({
      where: { fromPetId: myPet.id },
      select: { toPetId: true },
    });
    const alreadyLikedBack = new Set(myOutgoing.map((l) => l.toPetId));

    const items: LikeListItemDto[] = [];
    for (const like of likes) {
      if (blocked.has(like.fromPet.userId)) continue;
      // Solo likes pendientes (aún no respondí con like).
      if (alreadyLikedBack.has(like.fromPetId)) continue;
      // Sin foto igual se muestra (placeholder en app); si no, el badge
      // cuenta 1 y la grilla queda vacía.
      const candidate = this.toCandidate(like.fromPet, null, {
        requirePhoto: false,
      });
      if (!candidate) continue;
      items.push({
        ...candidate,
        likedAt: like.createdAt.toISOString(),
        matched: false,
      });
    }
    return items;
  }

  async likesSummary(userId: string): Promise<LikesSummaryDto> {
    // Misma lógica que las listas (bloqueados / like back / nombre).
    const [sent, received] = await Promise.all([
      this.listSentLikes(userId),
      this.listReceivedLikes(userId),
    ]);
    return { receivedCount: received.length, sentCount: sent.length };
  }

  /**
   * Elimina el match (unmatch): likes cruzados + fila match + canal Stream.
   * No bloquea: pueden volver a verse en Desliza.
   */
  async unmatch(userId: string, matchId: string) {
    const myPet = await this.requireMyPet(userId);
    const match = await this.requireMatchMember(matchId, myPet.id);
    const otherPetId =
      match.petAId === myPet.id ? match.petBId : match.petAId;

    await this.prisma.$transaction([
      this.prisma.like.deleteMany({
        where: {
          OR: [
            { fromPetId: myPet.id, toPetId: otherPetId },
            { fromPetId: otherPetId, toPetId: myPet.id },
          ],
        },
      }),
      this.prisma.match.delete({ where: { id: matchId } }),
    ]);

    await this.chatService.deleteChannelForMatch(matchId);
    return { deleted: true, matchId };
  }

  async listMatches(userId: string): Promise<MatchThreadDto[]> {
    const myPet = await this.requireMyPet(userId);
    const blocked = new Set(
      await this.safetyService.relatedBlockedUserIds(userId),
    );
    const matches = await this.prisma.match.findMany({
      where: {
        OR: [{ petAId: myPet.id }, { petBId: myPet.id }],
      },
      include: {
        petA: { include: this.petCardInclude },
        petB: { include: this.petCardInclude },
        messages: {
          orderBy: { createdAt: 'desc' },
          take: 1,
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    const threads: MatchThreadDto[] = [];
    for (const match of matches) {
      const other =
        match.petAId === myPet.id ? match.petB : match.petA;
      if (blocked.has(other.userId)) continue;
      const candidate = this.toCandidate(other);
      if (!candidate) continue;

      const last = match.messages[0] ?? null;
      threads.push({
        id: match.id,
        matchedAt: match.createdAt.toISOString(),
        otherPet: candidate,
        hasMessages: last != null,
        lastMessage: last
          ? {
              id: last.id,
              body: this.previewBody(last.type, last.body),
              type: last.type,
              createdAt: last.createdAt.toISOString(),
              fromMe: last.fromPetId === myPet.id,
            }
          : null,
      });
    }

    // Preferir preview/realtime de Stream cuando haya mensajes allí.
    const streamLast = await this.chatService.lastMessagesByMatchIds(
      userId,
      threads.map((t) => t.id),
    );
    for (const thread of threads) {
      const fromStream = streamLast.get(thread.id);
      if (fromStream) {
        thread.lastMessage = fromStream;
        thread.hasMessages = true;
      }
    }

    // Conversaciones arriba por última actividad; matches nuevos al final del sort lo maneja la app.
    threads.sort((a, b) => {
      const aTime = a.lastMessage?.createdAt ?? a.matchedAt;
      const bTime = b.lastMessage?.createdAt ?? b.matchedAt;
      return bTime.localeCompare(aTime);
    });

    return threads;
  }

  async listMessages(
    userId: string,
    matchId: string,
  ): Promise<ChatMessageDto[]> {
    const myPet = await this.requireMyPet(userId);
    await this.requireMatchMember(matchId, myPet.id);

    const messages = await this.prisma.chatMessage.findMany({
      where: { matchId },
      orderBy: { createdAt: 'asc' },
      take: 200,
    });

    return messages.map((m) => this.toMessageDto(m, myPet.id));
  }

  async sendMessage(userId: string, matchId: string, dto: SendMessageDto) {
    const myPet = await this.requireMyPet(userId);
    await this.requireMatchMember(matchId, myPet.id);

    const type = dto.type ?? ChatMessageType.text;
    const body = (dto.body ?? '').trim();

    if (type === ChatMessageType.text) {
      if (!body) {
        throw new BadRequestException('El mensaje no puede estar vacío.');
      }
    } else if (!dto.mediaUrl) {
      throw new BadRequestException('mediaUrl es obligatorio para imagen/video.');
    }

    const message = await this.prisma.chatMessage.create({
      data: {
        matchId,
        fromPetId: myPet.id,
        type,
        body,
        mediaUrl: type === ChatMessageType.text ? null : dto.mediaUrl,
        mediaPublicId:
          type === ChatMessageType.text ? null : (dto.mediaPublicId ?? null),
        thumbnailUrl:
          type === ChatMessageType.text ? null : (dto.thumbnailUrl ?? null),
        durationSec:
          type === ChatMessageType.video ? (dto.durationSec ?? null) : null,
      },
    });

    return this.toMessageDto(message, myPet.id);
  }

  private toMessageDto(
    m: {
      id: string;
      type: ChatMessageType;
      body: string;
      mediaUrl: string | null;
      mediaPublicId: string | null;
      thumbnailUrl: string | null;
      durationSec: number | null;
      createdAt: Date;
      fromPetId: string;
    },
    myPetId: string,
  ): ChatMessageDto {
    return {
      id: m.id,
      type: m.type,
      body: m.body,
      mediaUrl: m.mediaUrl,
      mediaPublicId: m.mediaPublicId,
      thumbnailUrl: m.thumbnailUrl,
      durationSec: m.durationSec,
      createdAt: m.createdAt.toISOString(),
      fromMe: m.fromPetId === myPetId,
      fromPetId: m.fromPetId,
    };
  }

  private previewBody(type: ChatMessageType, body: string): string {
    if (type === ChatMessageType.image) {
      return body.trim() ? `📷 ${body}` : '📷 Foto';
    }
    if (type === ChatMessageType.video) {
      return body.trim() ? `🎬 ${body}` : '🎬 Video';
    }
    return body;
  }

  private async requireMatchMember(matchId: string, myPetId: string) {
    const match = await this.prisma.match.findUnique({ where: { id: matchId } });
    if (!match) {
      throw new NotFoundException('Match no encontrado.');
    }
    if (match.petAId !== myPetId && match.petBId !== myPetId) {
      throw new NotFoundException('Match no encontrado.');
    }
    return match;
  }

  private readonly petCardInclude = {
    media: {
      where: { type: PetMediaType.photo },
      orderBy: [{ isPrimary: 'desc' as const }, { sortOrder: 'asc' as const }],
      select: { url: true },
    },
    user: {
      select: {
        profile: {
          select: {
            location: true,
            bio: true,
            latitude: true,
            longitude: true,
          },
        },
      },
    },
  };

  private async requireMyPet(userId: string) {
    const pet = await this.prisma.pet.findUnique({ where: { userId } });
    if (!pet) {
      throw new NotFoundException('No tenés mascota configurada.');
    }
    return pet;
  }

  private async requireTargetPet(petId: string) {
    const pet = await this.prisma.pet.findUnique({ where: { id: petId } });
    if (!pet) {
      throw new NotFoundException('Mascota no encontrada.');
    }
    return pet;
  }

  private async findMatchBetween(petIdA: string, petIdB: string) {
    const [petAId, petBId] = this.orderedPair(petIdA, petIdB);
    return this.prisma.match.findUnique({
      where: { petAId_petBId: { petAId, petBId } },
    });
  }

  private async createMatch(petIdA: string, petIdB: string) {
    const [petAId, petBId] = this.orderedPair(petIdA, petIdB);
    const match = await this.prisma.match.upsert({
      where: { petAId_petBId: { petAId, petBId } },
      create: { petAId, petBId },
      update: {},
    });
    void this.chatService.ensureChannelForMatchPets(petAId, petBId, match.id);
    void this.notifyMatchPush(match.id, petAId, petBId);
    return match;
  }

  private async notifyMatchPush(
    matchId: string,
    petAId: string,
    petBId: string,
  ) {
    try {
      const pets = await this.prisma.pet.findMany({
        where: { id: { in: [petAId, petBId] } },
        select: { id: true, userId: true, name: true },
      });
      const petA = pets.find((p) => p.id === petAId);
      const petB = pets.find((p) => p.id === petBId);
      if (!petA || !petB) return;

      await Promise.all([
        this.pushService.notifyMatch({
          recipientUserId: petA.userId,
          otherPetName: petB.name?.trim() || 'Alguien',
          matchId,
        }),
        this.pushService.notifyMatch({
          recipientUserId: petB.userId,
          otherPetName: petA.name?.trim() || 'Alguien',
          matchId,
        }),
      ]);
    } catch {
      // Best-effort: el match ya está creado.
    }
  }

  private orderedPair(a: string, b: string): [string, string] {
    return a < b ? [a, b] : [b, a];
  }

  private toCandidate(
    pet: Prisma.PetGetPayload<{
      include: {
        media: { select: { url: true } };
        user: {
          select: {
            profile: {
              select: {
                location: true;
                bio: true;
                latitude: true;
                longitude: true;
              };
            };
          };
        };
      };
    }>,
    distanceKm: number | null = null,
    options: { requirePhoto?: boolean } = {},
  ): DiscoverCandidateDto | null {
    const requirePhoto = options.requirePhoto ?? true;
    const name = pet.name?.trim();
    if (!name) return null;

    const fromMedia = pet.media.map((m) => m.url);
    const photoUrls = [
      ...fromMedia,
      ...(pet.photoUrl && !fromMedia.includes(pet.photoUrl)
        ? [pet.photoUrl]
        : []),
    ];
    if (requirePhoto && photoUrls.length === 0) return null;

    return {
      id: pet.id,
      name,
      age: pet.age,
      breed: pet.breed,
      bio: pet.user.profile?.bio?.trim() || null,
      location: pet.user.profile?.location ?? null,
      distanceKm:
        distanceKm != null ? Math.round(distanceKm * 10) / 10 : null,
      isActive: true,
      photoUrls,
      ownerUserId: pet.userId,
    };
  }
}
