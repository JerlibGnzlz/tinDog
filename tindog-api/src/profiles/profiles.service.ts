import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Injectable()
export class ProfilesService {
  constructor(private readonly prisma: PrismaService) {}

  async getByUserId(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { email: true, googleSub: true },
    });
    if (!user) {
      throw new UnauthorizedException(
        'Sesión inválida. Vuelve a iniciar sesión.',
      );
    }

    const existing = await this.prisma.profile.findUnique({
      where: { userId },
    });
    const profile =
      existing ?? (await this.prisma.profile.create({ data: { userId } }));

    return {
      ...profile,
      email: user.email,
      googleLinked: Boolean(user.googleSub),
    };
  }

  async updateByUserId(userId: string, dto: UpdateProfileDto) {
    await this.getByUserId(userId);

    const {
      clearCoordinates,
      latitude,
      longitude,
      name,
      bio,
      avatarUrl,
      location,
    } = dto;

    const data: {
      name?: string;
      bio?: string;
      avatarUrl?: string;
      location?: string;
      latitude?: number | null;
      longitude?: number | null;
      locationUpdatedAt?: Date | null;
    } = {};

    if (name !== undefined) data.name = name;
    if (bio !== undefined) data.bio = bio;
    if (avatarUrl !== undefined) data.avatarUrl = avatarUrl;
    if (location !== undefined) data.location = location;

    if (clearCoordinates === true) {
      data.latitude = null;
      data.longitude = null;
      data.locationUpdatedAt = null;
    } else if (latitude !== undefined && longitude !== undefined) {
      data.latitude = latitude;
      data.longitude = longitude;
      data.locationUpdatedAt = new Date();
    }

    return this.prisma.profile.update({
      where: { userId },
      data,
    });
  }

  private async ensureUserExists(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new UnauthorizedException(
        'Sesión inválida. Vuelve a iniciar sesión.',
      );
    }
  }
}
