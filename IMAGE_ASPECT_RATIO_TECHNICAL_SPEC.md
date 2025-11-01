# Image Aspect Ratio - Technical Specification

## 1. Overview

### 1.1 Purpose
This document specifies the technical implementation for detecting, storing, and displaying images with various aspect ratios in the car marketplace application.

### 1.2 Scope
- Frontend: Flutter/Dart application
- Backend: NestJS/TypeScript API
- Database: PostgreSQL/MySQL with Sequelize ORM

### 1.3 Definitions
- **Aspect Ratio**: The proportional relationship between width and height (e.g., 16:9)
- **Ratio Value**: Decimal representation of aspect ratio (e.g., 1.78 for 16:9)
- **Image Metadata**: Additional information about image dimensions and characteristics

---

## 2. Data Models

### 2.1 Frontend - ImageMetadata Class

**File**: `lib/models/image_metadata.dart`

```dart
import 'dart:typed_data';
import 'package:image/image.dart' as img;

enum ImageAspectRatio {
  landscape16x9('16:9', 1.78),
  landscape4x3('4:3', 1.33),
  square1x1('1:1', 1.0),
  portrait3x4('3:4', 0.75),
  portrait9x16('9:16', 0.56),
  custom('custom', 0.0);

  final String label;
  final double value;
  const ImageAspectRatio(this.label, this.value);
}

class ImageMetadata {
  /// Original image bytes
  final Uint8List bytes;
  
  /// Original dimensions (before optimization)
  final int originalWidth;
  final int originalHeight;
  
  /// Optimized dimensions (after compression/resize)
  final int optimizedWidth;
  final int optimizedHeight;
  
  /// Aspect ratio information
  final double ratio;
  final ImageAspectRatio category;
  final String aspectRatioString;
  
  /// File size information
  final int originalSize;
  final int optimizedSize;
  
  /// Compression quality (1-100)
  final int quality;

  ImageMetadata({
    required this.bytes,
    required this.originalWidth,
    required this.originalHeight,
    required this.optimizedWidth,
    required this.optimizedHeight,
    required this.ratio,
    required this.category,
    required this.aspectRatioString,
    required this.originalSize,
    required this.optimizedSize,
    required this.quality,
  });

  /// Analyze and create metadata from raw image bytes
  static Future<ImageMetadata> fromBytes(
    Uint8List bytes, {
    int maxDimension = 2048,
    int quality = 85,
  }) async {
    // Implementation details in Phase 1
  }
  
  /// Categorize ratio into standard aspect ratio
  static ImageAspectRatio categorizeRatio(double ratio) {
    const tolerance = 0.05;
    
    for (final category in ImageAspectRatio.values) {
      if (category == ImageAspectRatio.custom) continue;
      if ((ratio - category.value).abs() < tolerance) {
        return category;
      }
    }
    
    return ImageAspectRatio.custom;
  }
  
  /// Calculate ratio from dimensions
  static double calculateRatio(int width, int height) {
    return width / height;
  }
  
  /// Get standard cache dimensions for aspect ratio
  (int, int) getCacheDimensions({required double multiplier}) {
    return (
      (optimizedWidth * multiplier).toInt(),
      (optimizedHeight * multiplier).toInt(),
    );
  }
  
  /// Convert to JSON for storage/transmission
  Map<String, dynamic> toJson() {
    return {
      'b64': base64Encode(bytes),
      'originalWidth': originalWidth,
      'originalHeight': originalHeight,
      'optimizedWidth': optimizedWidth,
      'optimizedHeight': optimizedHeight,
      'ratio': ratio,
      'aspectRatio': aspectRatioString,
      'category': category.name,
      'originalSize': originalSize,
      'optimizedSize': optimizedSize,
      'quality': quality,
    };
  }
}
```

---

### 2.2 Backend - Photo Entity Updates

**File**: `backend/src/photo/photo.entity.ts`

```typescript
import { Column, DataType } from 'sequelize-typescript';

@Table({ tableName: 'photo' })
export class Photo extends Model {
  @Column({ primaryKey: true })
  uuid: string;

  @Column({ type: DataType.JSON, allowNull: true })
  path: { small: string; medium: string; large: string } | null;
  
  @Column({ allowNull: true })
  originalPath: string;

  // NEW FIELDS
  @Column({ 
    type: DataType.STRING(20), 
    allowNull: true,
    defaultValue: '4:3',
    comment: 'Aspect ratio format (16:9, 4:3, 1:1, 9:16, custom)'
  })
  aspectRatio: string;

  @Column({ 
    type: DataType.INTEGER, 
    allowNull: true,
    comment: 'Image width in pixels'
  })
  width: number;

  @Column({ 
    type: DataType.INTEGER, 
    allowNull: true,
    comment: 'Image height in pixels'
  })
  height: number;

  @Column({ 
    type: DataType.FLOAT, 
    allowNull: true,
    comment: 'Decimal aspect ratio (width/height)'
  })
  ratio: number;

  @Column({
    type: DataType.STRING(20),
    allowNull: true,
    comment: 'Orientation: landscape, portrait, square'
  })
  orientation: string;

  // Existing fields...
}
```

