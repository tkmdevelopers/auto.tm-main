import { ApiProperty } from '@nestjs/swagger';

export class createCommets {
  @ApiProperty()
  message: string;
  @ApiProperty()
  postId: string;
}

export class findAllComments {
  @ApiProperty()
  postId: string;
}
