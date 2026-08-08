import { Type } from 'class-transformer';
import {
  IsIn,
  IsInt,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export const DISCOVER_MODES = ['for_you', 'near', 'breed', 'play'] as const;
export type DiscoverMode = (typeof DISCOVER_MODES)[number];

export class DiscoverQueryDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number;

  /** for_you | near | breed | play */
  @IsOptional()
  @IsIn(DISCOVER_MODES)
  mode?: DiscoverMode;

  /** Filtro de raza (también se usa en modo breed). */
  @IsOptional()
  @IsString()
  @MaxLength(80)
  breed?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(40)
  minAge?: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(0)
  @Max(40)
  maxAge?: number;

  /** Radio máximo en km (modo near). Default 50. */
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(500)
  maxKm?: number;
}
