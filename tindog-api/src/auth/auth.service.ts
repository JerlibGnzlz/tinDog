import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { UsersService } from '../users/users.service';
import { GoogleAuthDto } from './dto/google-auth.dto';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { EmailDomainService } from './email-domain.service';
import { GoogleTokenService } from './google-token.service';

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
    private readonly emailDomainService: EmailDomainService,
    private readonly googleTokenService: GoogleTokenService,
  ) {}

  async register(dto: RegisterDto) {
    await this.emailDomainService.assertDeliverableDomain(dto.email);

    const existing = await this.usersService.findByEmail(dto.email);
    if (existing) {
      throw new ConflictException('Este email ya está registrado');
    }

    const passwordHash = await bcrypt.hash(dto.password, 10);
    const user = await this.usersService.create({
      email: dto.email,
      passwordHash,
    });

    return this.buildAuthResponse(user.id, user.email);
  }

  async login(dto: LoginDto) {
    const nodeEnv = process.env.NODE_ENV ?? 'development';
    if (nodeEnv === 'development') {
      console.log('[auth/login]', {
        email: dto.email,
        passwordLength: dto.password?.length ?? 0,
      });
    }

    const user = await this.usersService.findByEmail(dto.email);
    if (!user) {
      throw new UnauthorizedException('Email o contraseña incorrectos');
    }

    if (!user.passwordHash) {
      throw new UnauthorizedException(
        'Esta cuenta usa Google. Tocá Continuar con Google.',
      );
    }

    const valid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!valid) {
      throw new UnauthorizedException('Email o contraseña incorrectos');
    }

    return this.buildAuthResponse(user.id, user.email);
  }

  async loginWithGoogle(dto: GoogleAuthDto) {
    const identity = await this.googleTokenService.verifyIdToken(dto.idToken);

    let user = await this.usersService.findByGoogleSub(identity.googleSub);
    if (user) {
      await this.usersService.syncTutorFromGoogle(user.id, identity);
      return this.buildAuthResponse(user.id, user.email);
    }

    const byEmail = await this.usersService.findByEmail(identity.email);
    if (byEmail) {
      // Misma persona: vincula Google al usuario email/password existente.
      user = await this.usersService.linkGoogleSub(
        byEmail.id,
        identity.googleSub,
      );
      await this.usersService.syncTutorFromGoogle(byEmail.id, identity);
      return this.buildAuthResponse(user.id, user.email);
    }

    await this.emailDomainService.assertDeliverableDomain(identity.email);
    user = await this.usersService.create({
      email: identity.email,
      passwordHash: null,
      googleSub: identity.googleSub,
      // Nombre y foto de Google = tutor, nunca la mascota.
      profileName: identity.name,
      avatarUrl: identity.picture,
    });

    return this.buildAuthResponse(user.id, user.email);
  }

  private async buildAuthResponse(userId: string, email: string) {
    const accessToken = this.jwtService.sign({ sub: userId, email });
    const petName = await this.usersService.findPetName(userId);
    return {
      accessToken,
      needsPetOnboarding: petName == null,
    };
  }
}
