import { IsUUID } from 'class-validator';

export class TargetPetDto {
  @IsUUID()
  toPetId!: string;
}
