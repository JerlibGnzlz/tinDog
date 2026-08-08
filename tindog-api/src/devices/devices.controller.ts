import { Body, Controller, Delete, Post, UseGuards } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { AuthUser } from '../common/types/auth-user.type';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RegisterDeviceDto } from './dto/register-device.dto';
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
}
