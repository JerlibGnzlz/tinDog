import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import type { AuthUser } from '../common/types/auth-user.type';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UpdatePetDto } from './dto/update-pet.dto';
import { AddPetMediaDto } from './dto/add-pet-media.dto';
import { AddPetVideoDto } from './dto/add-pet-video.dto';
import { ReorderPetMediaDto } from './dto/reorder-pet-media.dto';
import { PetMediaService } from './pet-media.service';
import { PetsService } from './pets.service';

@Controller('pets')
@UseGuards(JwtAuthGuard)
export class PetsController {
  constructor(
    private readonly petsService: PetsService,
    private readonly petMediaService: PetMediaService,
  ) {}

  @Get('me')
  getMe(@CurrentUser() user: AuthUser) {
    return this.petsService.getByUserId(user.id);
  }

  @Patch('me')
  updateMe(@CurrentUser() user: AuthUser, @Body() dto: UpdatePetDto) {
    return this.petsService.updateByUserId(user.id, dto);
  }

  @Get('me/media')
  listMyMedia(@CurrentUser() user: AuthUser) {
    return this.petMediaService.listPhotos(user.id);
  }

  @Post('me/media')
  addMyMedia(@CurrentUser() user: AuthUser, @Body() dto: AddPetMediaDto) {
    return this.petMediaService.addPhoto(user.id, dto);
  }

  @Patch('me/media/reorder')
  reorderMyMedia(
    @CurrentUser() user: AuthUser,
    @Body() dto: ReorderPetMediaDto,
  ) {
    return this.petMediaService.reorder(user.id, dto.orderedIds);
  }

  @Patch('me/media/:id/primary')
  setPrimaryMyMedia(
    @CurrentUser() user: AuthUser,
    @Param('id') mediaId: string,
  ) {
    return this.petMediaService.setPrimary(user.id, mediaId);
  }

  @Delete('me/media/:id')
  deleteMyMedia(@CurrentUser() user: AuthUser, @Param('id') mediaId: string) {
    return this.petMediaService.deletePhoto(user.id, mediaId);
  }

  @Get('me/videos')
  listMyVideos(@CurrentUser() user: AuthUser) {
    return this.petMediaService.listVideos(user.id);
  }

  @Post('me/videos')
  addMyVideo(@CurrentUser() user: AuthUser, @Body() dto: AddPetVideoDto) {
    return this.petMediaService.addVideo(user.id, dto);
  }

  @Delete('me/videos/:id')
  deleteMyVideo(@CurrentUser() user: AuthUser, @Param('id') mediaId: string) {
    return this.petMediaService.deleteVideo(user.id, mediaId);
  }
}
