import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { IsNumber, IsObject, IsOptional, IsString } from "class-validator";
import { IsInt, Min, Max, IsIn } from "sequelize-typescript";

export class findOneSubscriptions {
  @ApiProperty()
  uuid: string;
}

export class findAllSubscription {
  @ApiProperty({ required: false })
  offset?: number;

  @ApiProperty({ required: false })
  limit?: number = 10;

  @ApiProperty({ required: false })
  sortBy?: string = "createdAt";

  @ApiProperty({ required: false })
  order?: "asc" | "desc" = "asc";
}
export class CreateSubscriptionDto {
  @ApiProperty({ required: false })
  name: Record<string, string>;
  @ApiProperty()
  priority: number;
  @ApiProperty()
  price: number;

  @ApiProperty()
  color: string;

  @ApiProperty()
  description: object;
}
export class UpdateSubscriptionDto {
  @ApiPropertyOptional({ type: Object, example: { en: "Pro", ru: "Премиум" } })
  name?: Record<string, string>;

  @ApiPropertyOptional({ type: Number, example: 2 })
  priority?: number;

  @ApiPropertyOptional({ type: Number, example: 19 })
  price?: number;

  @ApiPropertyOptional({ type: String, example: "#00FF00" })
  color?: string;

  @ApiPropertyOptional({
    type: Object,
    example: { en: "Pro plan", ru: "Премиум план" },
  })
  description?: Record<string, string>;
}
export class orderSubscriptionDto {
  @ApiProperty()
  location: string;
  @ApiProperty()
  phone: string;
  @ApiProperty()
  subscriptionId: string;
}

export class getAllOrdersSubscription {
  @ApiProperty({ required: false })
  offset?: number;

  @ApiProperty({ required: false })
  limit?: number = 10;

  @ApiProperty({ required: false })
  sortBy?: string = "createdAt";

  @ApiProperty({ required: false })
  order?: "asc" | "desc" = "asc";

  @ApiProperty({ required: false })
  location: string;

  @ApiProperty({ required: false })
  status: "Pending" | "Active" | "Expired" | "Inactive" = "Pending";
}
