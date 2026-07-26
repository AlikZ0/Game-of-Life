import { Module } from '@nestjs/common';
import { NotificationsService } from './application/notifications.service';
import { ReminderService } from './application/reminder.service';
import { FcmSender } from './infrastructure/fcm-sender';
import { NotificationsController } from './presentation/notifications.controller';

@Module({
  controllers: [NotificationsController],
  providers: [NotificationsService, ReminderService, FcmSender],
  exports: [NotificationsService],
})
export class NotificationsModule {}
