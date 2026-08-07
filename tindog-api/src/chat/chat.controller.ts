import { Controller, Get, Param, ParseUUIDPipe, Post, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import type { AuthUser } from '../common/types/auth-user.type';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { ChatService } from './chat.service';

@Controller('chat')
@UseGuards(JwtAuthGuard)
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  /** Token Stream + perfil (nombre = mascota) para conectar el SDK. */
  @Get('token')
  getToken(@CurrentUser() user: AuthUser) {
    return this.chatService.getToken(user.id);
  }

  /** Asegura canal messaging por match y devuelve ids para watch(). */
  @Post('channels/:matchId/ensure')
  ensureChannel(
    @CurrentUser() user: AuthUser,
    @Param('matchId', ParseUUIDPipe) matchId: string,
  ) {
    return this.chatService.ensureChannel(user.id, matchId);
  }
}
