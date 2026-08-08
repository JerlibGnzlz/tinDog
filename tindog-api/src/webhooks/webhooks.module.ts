import { Module } from '@nestjs/common';
import { ChatModule } from '../chat/chat.module';
import { DevicesModule } from '../devices/devices.module';
import { StreamWebhookService } from './stream-webhook.service';
import { WebhooksController } from './webhooks.controller';

@Module({
  imports: [ChatModule, DevicesModule],
  controllers: [WebhooksController],
  providers: [StreamWebhookService],
})
export class WebhooksModule {}
