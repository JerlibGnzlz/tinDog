import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { AuthModule } from './auth/auth.module';
import { ChatModule } from './chat/chat.module';
import { DevicesModule } from './devices/devices.module';
import { MediaModule } from './media/media.module';
import { MatchingModule } from './matching/matching.module';
import { PetsModule } from './pets/pets.module';
import { PrismaModule } from './prisma/prisma.module';
import { ProfilesModule } from './profiles/profiles.module';
import { SafetyModule } from './safety/safety.module';
import { UsersModule } from './users/users.module';
import { WebhooksModule } from './webhooks/webhooks.module';

const nodeEnv = process.env.NODE_ENV ?? 'development';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: [`.env.${nodeEnv}`, '.env'],
    }),
    ThrottlerModule.forRoot([
      {
        ttl: 60000,
        limit: 100,
      },
    ]),
    PrismaModule,
    AuthModule,
    UsersModule,
    ProfilesModule,
    PetsModule,
    MediaModule,
    MatchingModule,
    ChatModule,
    SafetyModule,
    DevicesModule,
    WebhooksModule,
  ],
})
export class AppModule {}
