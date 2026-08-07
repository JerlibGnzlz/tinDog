import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import type { AuthUser } from '../common/types/auth-user.type';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { BlockUserDto, ReportUserDto } from './dto/safety.dto';
import { SafetyService } from './safety.service';

@Controller('safety')
@UseGuards(JwtAuthGuard)
export class SafetyController {
  constructor(private readonly safetyService: SafetyService) {}

  @Get('blocks')
  listBlocks(@CurrentUser() user: AuthUser) {
    return this.safetyService.listBlocked(user.id);
  }

  @Post('blocks')
  block(@CurrentUser() user: AuthUser, @Body() dto: BlockUserDto) {
    return this.safetyService.block(user.id, dto.userId);
  }

  @Delete('blocks/:userId')
  unblock(
    @CurrentUser() user: AuthUser,
    @Param('userId', ParseUUIDPipe) userId: string,
  ) {
    return this.safetyService.unblock(user.id, userId);
  }

  @Post('reports')
  report(@CurrentUser() user: AuthUser, @Body() dto: ReportUserDto) {
    return this.safetyService.report(user.id, dto.userId, dto.reason, {
      details: dto.details,
      matchId: dto.matchId,
      blockAlso: dto.blockAlso,
    });
  }
}
