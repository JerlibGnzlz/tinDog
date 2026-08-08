import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import type { AuthUser } from '../common/types/auth-user.type';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { DiscoverQueryDto } from './dto/discover-query.dto';
import { SendMessageDto } from './dto/send-message.dto';
import { TargetPetDto } from './dto/target-pet.dto';
import { MatchingService } from './matching.service';

@Controller()
@UseGuards(JwtAuthGuard)
export class MatchingController {
  constructor(private readonly matchingService: MatchingService) {}

  @Get('discover')
  discover(
    @CurrentUser() user: AuthUser,
    @Query() query: DiscoverQueryDto,
  ) {
    return this.matchingService.discover(user.id, {
      limit: query.limit ?? 20,
      mode: query.mode ?? 'for_you',
      breed: query.breed,
      minAge: query.minAge,
      maxAge: query.maxAge,
      maxKm: query.maxKm,
    });
  }

  @Post('likes')
  like(@CurrentUser() user: AuthUser, @Body() dto: TargetPetDto) {
    return this.matchingService.like(user.id, dto.toPetId);
  }

  @Get('likes/sent')
  listSent(@CurrentUser() user: AuthUser) {
    return this.matchingService.listSentLikes(user.id);
  }

  @Get('likes/received')
  listReceived(@CurrentUser() user: AuthUser) {
    return this.matchingService.listReceivedLikes(user.id);
  }

  @Get('likes/summary')
  summary(@CurrentUser() user: AuthUser) {
    return this.matchingService.likesSummary(user.id);
  }

  @Post('passes')
  pass(@CurrentUser() user: AuthUser, @Body() dto: TargetPetDto) {
    return this.matchingService.pass(user.id, dto.toPetId);
  }

  @Get('matches')
  listMatches(@CurrentUser() user: AuthUser) {
    return this.matchingService.listMatches(user.id);
  }

  @Get('matches/:matchId/messages')
  listMessages(
    @CurrentUser() user: AuthUser,
    @Param('matchId', ParseUUIDPipe) matchId: string,
  ) {
    return this.matchingService.listMessages(user.id, matchId);
  }

  @Post('matches/:matchId/messages')
  sendMessage(
    @CurrentUser() user: AuthUser,
    @Param('matchId', ParseUUIDPipe) matchId: string,
    @Body() dto: SendMessageDto,
  ) {
    return this.matchingService.sendMessage(user.id, matchId, dto);
  }
}
