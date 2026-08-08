import { Transform } from 'class-transformer';
import { IsEmail } from 'class-validator';
import { NoCommonEmailTypo } from './no-common-email-typo';
import { normalizeEmail } from './normalize-email';

export class ForgotPasswordDto {
  @Transform(({ value }) => normalizeEmail(value))
  @IsEmail({}, { message: 'Ingresá un email válido' })
  @NoCommonEmailTypo()
  email: string;
}
