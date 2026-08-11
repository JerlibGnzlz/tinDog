import { IsUUID } from 'class-validator';

export class RewindDto {
  @IsUUID()
  toPetId!: string;
}
