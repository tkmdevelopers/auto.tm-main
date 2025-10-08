import { ApiProperty } from '@nestjs/swagger';

export class CreateFile {
  @ApiProperty({ type: 'string', format: 'binary' })
  file: any;
  @ApiProperty()
  postId: string;
}

export class UpdateFile {
  @ApiProperty({ required: false })
  postId?: string;
}

export class FileResponse {
  @ApiProperty()
  uuid: string;

  @ApiProperty()
  path: string;

  @ApiProperty()
  postId: string;

  @ApiProperty()
  createdAt: Date;

  @ApiProperty()
  updatedAt: Date;
}
