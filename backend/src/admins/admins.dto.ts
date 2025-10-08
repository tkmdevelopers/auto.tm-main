import { ApiProperty } from '@nestjs/swagger';

export class FindOne {
  @ApiProperty()
  uuid: string;
}
export class updateAdmin {
  @ApiProperty()
  name: string;
  @ApiProperty()
  email: string;
  @ApiProperty()
  phone: string;
  @ApiProperty()
  access: string[];
  @ApiProperty()
  password: string;
  @ApiProperty()
  status: boolean;
}
