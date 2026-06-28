import { Module } from '@nestjs/common';
import { MediaModule } from '../media/media.module';
import { PetMediaService } from './pet-media.service';
import { PetsController } from './pets.controller';
import { PetsService } from './pets.service';

@Module({
  imports: [MediaModule],
  controllers: [PetsController],
  providers: [PetsService, PetMediaService],
})
export class PetsModule {}
