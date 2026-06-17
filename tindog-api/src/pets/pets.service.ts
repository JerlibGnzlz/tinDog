import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdatePetDto } from './dto/update-pet.dto';

@Injectable()
export class PetsService {
  constructor(private readonly prisma: PrismaService) {}

  async getByUserId(userId: string) {
    await this.ensureUserExists(userId);

    const existing = await this.prisma.pet.findUnique({ where: { userId } });
    if (existing) return existing;

    return this.prisma.pet.create({ data: { userId } });
  }

  async updateByUserId(userId: string, dto: UpdatePetDto) {
    await this.getByUserId(userId);
    return this.prisma.pet.update({ where: { userId }, data: dto });
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
