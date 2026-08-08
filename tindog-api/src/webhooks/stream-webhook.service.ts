import { Injectable, Logger, UnauthorizedException } from '@nestjs/common';
import { PushService } from '../devices/push.service';
import { PrismaService } from '../prisma/prisma.service';
import { StreamChatService } from '../chat/stream-chat.service';

type StreamWebhookEvent = {
  type?: string;
  channel_id?: string;
  channel_type?: string;
  cid?: string;
  message?: {
    id?: string;
    text?: string;
    type?: string;
    silent?: boolean;
    user?: { id?: string; name?: string };
    attachments?: Array<{ type?: string }>;
  };
  user?: { id?: string; name?: string };
};

@Injectable()
export class StreamWebhookService {
  private readonly logger = new Logger(StreamWebhookService.name);

  constructor(
    private readonly streamChat: StreamChatService,
    private readonly push: PushService,
    private readonly prisma: PrismaService,
  ) {}

  async handle(rawBody: Buffer, signature: string): Promise<void> {
    let event: StreamWebhookEvent;
    try {
      event = this.streamChat.verifyAndParseWebhook(rawBody, signature);
    } catch (err) {
      this.logger.warn(
        `Firma webhook inválida: ${err instanceof Error ? err.message : err}`,
      );
      throw new UnauthorizedException('Firma Stream inválida');
    }

    if (event.type !== 'message.new') {
      return;
    }

    const message = event.message;
    if (!message || message.silent === true) return;
    if (message.type && message.type !== 'regular') return;

    const senderId = message.user?.id ?? event.user?.id;
    if (!senderId) return;

    const matchId = this.extractMatchId(event);
    if (!matchId) {
      this.logger.debug('message.new sin matchId — ignorado');
      return;
    }

    const match = await this.prisma.match.findUnique({
      where: { id: matchId },
      include: {
        petA: { select: { userId: true, name: true } },
        petB: { select: { userId: true, name: true } },
      },
    });
    if (!match) return;

    const senderName =
      message.user?.name?.trim() ||
      event.user?.name?.trim() ||
      (match.petA.userId === senderId
        ? match.petA.name
        : match.petB.userId === senderId
          ? match.petB.name
          : null) ||
      'Alguien';

    const recipients = [match.petA, match.petB]
      .map((p) => p.userId)
      .filter((id) => id !== senderId);

    const body = this.previewBody(message);
    this.logger.log(
      `message.new match=${matchId} from=${senderId} → push a ${recipients.length} usuario(s)`,
    );
    await Promise.all(
      recipients.map((userId) =>
        this.push.notifyChatMessage({
          recipientUserId: userId,
          senderName,
          body,
          matchId,
        }),
      ),
    );
  }

  private extractMatchId(event: StreamWebhookEvent): string | null {
    const channelId = event.channel_id?.trim();
    if (channelId?.startsWith('match-')) {
      return channelId.slice('match-'.length);
    }
    const cid = event.cid?.trim(); // messaging:match-uuid
    if (cid?.includes(':')) {
      const id = cid.split(':')[1];
      if (id?.startsWith('match-')) {
        return id.slice('match-'.length);
      }
    }
    return null;
  }

  private previewBody(message: NonNullable<StreamWebhookEvent['message']>) {
    const text = message.text?.trim();
    if (text) {
      return text.length > 120 ? `${text.slice(0, 117)}…` : text;
    }
    const types = (message.attachments ?? []).map((a) => a.type);
    if (types.includes('image') || types.includes('img')) return '📷 Foto';
    if (types.includes('video')) return '🎬 Video';
    if (types.includes('voiceRecording') || types.includes('audio')) {
      return '🎤 Mensaje de voz';
    }
    if (types.includes('giphy') || types.includes('gif')) return 'GIF';
    return 'Nuevo mensaje';
  }
}
