import { ApiProperty } from "@nestjs/swagger";

export class GetTime {
  @ApiProperty({ example: "99362120020" })
  phone: string;
  @ApiProperty({ example: "1111" })
  otp: string;
}
export class messageSend {
  @ApiProperty()
  uuid: string;
  @ApiProperty()
  message: string;
}
export class SendOtp {
  @ApiProperty({ example: "99362120020" })
  phone: string;
}
