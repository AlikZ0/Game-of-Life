import { ValidationPipe } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import { Logger } from 'nestjs-pino';
import { AppModule } from './app.module';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { TransformInterceptor } from './common/interceptors/transform.interceptor';

async function bootstrap() {
  const app = await NestFactory.create(AppModule, { bufferLogs: true });
  app.useLogger(app.get(Logger)); // structured JSON logging via pino
  const config = app.get(ConfigService);

  const apiPrefix = config.get<string>('app.apiPrefix', 'api/v1');
  const port = config.get<number>('app.port', 3000);
  const corsOrigins = config.get<string[]>('app.corsOrigins', ['*']);

  // Security & platform hardening
  app.use(helmet());
  app.enableCors({ origin: corsOrigins, credentials: true });
  app.setGlobalPrefix(apiPrefix, {
    exclude: ['health', 'health/ready', 'metrics'],
  });
  app.enableShutdownHooks();

  // Global validation, error handling and response envelope
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );
  app.useGlobalFilters(new HttpExceptionFilter());
  app.useGlobalInterceptors(new TransformInterceptor());

  // OpenAPI / Swagger
  const swaggerConfig = new DocumentBuilder()
    .setTitle('Life Quest API')
    .setDescription('Turn your real life into an RPG — REST + WebSocket API')
    .setVersion('1.0')
    .addBearerAuth()
    .addTag('auth')
    .addTag('character')
    .addTag('quests')
    .addTag('skills')
    .addTag('bosses')
    .addTag('achievements')
    .addTag('economy')
    .addTag('social')
    .addTag('stats')
    .addTag('monetization')
    .build();
  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('docs', app, document);

  await app.listen(port);
  // eslint-disable-next-line no-console
  console.log(`⚔️  Life Quest API listening on :${port}/${apiPrefix}`);
}

bootstrap();
