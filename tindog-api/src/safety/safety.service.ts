import {
  BadRequestException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
  forwardRef,
} from '@nestjs/common';
import { ReportReason } from '@prisma/client';
import { StreamChatService } from '../chat/stream-chat.service';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class SafetyService {
  private readonly logger = new Logger(SafetyService.name);

  constructor(
    private readonly prisma: PrismaService,
    @Inject(forwardRef(() => StreamChatService))
    private readonly streamChat: StreamChatService,
  ) {}

  /** Usuarios con los que hay bloqueo (en cualquier dirección). */
  async relatedBlockedUserIds(userId: string): Promise<string[]> {
    const blocks = await this.prisma.userBlock.findMany({
      where: {
        OR: [{ blockerId: userId }, { blockedId: userId }],
      },
      select: { blockerId: true, blockedId: true },
    });
    return blocks.map((b) =>
      b.blockerId === userId ? b.blockedId : b.blockerId,
    );
  }

  async isBlockedEitherWay(userA: string, userB: string): Promise<boolean> {
    if (userA === userB) return false;
    const row = await this.prisma.userBlock.findFirst({
      where: {
        OR: [
          { blockerId: userA, blockedId: userB },
          { blockerId: userB, blockedId: userA },
        ],
      },
      select: { id: true },
    });
    return row != null;
  }

  async assertNotBlocked(userA: string, userB: string): Promise<void> {
    if (await this.isBlockedEitherWay(userA, userB)) {
      throw new BadRequestException(
        'No podés interactuar con este usuario (bloqueo activo).',
      );
    }
  }

  async block(blockerId: string, blockedId: string) {
    if (blockerId === blockedId) {
      throw new BadRequestException('No podés bloquearte a vos mismo.');
    }

    const target = await this.prisma.user.findUnique({
      where: { id: blockedId },
      select: { id: true },
    });
    if (!target) {
      throw new NotFoundException('Usuario no encontrado.');
    }

    await this.prisma.userBlock.upsert({
      where: {
        blockerId_blockedId: { blockerId, blockedId },
      },
      create: { blockerId, blockedId },
      update: {},
    });

    await this.cleanupRelationship(blockerId, blockedId);

    return { blocked: true, userId: blockedId };
  }

  async unblock(blockerId: string, blockedId: string) {
    await this.prisma.userBlock.deleteMany({
      where: { blockerId, blockedId },
    });

    // Quitar el pass automático del bloqueo para que puedan volver a verse
    // en Desliza (el match anterior no se restaura).
    const pets = await this.prisma.pet.findMany({
      where: { userId: { in: [blockerId, blockedId] } },
      select: { id: true, userId: true },
    });
    const petA = pets.find((p) => p.userId === blockerId);
    const petB = pets.find((p) => p.userId === blockedId);
    if (petA && petB) {
      await this.prisma.pass.deleteMany({
        where: { fromPetId: petA.id, toPetId: petB.id },
      });
    }

    return { blocked: false, userId: blockedId };
  }

  async report(
    reporterId: string,
    reportedId: string,
    reason: ReportReason,
    options?: { details?: string; matchId?: string; blockAlso?: boolean },
  ) {
    if (reporterId === reportedId) {
      throw new BadRequestException('No podés reportarte a vos mismo.');
    }

    const target = await this.prisma.user.findUnique({
      where: { id: reportedId },
      select: { id: true },
    });
    if (!target) {
      throw new NotFoundException('Usuario no encontrado.');
    }

    const report = await this.prisma.userReport.create({
      data: {
        reporterId,
        reportedId,
        reason,
        details: options?.details?.trim() || null,
        matchId: options?.matchId ?? null,
      },
    });

    let blocked = false;
    if (options?.blockAlso) {
      await this.block(reporterId, reportedId);
      blocked = true;
    }

    return {
      reported: true,
      reportId: report.id,
      blocked,
    };
  }

  async listBlocked(blockerId: string) {
    const rows = await this.prisma.userBlock.findMany({
      where: { blockerId },
      orderBy: { createdAt: 'desc' },
      include: {
        blocked: {
          select: {
            id: true,
            pet: {
              select: {
                id: true,
                name: true,
                photoUrl: true,
              },
            },
            profile: { select: { name: true } },
          },
        },
      },
    });

    return rows.map((r) => ({
      userId: r.blockedId,
      blockedAt: r.createdAt.toISOString(),
      displayName:
        r.blocked.pet?.name?.trim() ||
        r.blocked.profile?.name?.trim() ||
        'Usuario',
      photoUrl: r.blocked.pet?.photoUrl ?? null,
      petId: r.blocked.pet?.id ?? null,
    }));
  }

  /** Quita likes, passes y match; borra el canal Stream del match. */
  private async cleanupRelationship(userA: string, userB: string) {
    const pets = await this.prisma.pet.findMany({
      where: { userId: { in: [userA, userB] } },
      select: { id: true, userId: true },
    });
    const petA = pets.find((p) => p.userId === userA);
    const petB = pets.find((p) => p.userId === userB);
    if (!petA || !petB) return;

    const [id1, id2] =
      petA.id < petB.id ? [petA.id, petB.id] : [petB.id, petA.id];

    const match = await this.prisma.match.findUnique({
      where: { petAId_petBId: { petAId: id1, petBId: id2 } },
      select: { id: true },
    });

    await this.prisma.$transaction([
      this.prisma.like.deleteMany({
        where: {
          OR: [
            { fromPetId: petA.id, toPetId: petB.id },
            { fromPetId: petB.id, toPetId: petA.id },
          ],
        },
      }),
      this.prisma.pass.deleteMany({
        where: {
          OR: [
            { fromPetId: petA.id, toPetId: petB.id },
            { fromPetId: petB.id, toPetId: petA.id },
          ],
        },
      }),
      this.prisma.match.deleteMany({
        where: { petAId: id1, petBId: id2 },
      }),
      ...(match
        ? [
            this.prisma.mutedChat.deleteMany({
              where: { matchId: match.id },
            }),
          ]
        : []),
      // Evitar que vuelva a aparecer en discover para quien bloqueó.
      this.prisma.pass.upsert({
        where: {
          fromPetId_toPetId: { fromPetId: petA.id, toPetId: petB.id },
        },
        create: { fromPetId: petA.id, toPetId: petB.id },
        update: {},
      }),
    ]);

    if (match) {
      await this.streamChat.deleteMatchChannel(match.id);
      this.logger.log(
        `Bloqueo: match ${match.id} limpiado (+ canal Stream)`,
      );
    }
  }
}
