import { Transform } from 'class-transformer';
import {
  IsEnum,
  IsInt,
  IsOptional,
  IsString,
  IsUrl,
  Max,
  MaxLength,
  Min,
  ValidateIf,
} from 'class-validator';
import { ChatMessageType } from '@prisma/client';

export class SendMessageDto {
  @IsOptional()
  @IsEnum(ChatMessageType)
  type?: ChatMessageType;

  /** Texto o caption opcional en imagen/video. */
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  body?: string;

  @ValidateIf(
    (o: SendMessageDto) =>
      o.type === ChatMessageType.image || o.type === ChatMessageType.video,
  )
  @IsUrl()
  mediaUrl?: string;

  @IsOptional()
  @IsString()
  @MaxLength(255)
  mediaPublicId?: string;

  @IsOptional()
  @IsUrl()
  thumbnailUrl?: string;

  @IsOptional()
  @Transform(({ value }) => (value === null ? undefined : value))
  @IsInt()
  @Min(1)
  @Max(600)
  durationSec?: number;
}
