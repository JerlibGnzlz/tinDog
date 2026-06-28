import { IsString, IsUrl, MaxLength } from 'class-validator';

export class AddPetMediaDto {
  @IsUrl()
  url: string;

  @IsString()
  @MaxLength(255)
  publicId: string;
}
