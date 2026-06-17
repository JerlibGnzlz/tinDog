import { IsOptional, IsString, IsUrl, MaxLength } from 'class-validator';

export class UpdatePetDto {
  @IsOptional()
  @IsString()
  @MaxLength(100)
  name?: string;

  @IsOptional()
  @IsUrl()
  photoUrl?: string;
}
