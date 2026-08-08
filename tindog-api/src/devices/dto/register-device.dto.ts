import { IsIn, IsOptional, IsString, MinLength } from 'class-validator';

export class RegisterDeviceDto {
  @IsString()
  @MinLength(10)
  token!: string;

  @IsOptional()
  @IsString()
  @IsIn(['android', 'ios', 'web'])
  platform?: string;
}
