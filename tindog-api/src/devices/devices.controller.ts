import { Body, Controller, Delete, Put, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { AuthUser } from '../common/types/auth-user.type';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RegisterDeviceDto } from './dto/register-device.dto';
import { SetActiveChatDto } from './dto/set-active-chat.dto';
import { PushService } from './push.service';

@Controller('devices')
@UseGuards(JwtAuthGuard)
export class DevicesController {
  constructor(private readonly pushService: PushService) {}

  @Post()
  register(@CurrentUser() user: AuthUser, @Body() dto: RegisterDeviceDto) {
    return this.pushService.registerToken(
      user.id,
      dto.token,
      dto.platform ?? 'android',
    );
  }

  @Delete()
  async unregister(
    @CurrentUser() user: AuthUser,
    @Body() dto: RegisterDeviceDto,
  ) {
    await this.pushService.unregisterToken(user.id, dto.token);
    return { ok: true };
  }

  /** Chat abierto → Nest omite push de mensajes de ese match. */
  @Put('active-chat')
  setActiveChat(@CurrentUser() user: AuthUser, @Body() dto: SetActiveChatDto) {
    return this.pushService.setActiveChat(user.id, dto.matchId ?? null);
  }
}
