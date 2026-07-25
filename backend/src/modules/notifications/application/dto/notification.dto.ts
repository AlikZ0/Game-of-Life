import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsString, Length } from 'class-validator';

export class RegisterTokenDto {
  @ApiProperty({ description: 'FCM device registration token' })
  @IsString()
  @Length(10, 512)
  fcmToken!: string;

  @ApiProperty({ enum: ['ios', 'android'], example: 'ios' })
  @IsIn(['ios', 'android'])
  platform!: string;
}
