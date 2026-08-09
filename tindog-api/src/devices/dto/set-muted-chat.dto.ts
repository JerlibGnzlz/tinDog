import { IsBoolean, IsUUID } from 'class-validator';

export class SetMutedChatDto {
  @IsUUID()
  matchId!: string;

  @IsBoolean()
  muted!: boolean;
}
