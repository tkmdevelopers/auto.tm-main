import { ApiProperty } from "@nestjs/swagger";

export class SendOtp {
  @ApiProperty({ required: true })
  phone: string;
}
export class VerifyOtp {
  @ApiProperty({ required: true })
  phone: string;
  @ApiProperty({ required: true })
  password: number;
}
