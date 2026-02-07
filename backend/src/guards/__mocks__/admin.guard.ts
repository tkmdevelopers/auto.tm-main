import { CanActivate, ExecutionContext } from '@nestjs/common';

export class MockAdminGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean | Promise<boolean> | import("rxjs").Observable<boolean> {
    return true;
  }
}
