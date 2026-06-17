import { Controller, Get, NotFoundException, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import type { AuthUser } from '../common/types/auth-user.type';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UsersService } from './users.service';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  async getMe(@CurrentUser() user: AuthUser) {
    const record = await this.usersService.findById(user.id);
    if (!record) {
      throw new NotFoundException('User not found');
    }

    return {
      id: record.id,
      email: record.email,
      createdAt: record.createdAt,
      profile: record.profile,
    };
  }
}
