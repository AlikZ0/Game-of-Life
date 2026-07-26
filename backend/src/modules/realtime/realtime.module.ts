import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { AchievementRealtimeBridge } from './achievement-realtime.bridge';
import { RealtimeGateway } from './realtime.gateway';

@Module({
  imports: [JwtModule.register({})],
  providers: [RealtimeGateway, AchievementRealtimeBridge],
  exports: [RealtimeGateway],
})
export class RealtimeModule {}
