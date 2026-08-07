import { IsBoolean, IsEnum, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';
import { ReportReason } from '@prisma/client';

export class BlockUserDto {
  @IsUUID()
  userId!: string;
}

export class ReportUserDto {
  @IsUUID()
  userId!: string;

  @IsEnum(ReportReason)
  reason!: ReportReason;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  details?: string;

  @IsOptional()
  @IsUUID()
  matchId?: string;

  /** Si true, también bloquea al reportado. */
  @IsOptional()
  @IsBoolean()
  blockAlso?: boolean;
}
