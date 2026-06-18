import {
  IsInt,
  IsOptional,
  IsString,
  IsUrl,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

export class UpdatePetDto {
  @IsOptional()
  @IsString()
  @MaxLength(100)
  name?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(30)
  age?: number;

  @IsOptional()
  @IsString()
  @MaxLength(80)
  color?: string;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  breed?: string;

  @IsOptional()
  @IsString()
  @MaxLength(120)
  favoriteToy?: string;

  @IsOptional()
  @IsUrl()
  photoUrl?: string;
}
