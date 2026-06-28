import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PetMediaType } from '@prisma/client';
import { CloudinaryService } from '../media/cloudinary.service';
import { PrismaService } from '../prisma/prisma.service';
import { AddPetMediaDto } from './dto/add-pet-media.dto';
import { AddPetVideoDto } from './dto/add-pet-video.dto';
import {
  MAX_PET_PHOTOS,
  MAX_PET_VIDEOS,
  MAX_VIDEO_DURATION_SEC,
} from './pet-media.constants';
import { PetsService } from './pets.service';

@Injectable()
export class PetMediaService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly petsService: PetsService,
    private readonly cloudinaryService: CloudinaryService,
  ) {}

  async listPhotos(userId: string) {
    const pet = await this.petsService.getByUserId(userId);
    return this.prisma.petMedia.findMany({
      where: { petId: pet.id, type: PetMediaType.photo },
      orderBy: { sortOrder: 'asc' },
    });
  }

  async addPhoto(userId: string, dto: AddPetMediaDto) {
    const pet = await this.petsService.getByUserId(userId);
    const photoCount = await this.prisma.petMedia.count({
      where: { petId: pet.id, type: PetMediaType.photo },
    });

    if (photoCount >= MAX_PET_PHOTOS) {
      throw new BadRequestException(
        `Solo podés subir hasta ${MAX_PET_PHOTOS} fotos`,
      );
    }

    const isFirstPhoto = photoCount === 0;

    const media = await this.prisma.petMedia.create({
      data: {
        petId: pet.id,
        type: PetMediaType.photo,
        url: dto.url,
        publicId: dto.publicId,
        sortOrder: photoCount,
        isPrimary: isFirstPhoto,
      },
    });

    if (isFirstPhoto) {
      await this.syncPrimaryPhotoUrl(pet.id);
    }

    return media;
  }

  async listVideos(userId: string) {
    const pet = await this.petsService.getByUserId(userId);
    return this.prisma.petMedia.findMany({
      where: { petId: pet.id, type: PetMediaType.video },
      orderBy: { sortOrder: 'asc' },
    });
  }

  async addVideo(userId: string, dto: AddPetVideoDto) {
    const pet = await this.petsService.getByUserId(userId);
    const videoCount = await this.prisma.petMedia.count({
      where: { petId: pet.id, type: PetMediaType.video },
    });

    if (videoCount >= MAX_PET_VIDEOS) {
      throw new BadRequestException(
        `Solo podés subir hasta ${MAX_PET_VIDEOS} videos`,
      );
    }

    if (
      dto.durationSec != null &&
      dto.durationSec > MAX_VIDEO_DURATION_SEC
    ) {
      throw new BadRequestException(
        `El video no puede durar más de ${MAX_VIDEO_DURATION_SEC} segundos`,
      );
    }

    return this.prisma.petMedia.create({
      data: {
        petId: pet.id,
        type: PetMediaType.video,
        url: dto.url,
        publicId: dto.publicId,
        sortOrder: videoCount,
        isPrimary: false,
        durationSec: dto.durationSec,
      },
    });
  }

  async deleteVideo(userId: string, mediaId: string) {
    const pet = await this.petsService.getByUserId(userId);
    const media = await this.findOwnedVideo(pet.id, mediaId);

    await this.cloudinaryService.destroyVideo(media.publicId);
    await this.prisma.petMedia.delete({ where: { id: media.id } });

    await this.reindexVideos(pet.id);
    return this.listVideos(userId);
  }

  async setPrimary(userId: string, mediaId: string) {
    const pet = await this.petsService.getByUserId(userId);
    const media = await this.findOwnedPhoto(pet.id, mediaId);

    await this.prisma.$transaction([
      this.prisma.petMedia.updateMany({
        where: { petId: pet.id, type: PetMediaType.photo },
        data: { isPrimary: false },
      }),
      this.prisma.petMedia.update({
        where: { id: media.id },
        data: { isPrimary: true },
      }),
    ]);

    await this.syncPrimaryPhotoUrl(pet.id);
    return this.listPhotos(userId);
  }

  async reorder(userId: string, orderedIds: string[]) {
    const pet = await this.petsService.getByUserId(userId);
    const photos = await this.prisma.petMedia.findMany({
      where: { petId: pet.id, type: PetMediaType.photo },
      orderBy: { sortOrder: 'asc' },
    });

    if (orderedIds.length !== photos.length) {
      throw new BadRequestException('La lista de fotos no coincide');
    }

    const photoIds = new Set(photos.map((photo) => photo.id));
    for (const id of orderedIds) {
      if (!photoIds.has(id)) {
        throw new BadRequestException('Foto no encontrada');
      }
    }

    await this.prisma.$transaction(
      orderedIds.map((id, index) =>
        this.prisma.petMedia.update({
          where: { id },
          data: { sortOrder: index },
        }),
      ),
    );

    return this.listPhotos(userId);
  }

  async deletePhoto(userId: string, mediaId: string) {
    const pet = await this.petsService.getByUserId(userId);
    const media = await this.findOwnedPhoto(pet.id, mediaId);

    await this.cloudinaryService.destroyImage(media.publicId);
    await this.prisma.petMedia.delete({ where: { id: media.id } });

    const remaining = await this.prisma.petMedia.findMany({
      where: { petId: pet.id, type: PetMediaType.photo },
      orderBy: { sortOrder: 'asc' },
    });

    if (remaining.length === 0) {
      await this.prisma.pet.update({
        where: { id: pet.id },
        data: { photoUrl: null },
      });
      return [];
    }

    const hasPrimary = remaining.some((item) => item.isPrimary);
    if (!hasPrimary) {
      await this.prisma.petMedia.update({
        where: { id: remaining[0].id },
        data: { isPrimary: true },
      });
    }

    await this.reindexPhotos(pet.id);
    await this.syncPrimaryPhotoUrl(pet.id);
    return this.listPhotos(userId);
  }

  private async reindexPhotos(petId: string) {
    const photos = await this.prisma.petMedia.findMany({
      where: { petId, type: PetMediaType.photo },
      orderBy: { sortOrder: 'asc' },
    });

    await this.prisma.$transaction(
      photos.map((photo, index) =>
        this.prisma.petMedia.update({
          where: { id: photo.id },
          data: { sortOrder: index },
        }),
      ),
    );
  }

  private async findOwnedPhoto(petId: string, mediaId: string) {
    const media = await this.prisma.petMedia.findFirst({
      where: { id: mediaId, petId, type: PetMediaType.photo },
    });
    if (!media) {
      throw new NotFoundException('Foto no encontrada');
    }
    return media;
  }

  private async findOwnedVideo(petId: string, mediaId: string) {
    const media = await this.prisma.petMedia.findFirst({
      where: { id: mediaId, petId, type: PetMediaType.video },
    });
    if (!media) {
      throw new NotFoundException('Video no encontrado');
    }
    return media;
  }

  private async reindexVideos(petId: string) {
    const videos = await this.prisma.petMedia.findMany({
      where: { petId, type: PetMediaType.video },
      orderBy: { sortOrder: 'asc' },
    });

    await this.prisma.$transaction(
      videos.map((video, index) =>
        this.prisma.petMedia.update({
          where: { id: video.id },
          data: { sortOrder: index },
        }),
      ),
    );
  }

  private async syncPrimaryPhotoUrl(petId: string) {
    const primary = await this.prisma.petMedia.findFirst({
      where: { petId, type: PetMediaType.photo, isPrimary: true },
    });

    await this.prisma.pet.update({
      where: { id: petId },
      data: { photoUrl: primary?.url ?? null },
    });
  }
}
