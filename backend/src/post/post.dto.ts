import { ApiProperty } from "@nestjs/swagger";

export class FindAllPosts {
  @ApiProperty({ required: false })
  status: boolean;

  @ApiProperty({ required: false })
  offset: number;

  @ApiProperty({ required: false })
  limit: number;

  @ApiProperty({
    required: false,
    description: "Whether to include brand relation",
  })
  brand: string;

  @ApiProperty({
    required: false,
    description: "Whether to include model relation",
  })
  model: string;

  @ApiProperty({ required: false })
  brandFilter: string;

  @ApiProperty({ required: false })
  modelFilter: string;

  @ApiProperty({
    required: false,
    description: "Whether to include photo relation",
  })
  photo: string;

  @ApiProperty({
    required: false,
    description: "Whether to include category relation",
  })
  category: string;

  @ApiProperty({ required: false })
  categoryFilter: string;

  @ApiProperty({
    required: false,
    description: "Whether to include subscription relation",
  })
  subscription: string;

  @ApiProperty({ required: false, enum: ["asc", "desc"] })
  sortAs: string;

  @ApiProperty({
    required: false,
    enum: ["createdAt", "price", "year", "milleage"],
  })
  sortBy: string;

  @ApiProperty({ required: false })
  search: string;

  @ApiProperty({ required: false })
  minYear: string;

  @ApiProperty({ required: false })
  maxYear: string;

  @ApiProperty({ required: false })
  minPrice: string;

  @ApiProperty({ required: false })
  maxPrice: string;

  @ApiProperty({ required: false })
  transmission: string;

  @ApiProperty({ required: false })
  engineType: string;

  @ApiProperty({ required: false })
  enginePower: number;

  @ApiProperty({ required: false })
  milleage: string;

  @ApiProperty({ required: false })
  condition: string;

  @ApiProperty({ required: false })
  region: string;

  @ApiProperty({ required: false })
  location: string;

  @ApiProperty({ required: false })
  credit: string;

  @ApiProperty({ required: false })
  exchange: string;

  @ApiProperty({ required: false })
  subFilter: string | string[];

  @ApiProperty({ required: false })
  color: string;
}
export class listPost {
  @ApiProperty()
  uuids: string[];
  @ApiProperty({ required: false })
  brand: string;
  @ApiProperty({ required: false })
  model: string;

  @ApiProperty({ required: false })
  photo: string;
}

export class FindOnePost {
  @ApiProperty({ required: false })
  brand: string;
  @ApiProperty({ required: false })
  comment: string;
  @ApiProperty({ required: false })
  model: string;
  @ApiProperty({ required: false })
  subscription: string;
  @ApiProperty({ required: false })
  photo: string;
}
export class FindOneUUID {
  @ApiProperty()
  uuid: string;
}

export class CreatePost {
  @ApiProperty({})
  brandsId: string;
  @ApiProperty()
  location: string;
  @ApiProperty()
  modelsId: string;
  @ApiProperty()
  phone: string;
  @ApiProperty()
  condition: string;
  @ApiProperty()
  transmission: string;
  @ApiProperty()
  engineType: string;
  @ApiProperty()
  enginePower: number;
  @ApiProperty()
  year: number;
  @ApiProperty()
  credit: boolean;
  @ApiProperty()
  exchange: boolean;
  @ApiProperty()
  milleage: number;
  @ApiProperty()
  vin: string;
  @ApiProperty()
  price: number;
  @ApiProperty()
  currency: string;
  @ApiProperty()
  personalInfo: { name: string; location: string; region?: string } | null;
  @ApiProperty()
  description: string;
  @ApiProperty()
  subscriptionId: string;

  @ApiProperty({ required: false })
  color: string;
}

export class UpdatePost {
  @ApiProperty()
  brandsId: string;
  @ApiProperty()
  modelsId: string;
  @ApiProperty()
  condition: string;
  @ApiProperty()
  transmission: string;
  @ApiProperty()
  engineType: string;
  @ApiProperty()
  enginePower: number;
  @ApiProperty()
  year: number;
  @ApiProperty()
  milleage: number;
  @ApiProperty()
  vin: string;
  @ApiProperty()
  credit: boolean;
  @ApiProperty()
  exchange: boolean;
  @ApiProperty()
  price: number;
  @ApiProperty()
  currency: string;
  @ApiProperty()
  personalInfo: { name: string; location: string; region?: string } | null;
  @ApiProperty()
  description: string;
  @ApiProperty()
  subscriptionId: string;
  @ApiProperty()
  status: boolean;
  @ApiProperty({ required: false })
  color: string;
}
