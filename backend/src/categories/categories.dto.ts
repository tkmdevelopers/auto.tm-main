import { ApiProperty } from '@nestjs/swagger';

export class findAllCategories {
  @ApiProperty({
    required: false,
    example: 0,
    description: 'Offset',
  })
  offset: number;

  @ApiProperty({
    example: 30,
    required: false,
    description: 'Limit',
  })
  limit: number;

  @ApiProperty({
    required: false,
    description: 'Sorting By',
    enum: ['asc', 'desc'],
  })
  sort?: string;
  @ApiProperty({ required: false })
  photo: string;
  @ApiProperty({ required: false })
  post: string;
  @ApiProperty({ required: false })
  search: string;
}

export class createCategories {
  @ApiProperty({
    type: 'object',
    additionalProperties: { type: 'string' },
    example: {
      tm: 'string',
      ru: 'string',
      en: 'string',
    },
  })
  name: Record<string, string>;
  @ApiProperty()
  priority: number;
}
export class updateCategories {
  @ApiProperty({
    type: 'object',
    additionalProperties: { type: 'string' },
    example: {
      tm: 'string',
      ru: 'string',
    },
  })
  name: Record<string, string>;
  @ApiProperty()
  subcategoriesId: string[];
  @ApiProperty()
  isActive: boolean;
}
export class findOneCat {
  @ApiProperty()
  uuid: string;
}
