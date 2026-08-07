import { Transform } from 'class-transformer';
import { IsEmail, IsString, MinLength } from 'class-validator';
import { NoCommonEmailTypo } from './no-common-email-typo';
import { normalizeEmail } from './normalize-email';

export class RegisterDto {
  @Transform(({ value }) => normalizeEmail(value))
  @IsEmail({}, { message: 'Ingresá un email válido' })
  @NoCommonEmailTypo()
  email: string;

  @IsString()
  @MinLength(8)
  password: string;
}
