import 'package:auto_tm/screens/post_details_screen/model/post_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Post Model - JSON Parsing', () {
    test('should parse complete post from JSON', () {
      final json = {
        'uuid': 'post-123',
        'brand': {'name': 'Toyota'},
        'model': {'name': 'Camry'},
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
          {'path': {'medium': '/photos/car1.jpg', 'small': '/photos/car1_small.jpg'}}
        ],
        'exchange': true,
        'credit': false,
      };

      final post = Post.fromJson(json);

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
        'brand': {'name': 'BMW'},
        'model': {'name': 'X5'},
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

      final post = Post.fromJson(json);

      expect(post.uuid, 'post-456');
      expect(post.brand, 'BMW');
      expect(post.status, isNull);
      expect(post.phoneNumber, '');
      expect(post.region, '');
      expect(post.photoPath, '');
      expect(post.photoPaths, isEmpty);
      expect(post.video, '');
      expect(post.subscription, isNull);
      expect(post.exchange, isNull);
      expect(post.credit, isNull);
    });

    test('should handle null brand/model objects', () {
      final json = {
        'uuid': 'post-789',
        'brand': null,
        'model': null,
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

      final post = Post.fromJson(json);

      expect(post.brand, '');
      expect(post.model, '');
    });

    test('should extract brand/model from nested name field', () {
      final json = {
        'uuid': 'post-101',
        'brand': {'uuid': 'brand-1', 'name': 'Mercedes-Benz', 'logo': 'mb.png'},
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

      final post = Post.fromJson(json);

      expect(post.brand, 'Mercedes-Benz');
      expect(post.model, 'E-Class');
    });

    test('should parse multiple photos', () {
      final json = {
        'uuid': 'post-202',
        'brand': {'name': 'Audi'},
        'model': {'name': 'A6'},
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
          {'path': {'medium': '/photos/audi1.jpg'}},
          {'path': {'medium': '/photos/audi2.jpg'}},
          {'path': {'medium': '/photos/audi3.jpg'}},
        ],
      };

      final post = Post.fromJson(json);

      expect(post.photoPaths.length, 3);
      expect(post.photoPaths[0], '/photos/audi1.jpg');
      expect(post.photoPaths[1], '/photos/audi2.jpg');
      expect(post.photoPaths[2], '/photos/audi3.jpg');
      expect(post.photoPath, '/photos/audi1.jpg'); // First photo as main
    });

    test('should parse subscription photo', () {
      final json = {
        'uuid': 'post-303',
        'brand': {'name': 'Lexus'},
        'model': {'name': 'RX'},
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
            'path': {'small': '/premium/small.jpg', 'medium': '/premium/medium.jpg'}
          }
        },
      };

      final post = Post.fromJson(json);

      expect(post.subscription, '/premium/small.jpg');
    });

    test('should parse video URL', () {
      final json = {
        'uuid': 'post-404',
        'brand': {'name': 'Tesla'},
        'model': {'name': 'Model 3'},
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
        'video': {
          'publicUrl': 'https://example.com/video.mp4',
        },
      };

      final post = Post.fromJson(json);

      expect(post.video, 'https://example.com/video.mp4');
    });

    test('should parse file data', () {
      final json = {
        'uuid': 'post-505',
        'brand': {'name': 'Ford'},
        'model': {'name': 'F-150'},
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

      final post = Post.fromJson(json);

      expect(post.file, isNotNull);
      expect(post.file!.uuid, 'file-123');
      expect(post.file!.path, '/files/document.pdf');
    });

    test('should handle personalInfo region fallback to location', () {
      final json = {
        'uuid': 'post-606',
        'brand': {'name': 'Honda'},
        'model': {'name': 'Civic'},
        'price': 25000,
        'year': 2022,
        'milleage': 20000,
        'engineType': 'gasoline',
        'enginePower': 158,
        'transmission': 'automatic',
        'condition': 'used',
        'currency': 'USD',
        'description': '',
        'location': 'Dashoguz',
        'vin': '',
        'createdAt': '2026-02-08T00:00:00Z',
        'personalInfo': {
          'phone': '+99365111111',
          'location': 'Dashoguz City', // no 'region', should fallback to 'location'
        },
      };

      final post = Post.fromJson(json);

      expect(post.region, 'Dashoguz City');
      expect(post.phoneNumber, '+99365111111');
    });
  });

  group('Video Model - JSON Parsing', () {
    test('should parse video from JSON', () {
      final json = {
        'id': 1,
        'url': ['https://example.com/video1.mp4', 'https://example.com/video2.mp4'],
        'partNumber': 1,
        'postId': 'post-123',
        'createdAt': '2026-02-08T00:00:00Z',
        'updatedAt': '2026-02-08T00:00:00Z',
      };

      final video = Video.fromJson(json);

      expect(video.id, 1);
      expect(video.url?.length, 2);
      expect(video.partNumber, 1);
      expect(video.postId, 'post-123');
    });

    test('should convert video to JSON', () {
      final video = Video(
        id: 2,
        url: ['video.mp4'],
        partNumber: 1,
        postId: 'post-456',
        createdAt: '2026-02-08T00:00:00Z',
        updatedAt: '2026-02-08T00:00:00Z',
      );

      final json = video.toJson();

      expect(json['id'], 2);
      expect(json['url'], ['video.mp4']);
      expect(json['postId'], 'post-456');
    });
  });

  group('FileData Model - JSON Parsing', () {
    test('should parse file data from JSON', () {
      final json = {
        'uuid': 'file-abc',
        'path': '/uploads/document.pdf',
        'postId': 'post-123',
        'createdAt': '2026-02-08T00:00:00Z',
        'updatedAt': '2026-02-08T00:00:00Z',
      };

      final file = FileData.fromJson(json);

      expect(file.uuid, 'file-abc');
      expect(file.path, '/uploads/document.pdf');
      expect(file.postId, 'post-123');
    });

    test('should handle missing file data fields', () {
      final json = <String, dynamic>{};

      final file = FileData.fromJson(json);

      expect(file.uuid, '');
      expect(file.path, '');
      expect(file.postId, '');
    });
  });
}
