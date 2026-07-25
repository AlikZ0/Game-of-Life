import { SetMetadata } from '@nestjs/common';

export const IS_PUBLIC_KEY = 'isPublic';

/**
 * Marks a route as accessible without a valid JWT.
 * The global JwtAuthGuard checks for this metadata and skips authentication.
 */
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);
