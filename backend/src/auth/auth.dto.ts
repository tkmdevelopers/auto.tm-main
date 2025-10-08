import { ApiProperty } from '@nestjs/swagger';

export class CreateUser {
  @ApiProperty()
  phone: string;
}
export class LoginUser {
  @ApiProperty()
  email: string;
  @ApiProperty()
  password: string;
}

export class UpdateUser {
  @ApiProperty()
  name: string;
  @ApiProperty()
  email: string;
  @ApiProperty()
  phone: string;
  @ApiProperty()
  location: string;
  @ApiProperty()
  password: string;
}
export class FindOne {
  @ApiProperty()
  uuid: string;
}
export class Update {
  @ApiProperty()
  name: string;
  @ApiProperty()
  location: string;
  @ApiProperty()
  password: string;
  @ApiProperty()
  access:string[];
  @ApiProperty()
  role:string;
}
export class DeleteOne {
  @ApiProperty()
  uuid: string;
}

export class firebaseDto {
  @ApiProperty()
  token: string;
}
