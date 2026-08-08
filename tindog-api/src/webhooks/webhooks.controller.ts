import {
  Controller,
  Headers,
  HttpCode,
  Post,
  Req,
  UnauthorizedException,
  Logger,
} from '@nestjs/common';
import type { RawBodyRequest } from '@nestjs/common';
import type { Request } from 'express';
import { StreamWebhookService } from './stream-webhook.service';

@Controller('webhooks')
export class WebhooksController {
  private readonly logger = new Logger(WebhooksController.name);

  constructor(private readonly streamWebhooks: StreamWebhookService) {}

  /**
   * Stream Chat → Nest (sin JWT).
   * Requiere raw body + header X-Signature.
   */
  @Post('stream')
  @HttpCode(200)
  async handleStream(
    @Req() req: RawBodyRequest<Request>,
    @Headers('x-signature') signature?: string,
  ) {
    const rawBody = req.rawBody;
    if (!rawBody || !signature) {
      this.logger.warn('Webhook Stream sin rawBody o X-Signature');
      throw new UnauthorizedException('Webhook inválido');
    }

    await this.streamWebhooks.handle(rawBody, signature);
    return { ok: true };
  }
}
