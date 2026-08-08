import { Module, forwardRef } from '@nestjs/common';
import { SafetyModule } from '../safety/safety.module';
import { ChatController } from './chat.controller';
import { ChatService } from './chat.service';
import { StreamChatService } from './stream-chat.service';

@Module({
  imports: [forwardRef(() => SafetyModule)],
  controllers: [ChatController],
  providers: [StreamChatService, ChatService],
  exports: [ChatService, StreamChatService],
})
export class ChatModule {}
