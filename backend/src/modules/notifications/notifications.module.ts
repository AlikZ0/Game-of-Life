import { Module } from '@nestjs/common';
import { NotificationsService } from './application/notifications.service';
import { NotificationsController } from './presentation/notifications.controller';

@Module({
  controllers: [NotificationsController],
  providers: [NotificationsService],
  exports: [NotificationsService],
})
export class NotificationsModule {}
