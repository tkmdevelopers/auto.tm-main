import {
  Body,
  Controller,
  Get,
  HttpStatus,
  Param,
  Post,
  Query,
  Res,
} from '@nestjs/common';

import { ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';
import { Response } from 'express';
import { OtpService } from './otp.service';
import { GetTime, SendOtp } from './/get-time.dto';
import { ChatGateway } from 'src/chat/chat.gateway';

@Controller({
  path: 'otp',
  version: '1',
})
@ApiTags('SMS and Functions')
export class OtpController {
  constructor(
    private OtpService: OtpService,
    private readonly chatGateway: ChatGateway,
  ) {}
  @ApiResponse({
    status: HttpStatus.NOT_ACCEPTABLE,
    description: 'Fill all fields',
    schema: {
      example: {
        response: 'Fill all fields',
        status: HttpStatus.NOT_ACCEPTABLE,
        message: 'Fill all fields',
        name: 'HttpException',
      },
    },
  })
  @ApiResponse({
    status: 201,
    description: 'Ok',
    schema: {
      example: {
        token: 'string',
      },
    },
  })
  @Get('send')
  sendOtp(@Query('phone') phone: string, @Res() res: Response): any {
    if (!phone) {
      return res
        .status(HttpStatus.BAD_REQUEST)
        .json({ message: 'Invalid Phone Number' });
    }
    return this.OtpService.sendOtp({ phone } as SendOtp, res);
  }

  // @Post('sendNotification')
  // sendNotification(@Body() body: notification) {
  //   const message = body.message;
  //   const notification = { message, timestamp: new Date() };
  //   this.chatGateway.sendNotification(notification);
  // }
  // @ApiTags('SMS and Functions')
  // @Post('sendOrdersMessageClient')
  // sendOrdersMessage(@Body()body: messageSend) {
  //   this.chatGateway.sendGeneralOrderMessage(
  //     this.chatGateway['socketId'],
  //     body?.uuid,
  //     body?.message
  //   );
  // }
  // @ApiTags('SMS and Functions')
  // @Post('sendOrdersMessageAdmin')
  // sendAdminsOrdersMessage() {
  //   return this.chatGateway.sendGeneralOrderMessageAdmin(
  //     this.chatGateway['socketId'],
  //   );
  // }

  @ApiResponse({
    status: HttpStatus.NOT_ACCEPTABLE,
    description: 'No otp validation',
    schema: {
      example: {
        response: 'No otp validation',
        status: HttpStatus.NOT_ACCEPTABLE,
        message: 'No otp validation',
        name: 'HttpException',
      },
    },
  })
  @ApiResponse({
    status: HttpStatus.UNAUTHORIZED,
    description: 'Hello word',
    schema: {
      example: {
        response: 'Otp Password is Incorrect',
        status: HttpStatus.NOT_ACCEPTABLE,
        message: 'Otp Password is Incorrect',
        name: 'HttpException',
      },
    },
  })
  @Get('verify')
  getTime(@Query() query: GetTime, @Res() res: Response): Promise<any> {
    return this.OtpService.checkOtp(query, res);
  }
  @Get('sendVerification')
  sendVerification(@Query('phone') phone: string, @Res() res: Response): any {
    if (!phone) {
      return res
        .status(HttpStatus.BAD_REQUEST)
        .json({ message: 'Invalid Phone Number' });
    }
    return this.OtpService.sendOtp({ phone } as SendOtp, res);
  }
  @Get('verifyVerification')
  getVerification(@Query() query: GetTime, @Res() res: Response): Promise<any> {
    return this.OtpService.checkVerification(query, res);
  }
}
