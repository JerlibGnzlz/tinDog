import { IsOptional, IsUUID, ValidateIf } from 'class-validator';

export class SetActiveChatDto {
  /** Match abierto; `null` / omitido = ya no está en un chat. */
  @IsOptional()
  @ValidateIf((_, v) => v != null && v !== '')
  @IsUUID()
  matchId?: string | null;
}