---

### 2.3 Backend - Photo DTO

**File**: `backend/src/photo/photo.dto.ts`

```typescript
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsNumber, IsOptional, Min, Max } from 'class-validator';

export class CreatePhotoDto {
  @ApiProperty({ description: 'Photo file path or URL' })
  @IsString()
  path: string;

  @ApiPropertyOptional({ description: 'Aspect ratio string (16:9, 4:3, etc.)' })
  @IsOptional()
  @IsString()
  aspectRatio?: string;

  @ApiPropertyOptional({ description: 'Image width in pixels' })
  @IsOptional()
  @IsNumber()
  @Min(1)
  @Max(10000)
  width?: number;

  @ApiPropertyOptional({ description: 'Image height in pixels' })
  @IsOptional()
  @IsNumber()
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
  orientation?: 'landscape' | 'portrait' | 'square';
}

export class UpdatePhotoDto extends CreatePhotoDto {}

export class PhotoResponseDto {
  @ApiProperty()
  uuid: string;

  @ApiProperty()
  path: { small: string; medium: string; large: string } | null;

  @ApiProperty()
  originalPath: string;

  @ApiProperty()
  aspectRatio: string;

  @ApiProperty()
  width: number;

  @ApiProperty()
  height: number;

  @ApiProperty()
  ratio: number;

  @ApiProperty()
  orientation: string;
}
```

---

### 2.4 Frontend - PhotoDto Updates

**File**: `lib/screens/post_details_screen/model/post_model.dart`

```dart
class PhotoDto {
  final String uuid;
  final String? originalPath;
  final Map<String, String>? path;
  
  // NEW FIELDS
  final String? aspectRatio;
  final int? width;
  final int? height;
  final double? ratio;
  final String? orientation;

  PhotoDto({
    required this.uuid,
    this.originalPath,
    this.path,
    this.aspectRatio,
    this.width,
    this.height,
    this.ratio,
    this.orientation,
  });

  factory PhotoDto.fromJson(Map<String, dynamic> json) {
    return PhotoDto(
      uuid: json['uuid'] as String,
      originalPath: json['originalPath'] as String?,
      path: json['path'] != null 
        ? Map<String, String>.from(json['path']) 
        : null,
      aspectRatio: json['aspectRatio'] as String? ?? '4:3', // Default
      width: json['width'] as int?,
      height: json['height'] as int?,
      ratio: (json['ratio'] as num?)?.toDouble(),
      orientation: json['orientation'] as String?,
    );
  }

  /// Get optimal display dimensions for container
  (double, double) getDisplayDimensions({
    required double containerWidth,
    required double containerHeight,
  }) {
    final effectiveRatio = ratio ?? 1.33; // Default to 4:3
    
    // Calculate dimensions that fit in container while maintaining ratio
    double displayWidth = containerWidth;
    double displayHeight = displayWidth / effectiveRatio;
    
    if (displayHeight > containerHeight) {
      displayHeight = containerHeight;
      displayWidth = displayHeight * effectiveRatio;
    }
    
    return (displayWidth, displayHeight);
  }

  /// Get cache dimensions with multiplier
  (int, int) getCacheDimensions({double multiplier = 6.0}) {
    final w = width ?? 800;
    final h = height ?? 600;
    return ((w * multiplier).toInt(), (h * multiplier).toInt());
  }
}
```

---

## 3. API Specifications

### 3.1 Create Post with Image Metadata

**Endpoint**: `POST /api/post`

**Request Body**:
```json
{
  "brand": "Toyota",
  "model": "Camry",
  "year": 2024,
  "price": 25000,
  "images": [
    {
      "b64": "base64_encoded_image_data",
      "aspectRatio": "16:9",
      "width": 1920,
      "height": 1080,
      "ratio": 1.78,
      "orientation": "landscape",
      "quality": 85
    },
    {
      "b64": "base64_encoded_image_data",
      "aspectRatio": "4:3",
      "width": 1600,
      "height": 1200,
      "ratio": 1.33,
      "orientation": "landscape",
      "quality": 85
    }
  ]
}
```

