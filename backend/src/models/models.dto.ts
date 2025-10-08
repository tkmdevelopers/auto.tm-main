import { ApiProperty } from '@nestjs/swagger';

export class FindAllModels {
  @ApiProperty({ required: false })
  offset: number;

  @ApiProperty({ required: false })
  limit: number;
  @ApiProperty({ required: false })
  brand: string;
  @ApiProperty({ required: false })
  post: string;
  @ApiProperty({ required: false, enum: ['asc', 'desc'] })
  sortAs: string;
  @ApiProperty({ required: false })
  search: string;
  @ApiProperty({ required: false })
  filter: string;
}

export class CreateModels {
  @ApiProperty()
  name: string;
  @ApiProperty()
  brandId: string;
}

export class findOneModel {
  @ApiProperty({ required: false })
  brand: string;
  @ApiProperty({ required: false })
  post: string;
}

export class ModelUUID {
  @ApiProperty()
  uuid: string;
}
export class updateModel {
  @ApiProperty()
  name: string;
  @ApiProperty()
  brandId: string;
}
