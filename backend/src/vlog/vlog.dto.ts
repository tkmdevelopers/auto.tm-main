import { ApiProperty } from "@nestjs/swagger";

export class CreateVlogDto {
  @ApiProperty()
  title: string;
  @ApiProperty({ required: false })
  description?: string;
  @ApiProperty({ required: false })
  tag?: string;
  @ApiProperty({ required: false })
  videoUrl?: string;
  @ApiProperty({ required: false, default: false })
  isActive?: boolean;
  @ApiProperty({ required: false, type: Object })
  thumbnail?: Record<string, any>;
  @ApiProperty()
  userId: string;
}

export class FindAllVlogDto {
  @ApiProperty({ required: false })
  userId?: string;

  @ApiProperty({ required: false, enum: ["Pending", "Accepted", "Declined"] })
  status?: "Pending" | "Accepted" | "Declined";

  @ApiProperty({ required: false, description: "Search by title" })
  search?: string;

  @ApiProperty({
    required: false,
    description: "Sort by column (e.g., title, createdAt)",
  })
  sortBy?: string;

  @ApiProperty({
    required: false,
    enum: ["ASC", "DESC"],
    description: "Sort direction",
  })
  sortOrder?: "ASC" | "DESC";

  @ApiProperty({
    required: false,
    description: "Page number for pagination",
    type: Number,
  })
  page?: number;

  @ApiProperty({
    required: false,
    description: "Items per page for pagination",
    type: Number,
  })
  limit?: number;
}

export class UpdateVlogDto {
  @ApiProperty({ required: false })
  title?: string;
  @ApiProperty({ required: false })
  description?: string;
  @ApiProperty({ required: false })
  tag?: string;
  @ApiProperty({ required: false })
  videoUrl?: string;
  @ApiProperty({ required: false })
  isActive?: boolean;
  @ApiProperty({ required: false, type: Object })
  thumbnail?: Record<string, any>;
}

export class FindOneVlogDto {
  @ApiProperty()
  id: string;
}

export class VlogParamDto {
  @ApiProperty()
  uuid: string;
}
