import { Body, Controller, Get, Patch, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { CharacterService } from '../application/character.service';
import {
  CharacterResponseDto,
  CreateCharacterDto,
  UpdateCharacterDto,
} from '../application/dto/character.dto';

@ApiTags('character')
@ApiBearerAuth()
@Controller('characters')
export class CharacterController {
  constructor(private readonly characters: CharacterService) {}

  @Post()
  @ApiOperation({ summary: 'Create the authenticated user’s character' })
  create(
    @CurrentUser('userId') userId: string,
    @Body() dto: CreateCharacterDto,
  ): Promise<CharacterResponseDto> {
    return this.characters.create(userId, dto);
  }

  @Get('me')
  @ApiOperation({ summary: 'Get the authenticated user’s character' })
  me(@CurrentUser('userId') userId: string): Promise<CharacterResponseDto> {
    return this.characters.getByUserId(userId);
  }

  @Patch('me')
  @ApiOperation({ summary: 'Update character name / avatar / active title' })
  update(
    @CurrentUser('userId') userId: string,
    @Body() dto: UpdateCharacterDto,
  ): Promise<CharacterResponseDto> {
    return this.characters.update(userId, dto);
  }
}
