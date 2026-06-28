import { IsInt, IsOptional, IsString, IsUrl, Max, MaxLength, Min } from 'class-validator';

export class AddPetVideoDto {
  @IsUrl()
  url: string;

  @IsString()
  @MaxLength(255)
  publicId: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(60)
  durationSec?: number;
}
