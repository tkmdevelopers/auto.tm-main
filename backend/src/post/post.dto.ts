import { ApiProperty } from '@nestjs/swagger';

export class FindAllPosts {
  @ApiProperty({ required: false })
  status: boolean;
  @ApiProperty({ required: false })
  offset: number;
  @ApiProperty({ required: false })
  limit: number;
  @ApiProperty({ required: false })
  brand: string; //True or false
  @ApiProperty({ required: false })
  model: string; // true or false
  @ApiProperty({ required: false })
  brandFilter: string;
  @ApiProperty({ required: false })
  modelFilter: string;
  @ApiProperty({ required: false })
  photo: string;
  @ApiProperty({ required: false })
  category: string;
  @ApiProperty({ required: false })
  subscription: string;
  @ApiProperty({ required: false, enum: ['asc', 'desc'] })
  sortAs: string;
  @ApiProperty({
    required: false,
    enum: ['createdAt', 'price', 'year', 'milleage'],
  })
  sortBy: string;
  @ApiProperty({ required: false })
  search: string;
  @ApiProperty({ required: false })
  location: string;
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
  subFilter: string[];
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
  personalInfo: { name: string; location: string } | null;
  @ApiProperty()
  description: string;
  @ApiProperty()
  subscriptionId: string;
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
  personalInfo: { name: string; location: string } | null;
  @ApiProperty()
  description: string;
  @ApiProperty()
  subscriptionId: string;
  @ApiProperty()
  status: boolean;
}
