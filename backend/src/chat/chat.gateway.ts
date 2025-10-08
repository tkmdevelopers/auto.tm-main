import {
  WebSocketGateway,
  SubscribeMessage,
  MessageBody,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Op } from 'sequelize';
import { Server, Socket } from 'socket.io';
import { User } from 'src/auth/auth.entity';
import { OtpTemp } from 'src/otp/otp.entity';
import { v4 as uniq } from 'uuid';
@WebSocketGateway(3090, { cors: false, origin: '*' })
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private socketId: string;

  handleConnection(client: Socket) {
    console.log('Client connected:', client.id);
    this.socketId = client.id;
  }

  handleDisconnect(client: Socket) {
    console.log('Client disconnected:', client.id);
  }

  @SubscribeMessage('chat message')
  handleChatMessage(@MessageBody() data: any): void {
    console.log('Received message:', data);
    this.server.emit('chat message', data); // Broadcast to all clients
  }

  @SubscribeMessage('sendOtp')
  handleSendOtp(@MessageBody() data: any): void {
    console.log(data);
    this.sendGeneralMessage(data.id);
  }

  private normalizePhone(phone?: string): string | undefined {
    if (!phone) return phone;
    return phone.startsWith('+') ? phone : `+${phone}`;
  }

  private generateOtp(): number {
    return Math.floor(Math.random() * 90000) + 10000; // 5-digit
  }

  /**
   * Central OTP issuance logic.
   * registered: if true -> update User.otp; else -> upsert/create in otp_temp.
   * Accepts override for test numbers producing deterministic OTP.
   */
  async issueOtp(socketId: string | undefined, phone: string, registered: boolean): Promise<{ otp: number, phone: string, target: 'user' | 'temp', emitted: boolean }> {
    const originalPhone = phone;
    phone = this.normalizePhone(phone)!;
    // Strip non-digits for comparison so +99361999999 also matches
    const digits = (originalPhone || '').replace(/\D/g, '');
    // Deterministic test numbers configuration:
    // 1. Explicit list from env TEST_OTP_NUMBERS (comma separated digits)
    // 2. Fallback: any number starting with TEST_OTP_PREFIX (default '9936199999')
    // 3. Explicit hard-coded range extension for convenience (99361999999, 99361999991-99361999993)
    const envListRaw = process.env.TEST_OTP_NUMBERS || '';
    const envPrefix = process.env.TEST_OTP_PREFIX || '9936199999';
    const list = envListRaw
      .split(',')
      .map(s => s.trim())
      .filter(Boolean);
    const hardcodedSet = new Set<string>([
      '99361999999',
      '99361999991',
      '99361999992',
      '99361999993',
    ]);
    const isListed = list.includes(digits);
    const matchesPrefix = digits.startsWith(envPrefix);
    const isHardcoded = hardcodedSet.has(digits);
    const forceDeterministic = isListed || isHardcoded || matchesPrefix;
    let otp: number;
    if (forceDeterministic) {
      otp = 12345;
      // eslint-disable-next-line no-console
      console.debug('[OTP] Deterministic test OTP applied', { originalPhone, digits, isListed, isHardcoded, matchesPrefix });
    } else {
      otp = this.generateOtp();
    }
    if (registered) {
      await User.update({ otp }, { where: { phone } });
    } else {
      const existing = await OtpTemp.findOne({ where: { phone } });
      if (existing) {
        await OtpTemp.update({ otp }, { where: { phone } });
      } else {
        await OtpTemp.create({ phone, otp });
      }
    }
    let emitted = false;
    if (socketId) {
      try {
        this.server.to(socketId).emit('recieveOtp', { otp, phoneNumber: phone });
        emitted = true;
      } catch (e) {
        emitted = false;
      }
    }
    return { otp, phone, target: registered ? 'user' : 'temp', emitted };
  }

  async sendGeneralMessage(id: string, phone?: string): Promise<any> {
    try {
      if (!phone) return false;
  const r = await this.issueOtp(id, phone, true);
  return r;
    } catch (error) {
      return error;
    }
  }

  async sendGeneralVerification(id: string, phone?: string): Promise<any> {
    try {
      if (!phone) return false;
  const r = await this.issueOtp(id, phone, false);
  return r;
    } catch (error) {
      return error;
    }
  }
  // async sendGeneralOrderMessage(id: string, uuid?: string,message?:string ): Promise<any> {
  //   try {
  //     const sms = message;
  //     const phonesObject: any = await Orders.findOne({
  //       where: {
  //         uuid,
  //       },
  //     });
  //     let phone = phonesObject?.phone;
  //       this.server.to(id).emit('recieveOrders', { phone, sms });

  //     return true;
  //   } catch (error) {
  //     return error;
  //   }
  // }
  // async sendGeneralOrderMessageAdmin(id: string): Promise<any> {
  //   try {
  //     const sms =
  //       'Size täze sargyt bar! Admin paneli açmagyňyzy haýyş edýäris!';
  //     const phones = await Admins.findAll({
  //       where: {
  //         [Op.and]: [
  //           {
  //             uuid: {
  //               [Op.iLike]: 'admin-%',
  //             },
  //             access: {
  //               [Op.contains]: ['orders'],
  //             },
  //           },
  //         ],
  //       },
  //       attributes: ['phone'],
  //     });

  //     phones?.map(async (e) => {
  //       await this.server
  //         .to(id)
  //         .emit('recieveOrders', { phone: e?.phone, sms });
  //     });
  //     return true;
  //   } catch (error) {
  //     return error;
  //   }
  // }
  sendNotification(notification: any) {
    this.server.emit('notification', notification);
    // this.server.to(clientId).emit('notification', notification);
  }
}
