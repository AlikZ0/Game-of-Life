import { NestFactory } from '@nestjs/core';
import { WorkerModule } from './workers/worker.module';

/**
 * Standalone process entrypoint for background job processing (BullMQ).
 * Runs the same domain modules but without the HTTP server — deployed as a
 * separate Kubernetes Deployment so gamification/notification workloads scale
 * independently of the API tier.
 */
async function bootstrapWorker() {
  const app = await NestFactory.createApplicationContext(WorkerModule, {
    bufferLogs: true,
  });
  app.enableShutdownHooks();
  // eslint-disable-next-line no-console
  console.log('🛠️  Life Quest worker started — processing queues');
}

bootstrapWorker();
