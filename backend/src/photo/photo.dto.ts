import { ApiProperty } from '@nestjs/swagger';

export class UploadDto {
  @ApiProperty({ type: 'array', items: { type: 'string', format: 'binary' } })
  files: any;
  @ApiProperty({ type: 'string' })
  uuid: any;
}

export class UploadUser {
  @ApiProperty({ type: 'array', items: { type: 'string', format: 'binary' } })
  file: any;
}

export class uploadFile {
  @ApiProperty({ type: 'string', format: 'binary' })
  file: any;
  @ApiProperty({ type: 'string' })
  uuid: any;
}

export class ResponsePhoto {
  @ApiProperty()
  uuid: string;
  @ApiProperty()
  path: string;
  @ApiProperty()
  createdAt: string;
  @ApiProperty()
  updatedAt: string;
  @ApiProperty()
  categoryId: string | null;
  @ApiProperty()
  subcategoryId: string | null;
  @ApiProperty()
  bannerId: string | null;
}
export class PhotoUUID {
  @ApiProperty()
  uuid: string;
}
