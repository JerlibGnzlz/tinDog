import { Module } from '@nestjs/common';
import { ChatController } from './chat.controller';
import { ChatService } from './chat.service';
import { StreamChatService } from './stream-chat.service';

@Module({
  controllers: [ChatController],
  providers: [StreamChatService, ChatService],
  exports: [ChatService, StreamChatService],
})
export class ChatModule {}
