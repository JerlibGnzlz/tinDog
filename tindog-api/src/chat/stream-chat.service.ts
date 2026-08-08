import {
  Injectable,
  Logger,
  OnModuleInit,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { StreamChat, Channel as StreamChannel } from 'stream-chat';

export type StreamUserProfile = {
  id: string;
  name: string;
  image?: string;
};

@Injectable()
export class StreamChatService implements OnModuleInit {
  private readonly logger = new Logger(StreamChatService.name);
  private client: StreamChat | null = null;
  private apiKey = '';

  constructor(private readonly config: ConfigService) {}

  onModuleInit() {
    const apiKey = this.config.get<string>('STREAM_API_KEY')?.trim();
    const apiSecret = this.config.get<string>('STREAM_API_SECRET')?.trim();
    if (!apiKey || !apiSecret) {
      this.logger.warn(
        'STREAM_API_KEY / STREAM_API_SECRET no configurados — chat Stream deshabilitado.',
      );
      return;
    }
    this.apiKey = apiKey;
    this.client = StreamChat.getInstance(apiKey, apiSecret);
    this.logger.log('Stream Chat client listo');
  }

  isEnabled(): boolean {
    return this.client != null;
  }

  getApiKey(): string {
    this.requireClient();
    return this.apiKey;
  }

  createUserToken(userId: string): string {
    return this.requireClient().createToken(userId);
  }

  async upsertUsers(users: StreamUserProfile[]): Promise<void> {
    const client = this.requireClient();
    const payloads = users.map((u) => ({
      id: u.id,
      name: u.name,
      image: u.image,
    }));
    // create/update completo
    await client.upsertUsers(payloads);
    // fuerza name/image por si Stream conservó un valor viejo
    await Promise.all(
      users.map((u) =>
        client
          .partialUpdateUser({
            id: u.id,
            set: {
              name: u.name,
              ...(u.image ? { image: u.image } : { image: '' }),
            },
          })
          .catch(() => undefined),
      ),
    );
  }

  channelIdForMatch(matchId: string): string {
    // Stream channel ids: letras, números, - _
    return `match-${matchId}`;
  }

  /** Verifica X-Signature de Stream y parsea el JSON del webhook. */
  verifyAndParseWebhook<T = unknown>(rawBody: Buffer, signature: string): T {
    return this.requireClient().verifyAndParseWebhook(
      rawBody,
      signature,
    ) as T;
  }

  async ensureMatchChannel(params: {
    matchId: string;
    members: StreamUserProfile[];
    channelName: string;
    channelImage?: string;
  }): Promise<{ channelType: string; channelId: string }> {
    const client = this.requireClient();
    const channelId = this.channelIdForMatch(params.matchId);
    const memberIds = params.members.map((m) => m.id);

    await this.upsertUsers(params.members);

    const channelData = {
      members: memberIds,
      created_by_id: memberIds[0],
      name: params.channelName,
      image: params.channelImage,
      match_id: params.matchId,
    };

    const channel = client.channel(
      'messaging',
      channelId,
      // Custom fields (name, image, match_id) + members — tipado estricto del SDK
      channelData as never,
    );

    try {
      await channel.create();
    } catch (err: unknown) {
      // Ya existe u otro proceso lo creó — asegurar miembros; no pisar name/image
      // con la perspectiva de quien abre (eso cruzaba fotos en la UI).
      this.logger.debug(
        `channel.create ${channelId}: ${err instanceof Error ? err.message : err}`,
      );
      await channel.addMembers(memberIds).catch(() => undefined);
      await channel
        .updatePartial({
          set: {
            match_id: params.matchId,
          } as never,
        })
        .catch(() => undefined);
    }

    return { channelType: 'messaging', channelId };
  }

  /**
   * Borra el canal del match (bloqueo / unmatch).
   * Best-effort: si Stream no está configurado o el canal no existe, no falla.
   */
  async deleteMatchChannel(matchId: string): Promise<void> {
    if (!this.client) return;
    const channelId = this.channelIdForMatch(matchId);
    try {
      const channel = this.client.channel('messaging', channelId);
      await channel.delete();
      this.logger.log(`Canal Stream eliminado: ${channelId}`);
    } catch (err: unknown) {
      this.logger.warn(
        `No se pudo eliminar canal ${channelId}: ${
          err instanceof Error ? err.message : err
        }`,
      );
    }
  }

  async queryMatchChannels(
    userId: string,
    matchIds: string[],
  ): Promise<Map<string, StreamChannel>> {
    const client = this.requireClient();
    if (matchIds.length === 0) return new Map();

    const channelIds = matchIds.map((id) => this.channelIdForMatch(id));
    const channels = await client.queryChannels(
      {
        type: 'messaging',
        id: { $in: channelIds },
        members: { $in: [userId] },
      },
      [{ last_message_at: -1 as const }],
      { limit: Math.min(channelIds.length, 30), state: true },
    );

    const byMatch = new Map<string, StreamChannel>();
    for (const ch of channels) {
      const data = ch.data as { match_id?: string } | undefined;
      const matchId = data?.match_id ?? ch.id?.replace(/^match-/, '');
      if (matchId) byMatch.set(matchId, ch);
    }
    return byMatch;
  }

  private requireClient(): StreamChat {
    if (!this.client) {
      throw new ServiceUnavailableException(
        'Stream Chat no está configurado en el servidor.',
      );
    }
    return this.client;
  }
}
