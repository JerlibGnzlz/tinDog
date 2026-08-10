import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';
import { PrismaService } from '../prisma/prisma.service';

export type PushPayload = {
  title: string;
  body: string;
  data?: Record<string, string>;
  /** Canal Android (debe existir en la app). */
  androidChannelId?: string;
};

@Injectable()
export class PushService implements OnModuleInit {
  private readonly logger = new Logger(PushService.name);
  private ready = false;

  /** Chat abierto en la app (in-memory; TTL evita estados huérfanos). */
  private readonly activeChatByUser = new Map<
    string,
    { matchId: string; at: number }
  >();
  /** Corto: si al minimizar falla el clear HTTP, el push no queda bloqueado minutos. */
  private static readonly ACTIVE_CHAT_TTL_MS = 75 * 1000;

  constructor(
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
  ) {}

  /** La app avisa qué match tiene abierto para no spamear push. */
  setActiveChat(userId: string, matchId?: string | null): { ok: true } {
    const clean = matchId?.trim();
    if (!clean) {
      const had = this.activeChatByUser.delete(userId);
      if (had) {
        this.logger.log(`active-chat clear user=${userId}`);
      }
    } else {
      this.activeChatByUser.set(userId, { matchId: clean, at: Date.now() });
      this.logger.debug(`active-chat set user=${userId} match=${clean}`);
    }
    return { ok: true };
  }

  isViewingChat(userId: string, matchId: string): boolean {
    const row = this.activeChatByUser.get(userId);
    if (!row || row.matchId !== matchId) return false;
    if (Date.now() - row.at > PushService.ACTIVE_CHAT_TTL_MS) {
      this.activeChatByUser.delete(userId);
      this.logger.log(
        `active-chat expiró user=${userId} match=${matchId}`,
      );
      return false;
    }
    return true;
  }

  async setChatMuted(
    userId: string,
    matchId: string,
    muted: boolean,
  ): Promise<{ ok: true; muted: boolean }> {
    const id = matchId.trim();
    if (muted) {
      await this.prisma.mutedChat.upsert({
        where: { userId_matchId: { userId, matchId: id } },
        create: { userId, matchId: id },
        update: {},
      });
    } else {
      await this.prisma.mutedChat.deleteMany({
        where: { userId, matchId: id },
      });
    }
    return { ok: true, muted };
  }

  async isChatMuted(userId: string, matchId: string): Promise<boolean> {
    const row = await this.prisma.mutedChat.findUnique({
      where: { userId_matchId: { userId, matchId } },
      select: { id: true },
    });
    return row != null;
  }

  /** Limpia mutes de un match (unmatch / bloqueo). */
  async clearMutesForMatch(matchId: string): Promise<void> {
    await this.prisma.mutedChat.deleteMany({ where: { matchId } });
  }

  onModuleInit() {
    const projectId = this.config.get<string>('FIREBASE_PROJECT_ID')?.trim();
    const clientEmail = this.config
      .get<string>('FIREBASE_CLIENT_EMAIL')
      ?.trim();
    const privateKeyRaw = this.config.get<string>('FIREBASE_PRIVATE_KEY');

    if (!projectId || !clientEmail || !privateKeyRaw?.trim()) {
      this.logger.warn(
        'Firebase Admin no configurado (FIREBASE_*). Push deshabilitado.',
      );
      return;
    }

    const privateKey = privateKeyRaw.replace(/\\n/g, '\n');

    try {
      if (!admin.apps.length) {
        admin.initializeApp({
          credential: admin.credential.cert({
            projectId,
            clientEmail,
            privateKey,
          }),
        });
      }
      this.ready = true;
      this.logger.log(`Firebase Admin listo (${projectId})`);
    } catch (err) {
      this.logger.error(
        `Firebase Admin init falló: ${err instanceof Error ? err.message : err}`,
      );
    }
  }

  async registerToken(
    userId: string,
    token: string,
    platform = 'android',
  ): Promise<{ ok: true }> {
    const clean = token.trim();
    await this.prisma.deviceToken.upsert({
      where: { token: clean },
      create: {
        userId,
        token: clean,
        platform: platform.trim() || 'android',
      },
      update: {
        userId,
        platform: platform.trim() || 'android',
      },
    });
    return { ok: true };
  }

  async unregisterToken(userId: string, token: string): Promise<void> {
    await this.prisma.deviceToken.deleteMany({
      where: { userId, token: token.trim() },
    });
  }

  /** Envía push a todos los devices del usuario (best-effort). */
  async sendToUser(userId: string, payload: PushPayload): Promise<void> {
    if (!this.ready) return;

    const devices = await this.prisma.deviceToken.findMany({
      where: { userId },
      select: { id: true, token: true },
    });
    if (devices.length === 0) {
      this.logger.warn(`Push sin device_tokens user=${userId}`);
      return;
    }
    this.logger.log(
      `FCM → user=${userId} devices=${devices.length} title="${payload.title}"`,
    );

    const staleIds: string[] = [];

    await Promise.all(
      devices.map(async (device) => {
        try {
          await admin.messaging().send({
            token: device.token,
            notification: {
              title: payload.title,
              body: payload.body,
            },
            data: payload.data,
            android: {
              priority: 'high',
              notification: {
                channelId: payload.androidChannelId ?? 'tindog_matches',
                sound: 'default',
              },
            },
          });
        } catch (err) {
          const code =
            err && typeof err === 'object' && 'code' in err
              ? String((err as { code: unknown }).code)
              : '';
          if (
            code.includes('registration-token-not-registered') ||
            code.includes('invalid-registration-token')
          ) {
            staleIds.push(device.id);
          } else {
            this.logger.warn(
              `FCM fallo user=${userId}: ${err instanceof Error ? err.message : err}`,
            );
          }
        }
      }),
    );

    if (staleIds.length > 0) {
      await this.prisma.deviceToken.deleteMany({
        where: { id: { in: staleIds } },
      });
    }
  }

  async notifyMatch(params: {
    recipientUserId: string;
    otherPetName: string;
    matchId: string;
  }): Promise<void> {
    await this.sendToUser(params.recipientUserId, {
      title: '¡Es un match! 🐾',
      body: `Vos y ${params.otherPetName} se gustaron.`,
      data: {
        type: 'match',
        matchId: params.matchId,
      },
      androidChannelId: 'tindog_matches',
    });
  }

  async notifyChatMessage(params: {
    recipientUserId: string;
    senderName: string;
    body: string;
    matchId: string;
  }): Promise<void> {
    await this.sendToUser(params.recipientUserId, {
      title: `Nuevo mensaje de ${params.senderName}`,
      body: params.body,
      data: {
        type: 'message',
        matchId: params.matchId,
      },
      androidChannelId: 'tindog_chat',
    });
  }
}
