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
import { SendMessageDto } from './dto/send-message.dto';

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
  ) {}

  async discover(userId: string, limit = 20): Promise<DiscoverCandidateDto[]> {
    const myPet = await this.requireMyPet(userId);
    const take = Math.min(Math.max(limit, 1), 50);

    const [liked, passed] = await Promise.all([
      this.prisma.like.findMany({
        where: { fromPetId: myPet.id },
        select: { toPetId: true },
      }),
      this.prisma.pass.findMany({
        where: { fromPetId: myPet.id },
        select: { toPetId: true },
      }),
    ]);

    const excludedIds = [
      myPet.id,
      ...liked.map((l) => l.toPetId),
      ...passed.map((p) => p.toPetId),
    ];

    const pets = await this.prisma.pet.findMany({
      where: {
        id: { notIn: excludedIds },
        name: { not: null },
        NOT: { name: '' },
        OR: [
          { photoUrl: { not: null } },
          { media: { some: { type: PetMediaType.photo } } },
        ],
      },
      include: {
        media: {
          where: { type: PetMediaType.photo },
          orderBy: [{ isPrimary: 'desc' }, { sortOrder: 'asc' }],
          select: { url: true },
        },
        user: {
          select: {
            profile: { select: { location: true, bio: true } },
          },
        },
      },
      orderBy: { updatedAt: 'desc' },
      take,
    });

    return pets
      .map((pet) => this.toCandidate(pet))
      .filter((c): c is DiscoverCandidateDto => c !== null);
  }

  async like(userId: string, toPetId: string) {
    const myPet = await this.requireMyPet(userId);
    if (myPet.id === toPetId) {
      throw new BadRequestException('No podés darte like a vos mismo.');
    }

    await this.requireTargetPet(toPetId);

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

    await this.requireTargetPet(toPetId);

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
      // Solo likes pendientes (aún no respondí con like).
      if (alreadyLikedBack.has(like.fromPetId)) continue;
      const candidate = this.toCandidate(like.fromPet);
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
    const myPet = await this.requireMyPet(userId);
    const [sentCount, receivedRaw] = await Promise.all([
      this.prisma.like.count({ where: { fromPetId: myPet.id } }),
      this.prisma.like.findMany({
        where: { toPetId: myPet.id },
        select: { fromPetId: true },
      }),
    ]);

    const myOutgoing = await this.prisma.like.findMany({
      where: { fromPetId: myPet.id },
      select: { toPetId: true },
    });
    const likedBack = new Set(myOutgoing.map((l) => l.toPetId));
    const receivedCount = receivedRaw.filter(
      (l) => !likedBack.has(l.fromPetId),
    ).length;

    return { receivedCount, sentCount };
  }

  async listMatches(userId: string): Promise<MatchThreadDto[]> {
    const myPet = await this.requireMyPet(userId);
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
        profile: { select: { location: true, bio: true } },
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
    return match;
  }

  private orderedPair(a: string, b: string): [string, string] {
    return a < b ? [a, b] : [b, a];
  }

  private toCandidate(
    pet: Prisma.PetGetPayload<{
      include: {
        media: { select: { url: true } };
        user: {
          select: { profile: { select: { location: true; bio: true } } };
        };
      };
    }>,
  ): DiscoverCandidateDto | null {
    const name = pet.name?.trim();
    if (!name) return null;

    const fromMedia = pet.media.map((m) => m.url);
    const photoUrls = [
      ...fromMedia,
      ...(pet.photoUrl && !fromMedia.includes(pet.photoUrl)
        ? [pet.photoUrl]
        : []),
    ];
    if (photoUrls.length === 0) return null;

    return {
      id: pet.id,
      name,
      age: pet.age,
      breed: pet.breed,
      bio: pet.user.profile?.bio?.trim() || null,
      location: pet.user.profile?.location ?? null,
      // TODO: geo real — por ahora null (la app oculta la línea si falta)
      distanceKm: null,
      isActive: true,
      photoUrls,
      ownerUserId: pet.userId,
    };
  }
}