**Response**:
```json
{
  "uuid": "post-uuid-123",
  "photos": [
    {
      "uuid": "photo-uuid-1",
      "originalPath": "/uploads/photos/image1.jpg",
      "path": {
        "small": "/uploads/photos/small/image1.jpg",
        "medium": "/uploads/photos/medium/image1.jpg",
        "large": "/uploads/photos/large/image1.jpg"
      },
      "aspectRatio": "16:9",
      "width": 1920,
      "height": 1080,
      "ratio": 1.78,
      "orientation": "landscape"
    }
  ]
}
```

---

### 3.2 Get Post with Photo Metadata

**Endpoint**: `GET /api/post/:uuid?photo=true`

**Response**:
```json
{
  "uuid": "post-uuid-123",
  "brand": "Toyota",
  "model": "Camry",
  "photos": [
    {
      "uuid": "photo-uuid-1",
      "originalPath": "/uploads/photos/image1.jpg",
      "aspectRatio": "16:9",
      "width": 1920,
      "height": 1080,
      "ratio": 1.78,
      "orientation": "landscape"
    }
  ]
}
```

---

## 4. Algorithms

### 4.1 Aspect Ratio Detection

```dart
/// Detect aspect ratio from image dimensions
ImageAspectRatio detectAspectRatio(int width, int height) {
  final ratio = width / height;
  const tolerance = 0.05;
  
  // Check standard ratios
  if ((ratio - 1.78).abs() < tolerance) return ImageAspectRatio.landscape16x9;
  if ((ratio - 1.33).abs() < tolerance) return ImageAspectRatio.landscape4x3;
  if ((ratio - 1.0).abs() < tolerance) return ImageAspectRatio.square1x1;
  if ((ratio - 0.75).abs() < tolerance) return ImageAspectRatio.portrait3x4;
  if ((ratio - 0.56).abs() < tolerance) return ImageAspectRatio.portrait9x16;
  
  return ImageAspectRatio.custom;
}
```

### 4.2 Image Optimization

```dart
/// Optimize image while maintaining aspect ratio
Future<Uint8List> optimizeImage({
  required Uint8List bytes,
  int maxDimension = 2048,
  int quality = 85,
}) async {
  // Decode image
  final image = img.decodeImage(bytes);
  if (image == null) throw Exception('Failed to decode image');
  
  // Calculate new dimensions maintaining aspect ratio
  int newWidth = image.width;
  int newHeight = image.height;
  
  if (newWidth > maxDimension || newHeight > maxDimension) {
    if (newWidth > newHeight) {
      newHeight = (maxDimension * newHeight / newWidth).round();
      newWidth = maxDimension;
    } else {
      newWidth = (maxDimension * newWidth / newHeight).round();
      newHeight = maxDimension;
    }
  }
  
  // Resize
  final resized = img.copyResize(
    image,
    width: newWidth,
    height: newHeight,
    interpolation: img.Interpolation.cubic,
  );
  
  // Encode with quality
  return Uint8List.fromList(img.encodeJpg(resized, quality: quality));
}
```

### 4.3 Adaptive Display Dimensions

```dart
/// Calculate optimal display dimensions for aspect ratio
(double, double) calculateDisplayDimensions({
  required String aspectRatio,
  required double containerWidth,
  required double containerHeight,
}) {
  double ratio;
  
  switch (aspectRatio) {
    case '16:9': ratio = 1.78; break;
    case '4:3': ratio = 1.33; break;
    case '1:1': ratio = 1.0; break;
    case '3:4': ratio = 0.75; break;
    case '9:16': ratio = 0.56; break;
    default: ratio = 1.33; // Default to 4:3
  }
  
  // Fit within container
  double width = containerWidth;
  double height = width / ratio;
  
  if (height > containerHeight) {
    height = containerHeight;
    width = height * ratio;
  }
  
  return (width, height);
}
```

### 4.4 Cache Key Generation

```dart
/// Generate consistent cache key including aspect ratio
String generateCacheKey({
  required String url,
  required String aspectRatio,
  required int width,
  required int height,
}) {
  // Normalize URL
  final normalizedUrl = url.replaceAll('\\', '/');
  
  // Create deterministic key
  return '${normalizedUrl}_${aspectRatio}_${width}x${height}';
}
```

---

## 5. Database Schema

### 5.1 Migration Script

