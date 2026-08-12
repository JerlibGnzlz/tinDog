import {
  Injectable,
  Logger,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OAuth2Client, TokenPayload } from 'google-auth-library';

export type VerifiedGoogleIdentity = {
  googleSub: string;
  email: string;
  emailVerified: boolean;
  name?: string;
  picture?: string;
};

@Injectable()
export class GoogleTokenService {
  private readonly logger = new Logger(GoogleTokenService.name);
  private readonly client = new OAuth2Client();

  constructor(private readonly config: ConfigService) {}

  private audienceIds(): string[] {
    const raw = this.config.get<string>('GOOGLE_CLIENT_IDS')?.trim() ?? '';
    return raw
      .split(',')
      .map((id) => id.trim())
      .filter((id) => id.length > 0);
  }

  async verifyIdToken(idToken: string): Promise<VerifiedGoogleIdentity> {
    const audiences = this.audienceIds();
    if (audiences.length === 0) {
      this.logger.error(
        'GOOGLE_CLIENT_IDS no configurado — no se puede verificar Google Sign-In',
      );
      throw new ServiceUnavailableException(
        'Inicio con Google no está configurado en el servidor',
      );
    }

    let payload: TokenPayload | undefined;
    try {
      const ticket = await this.client.verifyIdToken({
        idToken,
        audience: audiences,
      });
      payload = ticket.getPayload();
    } catch (err) {
      this.logger.warn(
        `idToken Google inválido: ${err instanceof Error ? err.message : err}`,
      );
      throw new UnauthorizedException('Token de Google inválido');
    }

    const googleSub = payload?.sub?.trim();
    const email = payload?.email?.trim().toLowerCase();
    if (!googleSub || !email) {
      throw new UnauthorizedException('Token de Google incompleto');
    }
    if (payload?.email_verified !== true) {
      throw new UnauthorizedException('Email de Google no verificado');
    }

    return {
      googleSub,
      email,
      emailVerified: true,
      name: payload.name?.trim() || payload.given_name?.trim(),
      picture: payload.picture,
    };
  }
}
