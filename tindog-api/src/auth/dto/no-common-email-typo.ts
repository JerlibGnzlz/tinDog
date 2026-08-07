import {
  ValidatorConstraint,
  ValidatorConstraintInterface,
  ValidationArguments,
  Validate,
} from 'class-validator';
import { emailTypoMessage } from './email-typo';

@ValidatorConstraint({ name: 'noCommonEmailTypo', async: false })
export class NoCommonEmailTypoConstraint
  implements ValidatorConstraintInterface
{
  validate(value: unknown): boolean {
    if (typeof value !== 'string' || !value.includes('@')) return true;
    return emailTypoMessage(value) == null;
  }

  defaultMessage(args: ValidationArguments): string {
    if (typeof args.value !== 'string') return 'Email inválido';
    return emailTypoMessage(args.value) ?? 'Email inválido';
  }
}

/** Rechaza typos conocidos (gmmail.com → gmail.com, etc.). */
export const NoCommonEmailTypo = () => Validate(NoCommonEmailTypoConstraint);
