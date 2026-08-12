import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

export type CreateUserInput = {
  email: string;
  passwordHash?: string | null;
  googleSub?: string | null;
  profileName?: string | null;
  avatarUrl?: string | null;
};

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  findByEmail(email: string) {
    return this.prisma.user.findUnique({ where: { email } });
  }

  findByGoogleSub(googleSub: string) {
    return this.prisma.user.findUnique({ where: { googleSub } });
  }

  create(input: CreateUserInput) {
    return this.prisma.user.create({
      data: {
        email: input.email,
        passwordHash: input.passwordHash ?? null,
        googleSub: input.googleSub ?? null,
        profile: {
          create: {
            name: input.profileName ?? undefined,
            avatarUrl: input.avatarUrl ?? undefined,
          },
        },
        pet: { create: {} },
      },
      include: { profile: true },
    });
  }

  linkGoogleSub(userId: string, googleSub: string) {
    return this.prisma.user.update({
      where: { id: userId },
      data: { googleSub },
      include: { profile: true },
    });
  }

  findById(id: string) {
    return this.prisma.user.findUnique({
      where: { id },
      include: { profile: true },
    });
  }

  /** Completa nombre/avatar del tutor si están vacíos (Google). */
  async syncTutorFromGoogle(
    userId: string,
    identity: { name?: string; picture?: string },
  ) {
    const profile = await this.prisma.profile.findUnique({
      where: { userId },
    });
    if (!profile) return;

    const data: { name?: string; avatarUrl?: string } = {};
    if (!profile.name?.trim() && identity.name?.trim()) {
      data.name = identity.name.trim();
    }
    if (!profile.avatarUrl?.trim() && identity.picture?.trim()) {
      data.avatarUrl = identity.picture.trim();
    }
    if (Object.keys(data).length === 0) return;

    await this.prisma.profile.update({
      where: { userId },
      data,
    });
  }

  async findPetName(userId: string): Promise<string | null> {
    const pet = await this.prisma.pet.findUnique({
      where: { userId },
      select: { name: true },
    });
    const name = pet?.name?.trim();
    return name ? name : null;
  }
}