**File**: `backend/migrations/YYYYMMDDHHMMSS-add-aspect-ratio-to-photos.ts`

```typescript
import { QueryInterface, DataTypes } from 'sequelize';

export async function up(queryInterface: QueryInterface): Promise<void> {
  await queryInterface.addColumn('photo', 'aspectRatio', {
    type: DataTypes.STRING(20),
    allowNull: true,
    defaultValue: '4:3',
    comment: 'Aspect ratio format (16:9, 4:3, 1:1, 9:16, custom)',
  });

  await queryInterface.addColumn('photo', 'width', {
    type: DataTypes.INTEGER,
    allowNull: true,
    comment: 'Image width in pixels',
  });

  await queryInterface.addColumn('photo', 'height', {
    type: DataTypes.INTEGER,
    allowNull: true,
    comment: 'Image height in pixels',
  });

  await queryInterface.addColumn('photo', 'ratio', {
    type: DataTypes.FLOAT,
    allowNull: true,
    comment: 'Decimal aspect ratio (width/height)',
  });

  await queryInterface.addColumn('photo', 'orientation', {
    type: DataTypes.STRING(20),
    allowNull: true,
    comment: 'Orientation: landscape, portrait, square',
  });

  // Add index for common queries
  await queryInterface.addIndex('photo', ['aspectRatio'], {
    name: 'idx_photo_aspect_ratio',
  });
}

export async function down(queryInterface: QueryInterface): Promise<void> {
  await queryInterface.removeIndex('photo', 'idx_photo_aspect_ratio');
  await queryInterface.removeColumn('photo', 'orientation');
  await queryInterface.removeColumn('photo', 'ratio');
  await queryInterface.removeColumn('photo', 'height');
  await queryInterface.removeColumn('photo', 'width');
  await queryInterface.removeColumn('photo', 'aspectRatio');
}
```

---

## 6. Performance Considerations

### 6.1 Image Processing
- Use isolates for heavy image processing (Flutter)
- Process images in background
- Show progress indicator during analysis
- Limit max concurrent processing (3-5 images)

### 6.2 Caching Strategy
- Include aspect ratio in cache key
- Separate cache pools for different ratios
- Cache dimensions: ratio-specific optimization
- Memory cache: 50-100 images
- Disk cache: 500-1000 images

### 6.3 Database Queries
- Index on `aspectRatio` for filtering
- Eager load photo metadata with posts
- Batch photo operations
- Connection pooling

---

## 7. Error Handling

### 7.1 Image Analysis Failures
```dart
try {
  final metadata = await ImageMetadata.fromBytes(bytes);
} catch (e) {
  // Fallback to default metadata
  return ImageMetadata.defaultFor(bytes);
}
```

### 7.2 Missing Metadata (Backward Compatibility)
```dart
final aspectRatio = photo.aspectRatio ?? '4:3';
final width = photo.width ?? 800;
final height = photo.height ?? 600;
final ratio = photo.ratio ?? 1.33;
```

### 7.3 Invalid Aspect Ratios
```dart
if (ratio < 0.1 || ratio > 10) {
  throw ValidationException('Invalid aspect ratio: $ratio');
}
```

---

## 8. Testing Strategy

### 8.1 Unit Tests
- Image metadata creation
- Aspect ratio detection
- Dimension calculations
- Cache key generation

### 8.2 Integration Tests
- End-to-end image upload
- API with metadata
- Database storage/retrieval
- Cache consistency

### 8.3 Performance Tests
- Image processing time
- Memory usage
- Cache hit rate
- Query performance

### 8.4 Compatibility Tests
- Old posts without metadata
- Various image formats
- Edge cases (very wide/tall images)

---

## 9. Deployment

### 9.1 Pre-Deployment
1. Backup database
2. Test migration on staging
3. Clear app cache
4. Prepare rollback plan

### 9.2 Deployment Steps
1. Deploy backend (API + migration)
2. Run migration
3. Verify migration success
4. Deploy frontend
5. Monitor errors
6. Gradual rollout

### 9.3 Post-Deployment
1. Monitor performance
2. Check error rates
3. Verify cache hit rates
4. User feedback collection

---

## 10. Maintenance

### 10.1 Monitoring
- Track aspect ratio distribution
- Monitor processing times
- Cache hit rates
- Error rates

### 10.2 Optimization Opportunities
- Adjust cache sizes based on usage
- Optimize popular ratios
- Improve detection algorithm
- Better compression

---

**Document Version**: 1.0
**Last Updated**: 2025-11-02
**Authors**: Development Team
**Status**: Approved for Implementation
