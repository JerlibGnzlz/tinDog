import {
  Injectable,
  Logger,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { PetMediaType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { SafetyService } from '../safety/safety.service';
import {
  StreamChatService,
  StreamUserProfile,
} from './stream-chat.service';

@Injectable()
export class ChatService {
  private readonly logger = new Logger(ChatService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly stream: StreamChatService,
    private readonly safetyService: SafetyService,
  ) {}

  async getToken(userId: string) {
    this.requireStream();
    const profile = await this.buildStreamUser(userId);
    await this.stream.upsertUsers([profile]);
    return {
      apiKey: this.stream.getApiKey(),
      token: this.stream.createUserToken(userId),
      user: profile,
    };
  }

  /** Unmatch / bloqueo: elimina canal Stream (best-effort). */
  async deleteChannelForMatch(matchId: string): Promise<void> {
    await this.stream.deleteMatchChannel(matchId);
  }

  async ensureChannel(userId: string, matchId: string) {
    this.requireStream();
    const { members, channelName, channelImage, other } =
      await this.loadMatchChannelContext(userId, matchId);

    if (other?.id) {
      await this.safetyService.assertNotBlocked(userId, other.id);
    }

    const channel = await this.stream.ensureMatchChannel({
      matchId,
      members,
      channelName,
      channelImage,
    });

    return {
      ...channel,
      apiKey: this.stream.getApiKey(),
      other,
      members,
    };
  }

  /** Crea canal Stream tras un match (best-effort, no falla el match). */
  async ensureChannelForMatchPets(
    petAId: string,
    petBId: string,
    matchId: string,
  ): Promise<void> {
    if (!this.stream.isEnabled()) return;
    try {
      const pets = await this.prisma.pet.findMany({
        where: { id: { in: [petAId, petBId] } },
        include: {
          media: {
            where: { type: PetMediaType.photo },
            orderBy: [{ isPrimary: 'desc' }, { sortOrder: 'asc' }],
            take: 1,
            select: { url: true },
          },
        },
      });
      if (pets.length !== 2) return;

      const members: StreamUserProfile[] = pets.map((p) => ({
        id: p.userId,
        name: p.name?.trim() || 'Mascota',
        image: p.media[0]?.url ?? p.photoUrl ?? undefined,
      }));

      const names = members
        .map((m) => m.name)
        .slice()
        .sort((a, b) => a.localeCompare(b));
      await this.stream.ensureMatchChannel({
        matchId,
        members,
        channelName: names.join(' & '),
        channelImage: members[0]?.image ?? members[1]?.image,
      });
    } catch (err) {
      this.logger.warn(
        `No se pudo crear canal Stream para match ${matchId}: ${
          err instanceof Error ? err.message : err
        }`,
      );
    }
  }

  async lastMessagesByMatchIds(
    userId: string,
    matchIds: string[],
  ): Promise<
    Map<
      string,
      {
        id: string;
        body: string;
        type: 'text' | 'image' | 'video';
        createdAt: string;
        fromMe: boolean;
      }
    >
  > {
    const result = new Map();
    if (!this.stream.isEnabled() || matchIds.length === 0) return result;

    try {
      const channels = await this.stream.queryMatchChannels(userId, matchIds);
      for (const [matchId, channel] of channels) {
        const last = channel.state?.messages?.at(-1);
        if (!last) continue;
        const text = (last.text ?? '').trim();
        const attachments = last.attachments ?? [];
        let type: 'text' | 'image' | 'video' = 'text';
        let body = text;
        if (attachments.some((a) => a.type === 'video')) {
          type = 'video';
          body = text || '🎬 Video';
        } else if (
          attachments.some(
            (a) => a.type === 'image' || a.type === 'giphy' || a.image_url,
          )
        ) {
          type = 'image';
          body = text || '📷 Foto';
        }
        result.set(matchId, {
          id: last.id ?? `${matchId}-last`,
          body,
          type,
          createdAt: (last.created_at
            ? new Date(last.created_at)
            : new Date()
          ).toISOString(),
          fromMe: last.user?.id === userId,
        });
      }
    } catch (err) {
      this.logger.warn(
        `queryMatchChannels falló: ${err instanceof Error ? err.message : err}`,
      );
    }
    return result;
  }

  private async loadMatchChannelContext(userId: string, matchId: string) {
    const myPet = await this.prisma.pet.findUnique({ where: { userId } });
    if (!myPet) {
      throw new NotFoundException('No tenés mascota configurada.');
    }

    const match = await this.prisma.match.findUnique({
      where: { id: matchId },
      include: {
        petA: {
          include: {
            media: {
              where: { type: PetMediaType.photo },
              orderBy: [{ isPrimary: 'desc' }, { sortOrder: 'asc' }],
              take: 1,
              select: { url: true },
            },
          },
        },
        petB: {
          include: {
            media: {
              where: { type: PetMediaType.photo },
              orderBy: [{ isPrimary: 'desc' }, { sortOrder: 'asc' }],
              take: 1,
              select: { url: true },
            },
          },
        },
      },
    });

    if (!match) {
      throw new NotFoundException('Match no encontrado.');
    }
    if (match.petAId !== myPet.id && match.petBId !== myPet.id) {
      throw new NotFoundException('Match no encontrado.');
    }

    const toProfile = (pet: typeof match.petA): StreamUserProfile => ({
      id: pet.userId,
      name: pet.name?.trim() || 'Mascota',
      image: pet.media[0]?.url ?? pet.photoUrl ?? undefined,
    });

    const members = [toProfile(match.petA), toProfile(match.petB)];
    const other = match.petAId === myPet.id ? match.petB : match.petA;
    // Nombre estable del canal (no depende de quién abre el chat).
    const names = members
      .map((m) => m.name)
      .slice()
      .sort((a, b) => a.localeCompare(b));

    return {
      members,
      channelName: names.join(' & '),
      channelImage:
        other.media[0]?.url ?? other.photoUrl ?? undefined,
      other: toProfile(other),
    };
  }

  private async buildStreamUser(userId: string): Promise<StreamUserProfile> {
    const pet = await this.prisma.pet.findUnique({
      where: { userId },
      include: {
        media: {
          where: { type: PetMediaType.photo },
          orderBy: [{ isPrimary: 'desc' }, { sortOrder: 'asc' }],
          take: 1,
          select: { url: true },
        },
        user: { select: { profile: { select: { name: true, avatarUrl: true } } } },
      },
    });

    if (pet?.name?.trim()) {
      return {
        id: userId,
        name: pet.name.trim(),
        image: pet.media[0]?.url ?? pet.photoUrl ?? undefined,
      };
    }

    const profileName = pet?.user.profile?.name?.trim();
    return {
      id: userId,
      name: profileName || 'Usuario tinDog',
      image: pet?.user.profile?.avatarUrl ?? undefined,
    };
  }

  private requireStream() {
    if (!this.stream.isEnabled()) {
      throw new ServiceUnavailableException(
        'Stream Chat no está configurado en el servidor.',
      );
    }
  }
}
