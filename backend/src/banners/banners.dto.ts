import { ApiProperty } from "@nestjs/swagger";

export class FindAllBanners {
  @ApiProperty({
    required: false,
    example: 0,
    description: "Offset",
  })
  offset: number;

  @ApiProperty({
    example: 30,
    required: false,
    description: "Limit",
  })
  limit: number;
}

export class BannerUUID {
  @ApiProperty()
  uuid: string;
}
