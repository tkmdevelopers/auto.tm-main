import { HttpException, HttpStatus, Inject, Injectable } from '@nestjs/common';
import { SendOtp } from './get-time.dto';
import { GetTime } from './get-time.dto';
import { User } from 'src/auth/auth.entity';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { OtpTemp } from './otp.entity';
import { ChatGateway } from 'src/chat/chat.gateway';
@Injectable()
export class OtpService {
  constructor(
    @Inject('USERS_REPOSITORY') private user: typeof User,
    @Inject('OTP_TEMP_REPOSITORY') private otp: typeof OtpTemp,
    private jwtService: JwtService,
    private configService: ConfigService,
    private chatGateway: ChatGateway,
  ) {}
  /**
   * Helper to normalize phone format. Currently ensures leading '+'.
   */
  private normalizePhone(phone: string): string {
    if (!phone) return phone;
    return phone.startsWith('+') ? phone : `+${phone}`;
  }

  // OTP generation delegated entirely to ChatGateway.issueOtp (with optional emission if socket absent).

  /**
   * sendOtp
   * If user with phone exists -> store OTP in users.otp
   * Else -> upsert into otp_temp (OtpTemp)
   * (Placeholder for actual SMS sending logic.)
   */
  async sendOtp(body: SendOtp, res: any): Promise<any> {
    const { phone } = body;
    try {
      if (!phone)
        throw new HttpException(
          'Fill `phoneNumber` field!',
          HttpStatus.BAD_REQUEST,
        );
      const formattedPhone = this.normalizePhone(phone);
      const existingUser = await this.user.findOne({ where: { phone: formattedPhone }, attributes: ['uuid', 'phone'] });
      const socketId: string | undefined = (this.chatGateway as any)?.['socketId'];
      const result = await this.chatGateway.issueOtp(socketId, formattedPhone, !!existingUser);
      return res.status(HttpStatus.OK).json({
        message: `OTP processed for ${formattedPhone}`,
        phone: result.phone,
        registered: !!existingUser,
        emitted: result.emitted,
        target: result.target,
        via: 'gateway'
      });
    } catch (error) {
      const status = error?.status || HttpStatus.INTERNAL_SERVER_ERROR;
      return res.status(status).json({ message: error?.message || 'OTP send failed' });
    }
  }
  async checkOtp(query: GetTime, res: any) {
    const { phone, otp } = query;
    try {
      const formattedPhone = this.normalizePhone(phone);
      const getInfo = await this.user.findOne({ where: { phone: formattedPhone }, attributes: ['otp', 'uuid'] });
      if (!getInfo) {
        throw new HttpException('No OTP validation', HttpStatus.NOT_FOUND);
      }
      if (otp == getInfo.otp) {
        await this.user.update({ otp: null }, { where: { phone: formattedPhone } });
        const [accessToken, refreshToken] = await Promise.all([
          this.jwtService.signAsync(
            { uuid: getInfo?.uuid, phone: formattedPhone },
            { secret: this.configService.get<string>('ACCESS_TOKEN_SECRET_KEY'), expiresIn: '24h' },
          ),
          this.jwtService.signAsync(
            { uuid: getInfo?.uuid, phone: formattedPhone },
            { secret: this.configService.get<string>('REFRESH_TOKEN_SECRET_KEY'), expiresIn: '7d' },
          ),
        ]);
        await this.user.update({ status: true, refreshToken }, { where: { phone: formattedPhone } });
        return res.status(200).json({ accessToken, refreshToken });
      } else {
        throw new HttpException('OTP password is incorrect', HttpStatus.UNAUTHORIZED);
      }
    } catch (error) {
      const status = error?.status || HttpStatus.INTERNAL_SERVER_ERROR;
      return res.status(status).json({ message: error?.message || 'OTP check failed' });
    }
  }

  async checkVerification(query: GetTime, res: any) {
    try {
      const { phone, otp } = query;
      const formattedPhone = this.normalizePhone(phone);
      // First: see if user exists; if yes, use normal user OTP flow (so frontend can call this endpoint generically)
      const existingUser = await this.user.findOne({ where: { phone: formattedPhone }, attributes: ['otp'] });
      if (existingUser) {
        if (otp == existingUser?.otp) {
          // Clear OTP after success
            await this.user.update({ otp: null }, { where: { phone: formattedPhone } });
          return res.status(HttpStatus.OK).json({ message: `OTP status success ${formattedPhone}`, response: true, registered: true });
        }
        return res.status(HttpStatus.NOT_ACCEPTABLE).json({ message: 'Incorrect OTP Code', response: false, registered: true });
      }
      // Else fallback to temp table
      const getInfo = await this.otp.findOne({ where: { phone: formattedPhone }, attributes: ['otp'] });
      if (!getInfo) {
        return res.status(HttpStatus.NOT_FOUND).json({ message: 'No OTP found', response: false });
      }
      if (otp == getInfo?.otp) {
        await this.otp.destroy({ where: { phone: formattedPhone } });
        return res.status(HttpStatus.OK).json({ message: `OTP status success ${formattedPhone}`, response: true, registered: false });
      }
      return res.status(HttpStatus.NOT_ACCEPTABLE).json({ message: 'Incorrect OTP Code', response: false, registered: false });
    } catch (error) {
      const status = error?.status || HttpStatus.INTERNAL_SERVER_ERROR;
      return res.status(status).json({ message: error?.message || 'OTP verification failed' });
    }
  }
}
