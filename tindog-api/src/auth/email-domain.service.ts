import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import { promises as dns } from 'dns';
import type { MxRecord } from 'dns';

/**
 * Valida que el dominio del email pueda recibir correo (registros MX).
 * Complementa typos conocidos: dominios inventados sin MX se rechazan.
 */
@Injectable()
export class EmailDomainService {
  private readonly logger = new Logger(EmailDomainService.name);

  async assertDeliverableDomain(email: string): Promise<void> {
    const domain = email.split('@')[1]?.trim().toLowerCase();
    if (!domain || !domain.includes('.')) {
      throw new BadRequestException('Ingresá un email válido');
    }

    try {
      const records = await this.resolveMxWithTimeout(domain, 2500);
      if (!records.length) {
        throw new BadRequestException(
          'Este dominio de email no puede recibir correo. Revisá que esté bien escrito.',
        );
      }
    } catch (err) {
      if (err instanceof BadRequestException) throw err;

      const code =
        err && typeof err === 'object' && 'code' in err
          ? String((err as { code?: string }).code)
          : '';

      if (
        code === 'ENOTFOUND' ||
        code === 'ENODATA' ||
        code === 'ESERVFAIL' ||
        code === 'ETIMEOUT'
      ) {
        throw new BadRequestException(
          'Este dominio de email no existe o no puede recibir correo. Revisá que esté bien escrito.',
        );
      }

      // Errores transitorios: no bloquear el registro por un DNS inestable.
      this.logger.warn(
        `MX check omitido para ${domain}: ${
          err instanceof Error ? err.message : err
        }`,
      );
    }
  }

  private async resolveMxWithTimeout(
    domain: string,
    ms: number,
  ): Promise<MxRecord[]> {
    let timer: NodeJS.Timeout | undefined;
    try {
      return await Promise.race([
        dns.resolveMx(domain),
        new Promise<never>((_, reject) => {
          timer = setTimeout(() => {
            const e = new Error('DNS MX timeout') as Error & { code: string };
            e.code = 'ETIMEOUT';
            reject(e);
          }, ms);
        }),
      ]);
    } finally {
      if (timer) clearTimeout(timer);
    }
  }
}
