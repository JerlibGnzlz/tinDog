import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Resend } from 'resend';

@Injectable()
export class MailService {
  private readonly logger = new Logger(MailService.name);
  private readonly resend: Resend | null;

  constructor(private readonly config: ConfigService) {
    const apiKey = this.config.get<string>('RESEND_API_KEY');
    this.resend = apiKey ? new Resend(apiKey) : null;
  }

  async sendPasswordResetCode(email: string, code: string): Promise<void> {
    const normalizedEmail = email.trim().toLowerCase();
    const nodeEnv = this.config.get<string>('NODE_ENV', 'development');
    const from = this.config.get<string>(
      'MAIL_FROM',
      'tinDog <onboarding@resend.dev>',
    );
    const ttlMinutes = this.config.get<number>(
      'PASSWORD_RESET_CODE_TTL_MINUTES',
      15,
    );

    if (
      nodeEnv === 'development' &&
      !this.shouldSendRealEmailInDev(normalizedEmail)
    ) {
      this.logDevCode(normalizedEmail, code);
      return;
    }

    const subject = 'Código para restablecer tu contraseña — tinDog';
    const html = `
      <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
        <h2 style="color: #2d6a4f;">tinDog</h2>
        <p>Recibimos una solicitud para restablecer tu contraseña.</p>
        <p style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #1b4332;">${code}</p>
        <p>Este código vence en <strong>${ttlMinutes} minutos</strong>.</p>
        <p style="color: #666; font-size: 14px;">Si no pediste esto, ignorá este correo. Tu contraseña no cambiará.</p>
      </div>
    `;
    const text = `tinDog — código para restablecer contraseña: ${code}. Vence en ${ttlMinutes} minutos. Si no pediste esto, ignorá este correo.`;

    if (!this.resend) {
      if (nodeEnv === 'development') {
        this.logDevCode(normalizedEmail, code);
        return;
      }
      this.logger.error(
        'RESEND_API_KEY no configurada; no se pudo enviar el correo de reset.',
      );
      return;
    }

    const { error } = await this.resend.emails.send({
      from,
      to: normalizedEmail,
      subject,
      html,
      text,
    });

    if (error) {
      this.logger.error(`Error enviando correo a ${normalizedEmail}: ${error.message}`);
      if (nodeEnv === 'development') {
        this.logDevCode(normalizedEmail, code);
      }
    }
  }

  private shouldSendRealEmailInDev(email: string): boolean {
    const allowed = this.config
      .get<string>('MAIL_DEV_REAL_RECIPIENT')
      ?.trim()
      .toLowerCase();
    if (!allowed) return false;
    return email === allowed;
  }

  private logDevCode(email: string, code: string): void {
    this.logger.warn(`[dev] Código de reset para ${email}: ${code}`);
  }
}
