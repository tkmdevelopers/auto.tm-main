import { ApiProperty } from '@nestjs/swagger';

export class UploadDto {
  @ApiProperty({ type: 'string' })
  uuid: any;
}

export class CreateVideo {
  @ApiProperty({ type: 'string', format: 'binary' })
  file: any;
  @ApiProperty()
  postId: string;
}

export class UpdateVideo {
  @ApiProperty({ required: false })
  postId?: string;
}

export class VideoResponse {
  @ApiProperty()
  id: number;

  @ApiProperty()
  url: string;

  @ApiProperty()
  postId: string;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  updatedAt: Date;
}
