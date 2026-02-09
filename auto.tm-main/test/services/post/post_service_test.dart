import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:get_storage/get_storage.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:auto_tm/services/post_service.dart';
import 'package:auto_tm/models/post_dtos.dart';
import 'package:auto_tm/services/token_service/token_store.dart';

import 'post_service_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Dio>(), MockSpec<FlutterSecureStorage>(), MockSpec<GetStorage>()])
void main() {
  late PostService postService;
  late MockDio mockDio;
  late MockFlutterSecureStorage mockStorage;
  late TokenStore tokenStore;
  late ApiClient apiClient;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    Get.reset();
    Get.testMode = true;

    mockDio = MockDio();
    mockStorage = MockFlutterSecureStorage();

    // Configure Dio mock
    when(mockDio.interceptors).thenReturn(Interceptors());
    when(mockDio.options).thenReturn(BaseOptions());

    // Configure storage
    when(mockStorage.read(key: 'ACCESS_TOKEN'))
        .thenAnswer((_) async => 'test_token');
    
    // Create services
    tokenStore = TokenStore(storage: mockStorage);
    apiClient = ApiClient(dio: mockDio);

    // Register with GetX
    Get.put<TokenStore>(tokenStore);
    Get.put<ApiClient>(apiClient);

    postService = PostService(apiClient);
    Get.put<PostService>(postService);
  });

  tearDown(() {
    Get.reset();
  });

  group('PostService - fetchMyPosts', () {
    test('should return list of my posts on success', () async {
      // Arrange
      final myPostsData = [
        {
          'uuid': 'my_post_1',
          'brandName': 'Mercedes',
          'modelName': 'E-Class',
          'price': 55000.0,
          'year': 2024,
          'milleage': 10000,
          'currency': 'USD',
          'createdAt': '2026-02-05T00:00:00.000Z',
          'status': true,
        },
        {
          'uuid': 'my_post_2',
          'brandName': 'BMW',
          'modelName': 'X5',
          'price': 65000.0,
          'year': 2023,
          'milleage': 20000,
          'currency': 'USD',
          'createdAt': '2026-02-04T00:00:00.000Z',
          'status': true,
        },
      ];

      when(mockDio.get('posts/me')).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: 'posts/me'),
            statusCode: 200,
            data: myPostsData,
          ));

      // Act
      final posts = await postService.fetchMyPosts();

      // Assert
      expect(posts.length, 2);
      expect(posts[0].uuid, 'my_post_1');
      expect(posts[0].brand, 'Mercedes');
      expect(posts[1].uuid, 'my_post_2');
      expect(posts[1].brand, 'BMW');
    });

    test('should handle nested data response', () async {
      // Arrange - API returns { data: [...] } format
      final nestedData = {
        'data': [
          {
            'uuid': 'post_1',
            'brandName': 'Toyota',
            'modelName': 'Camry',
            'price': 25000.0,
            'year': 2023,
            'milleage': 50000,
            'currency': 'USD',
            'createdAt': '2026-02-01T00:00:00.000Z',
            'status': true,
          },
        ]
      };

      when(mockDio.get('posts/me')).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: 'posts/me'),
            statusCode: 200,
            data: nestedData,
          ));

      // Act
      final posts = await postService.fetchMyPosts();

      // Assert
      expect(posts.length, 1);
      expect(posts[0].uuid, 'post_1');
    });

    test('should throw Failure on 401 unauthorized', () async {
      // Arrange
      when(mockDio.get('posts/me')).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: 'posts/me'),
            statusCode: 401,
            data: {'message': 'Unauthorized'},
          ));

      // Act & Assert
      expect(
        () => postService.fetchMyPosts(),
        throwsA(isA<Failure>()),
      );
    });

    test('should throw Failure on network error', () async {
      // Arrange
      when(mockDio.get('posts/me')).thenThrow(DioException(
        requestOptions: RequestOptions(path: 'posts/me'),
        type: DioExceptionType.connectionError,
        message: 'Connection failed',
      ));

      // Act & Assert
      expect(
        () => postService.fetchMyPosts(),
        throwsA(isA<Failure>()),
      );
    });
  });

  group('PostService - deleteMyPost', () {
    test('should return true on successful deletion', () async {
      // Arrange
      const postUuid = 'post_to_delete';
      when(mockDio.delete('posts/$postUuid')).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: 'posts/$postUuid'),
            statusCode: 200,
            data: {'status': 'ok'},
          ));

      // Act
      await postService.deleteMyPost(postUuid);

      // Assert - if no exception thrown, deletion succeeded
      verify(mockDio.delete('posts/$postUuid')).called(1);
    });

    test('should throw Failure on 404 not found', () async {
      // Arrange
      const postUuid = 'nonexistent_post';
      when(mockDio.delete('posts/$postUuid')).thenThrow(DioException(
        requestOptions: RequestOptions(path: 'posts/$postUuid'),
        response: Response(
          requestOptions: RequestOptions(path: 'posts/$postUuid'),
          statusCode: 404,
          data: {'message': 'Post not found'},
        ),
        type: DioExceptionType.badResponse,
      ));

      // Act & Assert
      expect(
        () => postService.deleteMyPost(postUuid),
        throwsA(isA<Failure>()),
      );
    });
  });

  group('PostService - createPostDetails', () {
    test('should return uuid on successful post creation', () async {
      // Arrange
      final postData = {
        'brandsId': 'brand_123',
        'modelsId': 'model_456',
        'price': 25000,
        'year': 2023,
        'milleage': 50000,
        'currency': 'USD',
      };

      when(mockDio.post('posts', data: postData)).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: 'posts'),
            statusCode: 201,
            data: {'uuid': 'new_post_123'},
          ));

      // Act
      final uuid = await postService.createPostDetails(postData);

      // Assert
      expect(uuid, 'new_post_123');
    });

    test('should throw Failure on validation error', () async {
      // Arrange
      final invalidData = {'price': -100}; // Invalid data

      when(mockDio.post('posts', data: invalidData)).thenThrow(DioException(
        requestOptions: RequestOptions(path: 'posts'),
        response: Response(
          requestOptions: RequestOptions(path: 'posts'),
          statusCode: 400,
          data: {'message': 'Price must be positive'},
        ),
        type: DioExceptionType.badResponse,
      ));

      // Act & Assert
      expect(
        () => postService.createPostDetails(invalidData),
        throwsA(isA<Failure>()),
      );
    });
  });
}