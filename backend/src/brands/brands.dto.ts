import { ApiProperty } from "@nestjs/swagger";
export class listBrands {
  @ApiProperty()
  uuids: string[];
  @ApiProperty()
  post: boolean;
}

export class FindALlBrands {
  @ApiProperty({ required: false })
  offset: number;
  @ApiProperty({ required: false })
  limit: number;
  @ApiProperty({ required: false })
  model: string;
  @ApiProperty({ required: false })
  post: string;
  @ApiProperty({ required: false })
  location: string;
  @ApiProperty({ required: false, enum: ["asc", "desc"] })
  sortAs: string;
  @ApiProperty({ required: false })
  search: string;
}

export class CreateBrands {
  @ApiProperty()
  name: string;
  @ApiProperty({ required: false })
  location: string;
}

export class FindOneBrands {
  @ApiProperty({ required: false })
  model: string;
  @ApiProperty({ required: false })
  post: string;
}

export class BrandsUUID {
  @ApiProperty()
  uuid: string;
}
export class UpdateBrands {
  @ApiProperty()
  name: string;
  @ApiProperty({ required: false })
  location: string;
}
export class Search {
  @ApiProperty({ required: true })
  search: string;
  @ApiProperty({ required: false })
  offset: number;
  @ApiProperty({ required: false })
  limit: number;
}
