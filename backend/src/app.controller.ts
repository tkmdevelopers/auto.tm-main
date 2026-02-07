import { Controller, Get, UseGuards } from "@nestjs/common";
import { AppService } from "./app.service";
import { ApiSecurity } from "@nestjs/swagger";
import { AuthGuard } from "./guards/auth.guard";

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get()
  @ApiSecurity("token")
  @UseGuards(AuthGuard)
  getHello(): string {
    return this.appService.getHello();
  }
}
