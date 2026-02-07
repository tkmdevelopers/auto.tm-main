import { CanActivate, ExecutionContext } from '@nestjs/common';

export class MockRefreshGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean | Promise<boolean> | import("rxjs").Observable<boolean> {
    const request = context.switchToHttp().getRequest();
    request['uuid'] = 'mock-uuid-refresh'; // Set a mock uuid for downstream dependencies
    return true;
  }
}
