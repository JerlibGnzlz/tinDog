import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Injectable()
export class ProfilesService {
  constructor(private readonly prisma: PrismaService) {}

  async getByUserId(userId: string) {
    await this.ensureUserExists(userId);

    const existing = await this.prisma.profile.findUnique({
      where: { userId },
    });
    if (existing) return existing;

    return this.prisma.profile.create({ data: { userId } });
  }

  async updateByUserId(userId: string, dto: UpdateProfileDto) {
    await this.getByUserId(userId);

    return this.prisma.profile.update({
      where: { userId },
      data: dto,
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
