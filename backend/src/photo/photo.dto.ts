import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, IsInt, IsNumber, Min, Max, Length } from 'class-validator';

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
  @ApiPropertyOptional({ description: 'Aspect ratio category (16:9, 4:3, 1:1, etc.)' })
  aspectRatio?: string | null;
  @ApiPropertyOptional({ description: 'Image width in pixels' })
  width?: number | null;
  @ApiPropertyOptional({ description: 'Image height in pixels' })
  height?: number | null;
  @ApiPropertyOptional({ description: 'Decimal aspect ratio' })
  ratio?: number | null;
  @ApiPropertyOptional({ description: 'Image orientation (landscape, portrait, square)' })
  orientation?: string | null;
}

export class PhotoUUID {
  @ApiProperty()
  uuid: string;
}

/**
 * DTO for creating a photo with aspect ratio metadata
 */
export class CreatePhotoDto {
  @ApiProperty({ description: 'Photo UUID' })
  @IsString()
  uuid: string;

  @ApiProperty({ description: 'Photo paths (small, medium, large)' })
  path: { small: string; medium: string; large: string };

  @ApiPropertyOptional({ description: 'Original file path' })
  @IsOptional()
  @IsString()
  originalPath?: string;

  @ApiPropertyOptional({ 
    description: 'Aspect ratio category',
    enum: ['16:9', '4:3', '1:1', '9:16', '3:4', 'custom'],
    example: '16:9'
  })
  @IsOptional()
  @IsString()
  @Length(1, 20)
  aspectRatio?: string;

  @ApiPropertyOptional({ 
    description: 'Image width in pixels',
    example: 1920,
    minimum: 1,
    maximum: 10000
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(10000)
  width?: number;

  @ApiPropertyOptional({ 
    description: 'Image height in pixels',
    example: 1080,
    minimum: 1,
    maximum: 10000
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(10000)
  height?: number;

  @ApiPropertyOptional({ 
    description: 'Decimal aspect ratio (width/height)',
    example: 1.78,
    minimum: 0.1,
    maximum: 10
  })
  @IsOptional()
  @IsNumber()
  @Min(0.1)
  @Max(10)
  ratio?: number;

  @ApiPropertyOptional({ 
    description: 'Image orientation',
    enum: ['landscape', 'portrait', 'square'],
    example: 'landscape'
  })
  @IsOptional()
  @IsString()
  @Length(1, 20)
  orientation?: string;
}

/**
 * DTO for updating photo metadata
 */
export class UpdatePhotoMetadataDto {
  @ApiPropertyOptional({ 
    description: 'Aspect ratio category',
    enum: ['16:9', '4:3', '1:1', '9:16', '3:4', 'custom']
  })
  @IsOptional()
  @IsString()
  @Length(1, 20)
  aspectRatio?: string;

  @ApiPropertyOptional({ description: 'Image width in pixels' })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(10000)
  width?: number;

  @ApiPropertyOptional({ description: 'Image height in pixels' })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(10000)
  height?: number;

  @ApiPropertyOptional({ description: 'Decimal aspect ratio' })
  @IsOptional()
  @IsNumber()
  @Min(0.1)
  @Max(10)
  ratio?: number;

  @ApiPropertyOptional({ description: 'Image orientation' })
  @IsOptional()
  @IsString()
  @Length(1, 20)
  orientation?: string;
}
