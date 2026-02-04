import { ApiProperty } from "@nestjs/swagger";

export class createCommets {
  @ApiProperty()
  message: string;
  @ApiProperty()
  postId: string;
  @ApiProperty({
    required: false,
    description: "UUID of parent comment if this is a reply",
  })
  replyTo?: string;
}

export class findAllComments {
  @ApiProperty()
  postId: string;
}
