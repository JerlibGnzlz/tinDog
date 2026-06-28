import {
  BadRequestException,
  HttpException,
  HttpStatus,
  Injectable,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { createHmac, randomInt } from 'crypto';
import { MailService } from '../mail/mail.service';
import { PrismaService } from '../prisma/prisma.service';
import { UsersService } from '../users/users.service';
import { ForgotPasswordDto } from './dto/forgot-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';

const GENERIC_FORGOT_MESSAGE =
  'Si el email está registrado, recibirás un código para restablecer tu contraseña.';

@Injectable()
export class PasswordResetService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly usersService: UsersService,
    private readonly mailService: MailService,
    private readonly config: ConfigService,
  ) {}

  async forgotPassword(dto: ForgotPasswordDto) {
    const user = await this.usersService.findByEmail(dto.email);
    if (!user) {
      return { message: GENERIC_FORGOT_MESSAGE };
    }

    await this.enforceHourlyRequestLimit(user.id);

    const code = this.generateCode();
    const codeHash = this.hashCode(code);
    const expiresAt = this.buildExpiryDate();

    await this.prisma.$transaction([
      this.prisma.passwordResetToken.updateMany({
        where: { userId: user.id, usedAt: null },
        data: { usedAt: new Date() },
      }),
      this.prisma.passwordResetToken.create({
        data: {
          userId: user.id,
          codeHash,
          expiresAt,
        },
      }),
    ]);

    await this.mailService.sendPasswordResetCode(user.email, code);

    return { message: GENERIC_FORGOT_MESSAGE };
  }

  async resetPassword(dto: ResetPasswordDto) {
    const user = await this.usersService.findByEmail(dto.email);
    if (!user) {
      throw new BadRequestException('Código inválido o expirado');
    }

    const token = await this.prisma.passwordResetToken.findFirst({
      where: {
        userId: user.id,
        usedAt: null,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!token) {
      throw new BadRequestException('Código inválido o expirado');
    }

    const maxAttempts = this.config.get<number>(
      'PASSWORD_RESET_MAX_ATTEMPTS',
      5,
    );
    if (token.attempts >= maxAttempts) {
      throw new HttpException(
        'Demasiados intentos. Solicita un nuevo código.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    const codeHash = this.hashCode(dto.code);
    if (codeHash !== token.codeHash) {
      await this.prisma.passwordResetToken.update({
        where: { id: token.id },
        data: { attempts: { increment: 1 } },
      });
      throw new BadRequestException('Código inválido o expirado');
    }

    const passwordHash = await bcrypt.hash(dto.password, 10);
    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: user.id },
        data: { passwordHash },
      }),
      this.prisma.passwordResetToken.update({
        where: { id: token.id },
        data: { usedAt: new Date() },
      }),
      this.prisma.passwordResetToken.updateMany({
        where: { userId: user.id, usedAt: null },
        data: { usedAt: new Date() },
      }),
    ]);

    return { message: 'Contraseña actualizada correctamente' };
  }

  private generateCode(): string {
    return randomInt(100000, 1000000).toString();
  }

  private hashCode(code: string): string {
    const pepper =
      this.config.get<string>('PASSWORD_RESET_PEPPER') ??
      this.config.getOrThrow<string>('JWT_SECRET');
    return createHmac('sha256', pepper).update(code).digest('hex');
  }

  private buildExpiryDate(): Date {
    const ttlMinutes = this.config.get<number>(
      'PASSWORD_RESET_CODE_TTL_MINUTES',
      15,
    );
    return new Date(Date.now() + ttlMinutes * 60 * 1000);
  }

  private async enforceHourlyRequestLimit(userId: string) {
    const oneHourAgo = new Date(Date.now() - 60 * 60 * 1000);
    const recentCount = await this.prisma.passwordResetToken.count({
      where: {
        userId,
        createdAt: { gte: oneHourAgo },
      },
    });

    const maxPerHour = this.config.get<number>(
      'PASSWORD_RESET_MAX_REQUESTS_PER_HOUR',
      3,
    );
    if (recentCount >= maxPerHour) {
      throw new HttpException(
        'Demasiadas solicitudes. Intenta más tarde.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
  }
}
