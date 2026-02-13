import 'package:auto_tm/data/mappers/post_mapper.dart';
import 'package:auto_tm/domain/models/post.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Post Model - JSON Parsing', () {
    test('should parse complete post from JSON', () {
      final json = {
        'uuid': 'post-123',
        'brandName': 'Toyota',
        'modelName': 'Camry',
        'price': 25000,
        'year': 2022,
        'milleage': 50000,
        'engineType': 'gasoline',
        'enginePower': 200,
        'transmission': 'automatic',
        'condition': 'used',
        'currency': 'USD',
        'description': 'Well maintained vehicle',
        'location': 'Ashgabat',
        'vin': 'ABC123456789',
        'status': true,
        'personalInfo': {'phone': '+99365000000', 'region': 'Ahal'},
        'createdAt': '2026-02-08T00:00:00Z',
        'photo': [
          {
            'path': {
              'medium': '/photos/car1.jpg',
              'small': '/photos/car1_small.jpg',
            },
          },
        ],
        'exchange': true,
        'credit': false,
      };

      final post = PostMapper.fromJson(json);

      expect(post.uuid, 'post-123');
      expect(post.brand, 'Toyota');
      expect(post.model, 'Camry');
      expect(post.price, 25000.0);
      expect(post.year, 2022.0);
      expect(post.milleage, 50000.0);
      expect(post.engineType, 'gasoline');
      expect(post.enginePower, 200.0);
      expect(post.transmission, 'automatic');
      expect(post.condition, 'used');
      expect(post.currency, 'USD');
      expect(post.description, 'Well maintained vehicle');
      expect(post.location, 'Ashgabat');
      expect(post.vinCode, 'ABC123456789');
      expect(post.status, true);
      expect(post.phoneNumber, '+99365000000');
      expect(post.region, 'Ahal');
      expect(post.createdAt, '2026-02-08T00:00:00Z');
      expect(post.photoPath, '/photos/car1.jpg');
      expect(post.photoPaths.length, 1);
      expect(post.exchange, true);
      expect(post.credit, false);
    });

    test('should handle missing optional fields', () {
      final json = {
        'uuid': 'post-456',
        'brandName': 'BMW',
        'modelName': 'X5',
        'price': 45000,
        'year': 2023,
        'milleage': 0,
        'engineType': 'diesel',
        'enginePower': 300,
        'transmission': 'automatic',
        'condition': 'new',
        'currency': 'EUR',
        'description': '',
        'location': 'Mary',
        'vin': '',
        'createdAt': '2026-02-08T00:00:00Z',
      };

      final post = PostMapper.fromJson(json);

      expect(post.uuid, 'post-456');
      expect(post.brand, 'BMW');
      expect(post.status, isNull);
      expect(post.phoneNumber, '');
      expect(post.region, '');
      expect(post.photoPath, '');
      expect(post.photoPaths, isEmpty);
      expect(post.video, isNull);
      expect(post.subscription, isNull);
      expect(post.exchange, isNull);
      expect(post.credit, isNull);
    });

    test('should handle null brand/model objects', () {
      final json = {
        'uuid': 'post-789',
        'brandName': null,
        'modelName': null,
        'price': 10000,
        'year': 2020,
        'milleage': 100000,
        'engineType': '',
        'enginePower': 0,
        'transmission': '',
        'condition': '',
        'currency': 'TMT',
        'description': '',
        'location': '',
        'vin': '',
        'createdAt': '',
      };

      final post = PostMapper.fromJson(json);

      expect(post.brand, 'Unknown');
      expect(post.model, '');
    });

    test(
      'should extract brand/model from nested object if brandName missing',
      () {
        final json = {
          'uuid': 'post-101',
          'brand': {
            'uuid': 'brand-1',
            'name': 'Mercedes-Benz',
            'logo': 'mb.png',
          },
          'model': {'uuid': 'model-1', 'name': 'E-Class', 'brandId': 'brand-1'},
          'price': 55000,
          'year': 2024,
          'milleage': 5000,
          'engineType': 'hybrid',
          'enginePower': 250,
          'transmission': 'automatic',
          'condition': 'new',
          'currency': 'USD',
          'description': 'Luxury sedan',
          'location': 'Ashgabat',
          'vin': 'XYZ789',
          'createdAt': '2026-02-08T00:00:00Z',
        };

        final post = PostMapper.fromJson(json);

        expect(post.brand, 'Mercedes-Benz');
        expect(post.model, 'E-Class');
      },
    );

    test('should parse multiple photos', () {
      final json = {
        'uuid': 'post-202',
        'brandName': 'Audi',
        'modelName': 'A6',
        'price': 40000,
        'year': 2022,
        'milleage': 30000,
        'engineType': 'gasoline',
        'enginePower': 245,
        'transmission': 'automatic',
        'condition': 'used',
        'currency': 'USD',
        'description': '',
        'location': 'Lebap',
        'vin': '',
        'createdAt': '2026-02-01T00:00:00Z',
        'photo': [
          {
            'path': {'medium': '/photos/audi1.jpg'},
          },
          {
            'path': {'medium': '/photos/audi2.jpg'},
          },
          {
            'path': {'medium': '/photos/audi3.jpg'},
          },
        ],
      };

      final post = PostMapper.fromJson(json);

      expect(post.photoPaths.length, 3);
      expect(post.photoPaths[0], '/photos/audi1.jpg');
      expect(post.photoPaths[1], '/photos/audi2.jpg');
      expect(post.photoPaths[2], '/photos/audi3.jpg');
      expect(post.photoPath, '/photos/audi1.jpg'); // First photo as main
    });

    test('should parse subscription photo', () {
      final json = {
        'uuid': 'post-303',
        'brandName': 'Lexus',
        'modelName': 'RX',
        'price': 60000,
        'year': 2025,
        'milleage': 0,
        'engineType': 'hybrid',
        'enginePower': 300,
        'transmission': 'automatic',
        'condition': 'new',
        'currency': 'USD',
        'description': 'Premium SUV',
        'location': 'Ashgabat',
        'vin': '',
        'createdAt': '2026-02-08T00:00:00Z',
        'subscription': {
          'type': 'premium',
          'photo': {
            'path': {
              'small': '/premium/small.jpg',
              'medium': '/premium/medium.jpg',
            },
          },
        },
      };

      final post = PostMapper.fromJson(json);

      expect(post.subscription, '/premium/small.jpg');
    });

    test('should parse video URL', () {
      final json = {
        'uuid': 'post-404',
        'brandName': 'Tesla',
        'modelName': 'Model 3',
        'price': 50000,
        'year': 2024,
        'milleage': 1000,
        'engineType': 'electric',
        'enginePower': 400,
        'transmission': 'automatic',
        'condition': 'new',
        'currency': 'USD',
        'description': 'Electric vehicle',
        'location': 'Ashgabat',
        'vin': '',
        'createdAt': '2026-02-08T00:00:00Z',
        'video': {'publicUrl': 'https://example.com/video.mp4'},
      };

      final post = PostMapper.fromJson(json);

      expect(post.video, 'https://example.com/video.mp4');
    });

    test('should parse file data', () {
      final json = {
        'uuid': 'post-505',
        'brandName': 'Ford',
        'modelName': 'F-150',
        'price': 55000,
        'year': 2024,
        'milleage': 500,
        'engineType': 'gasoline',
        'enginePower': 400,
        'transmission': 'automatic',
        'condition': 'new',
        'currency': 'USD',
        'description': 'Pickup truck',
        'location': 'Ashgabat',
        'vin': '',
        'createdAt': '2026-02-08T00:00:00Z',
        'file': {
          'uuid': 'file-123',
          'path': '/files/document.pdf',
          'postId': 'post-505',
          'createdAt': '2026-02-08T00:00:00Z',
          'updatedAt': '2026-02-08T00:00:00Z',
        },
      };

      final post = PostMapper.fromJson(json);

      expect(post.file, isNotNull);
      expect(post.file!.uuid, 'file-123');
      expect(post.file!.path, '/files/document.pdf');
    });
  });
}
