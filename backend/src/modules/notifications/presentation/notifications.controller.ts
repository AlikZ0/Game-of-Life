import { Body, Controller, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { NotificationsService } from '../application/notifications.service';
import { RegisterTokenDto } from '../application/dto/notification.dto';

@ApiTags('notifications')
@ApiBearerAuth()
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notifications: NotificationsService) {}

  @Post('token')
  @ApiOperation({ summary: 'Register a device FCM token for push notifications' })
  async registerToken(
    @CurrentUser('userId') userId: string,
    @Body() dto: RegisterTokenDto,
  ) {
    return this.notifications.registerToken(userId, dto.fcmToken, dto.platform);
  }
}
