import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
} from '@nestjs/common';
import { Request, Response } from 'express';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { MetricsService } from './metrics.service';

/**
 * Records request count + latency for every HTTP request. Uses the matched
 * route pattern (e.g. `/quests/:id/complete`) rather than the raw URL so
 * cardinality stays bounded.
 */
@Injectable()
export class MetricsInterceptor implements NestInterceptor {
  constructor(private readonly metrics: MetricsService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    if (context.getType() !== 'http') return next.handle();

    const start = process.hrtime.bigint();
    const req = context.switchToHttp().getRequest<Request>();
    const res = context.switchToHttp().getResponse<Response>();

    const record = () => {
      const route =
        (req.route?.path as string | undefined) ?? req.path ?? 'unknown';
      if (route === '/metrics') return; // don't measure the scrape endpoint
      const seconds = Number(process.hrtime.bigint() - start) / 1e9;
      this.metrics.observe(req.method, route, res.statusCode, seconds);
    };

    return next.handle().pipe(tap({ next: record, error: record }));
  }
}
