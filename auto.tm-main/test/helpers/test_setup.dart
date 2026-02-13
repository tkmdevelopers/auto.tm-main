import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:get_storage/get_storage.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:auto_tm/global_controllers/connection_controller.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:auto_tm/services/token_service/token_store.dart';

import 'test_setup.mocks.dart';

/// Generate mocks for all commonly used dependencies.
/// Run: flutter pub run build_runner build --delete-conflicting-outputs
@GenerateNiceMocks([
  MockSpec<Dio>(),
  MockSpec<FlutterSecureStorage>(),
  MockSpec<GetStorage>(),
])
/// Fake ConnectionController for tests
class FakeConnectionController extends GetxController
    implements ConnectionController {
  @override
  var hasConnection = true.obs;
}

/// Base test configuration with all common mocks pre-configured
class TestSetup {
  late MockDio mockDio;
  late MockFlutterSecureStorage mockStorage;
  late MockGetStorage mockBox;
  late TokenStore tokenStore;
  late ApiClient apiClient;
  late FakeConnectionController connectionController;

  /// Initialize all mocks and register with GetX
  Future<void> init({
    String accessToken = 'test_access_token',
    String? refreshToken,
    bool hasConnection = true,
  }) async {
    // Reset GetX state
    Get.reset();
    Get.testMode = true;

    // Load environment
    try {
      await dotenv.load(fileName: ".env");
    } catch (_) {
      dotenv.testLoad(fileInput: "API_BASE=http://localhost:3080/");
    }

    // Create mocks
    mockDio = MockDio();
    mockStorage = MockFlutterSecureStorage();
    mockBox = MockGetStorage();
    connectionController = FakeConnectionController();
    connectionController.hasConnection.value = hasConnection;

    // Configure common Dio mock behaviors
    when(mockDio.interceptors).thenReturn(Interceptors());
    when(mockDio.options).thenReturn(BaseOptions());

    // Configure storage with tokens
    when(
      mockStorage.read(key: 'ACCESS_TOKEN'),
    ).thenAnswer((_) async => accessToken);
    when(
      mockStorage.read(key: 'REFRESH_TOKEN'),
    ).thenAnswer((_) async => refreshToken ?? 'test_refresh_token');
    when(
      mockStorage.read(key: 'USER_PHONE'),
    ).thenAnswer((_) async => '+99365000000');
    when(
      mockStorage.write(key: anyNamed('key'), value: anyNamed('value')),
    ).thenAnswer((_) async => {});
    when(mockStorage.delete(key: anyNamed('key'))).thenAnswer((_) async => {});

    // Configure GetStorage
    when(mockBox.read(any)).thenReturn(null);
    when(mockBox.write(any, any)).thenAnswer((_) async => {});

    // Create real services with injected mocks
    tokenStore = TokenStore(storage: mockStorage);
    apiClient = ApiClient(dio: mockDio);

    // Register with GetX
    Get.put<TokenStore>(tokenStore);
    Get.put<ApiClient>(apiClient);
    Get.put<ConnectionController>(connectionController);
  }

  /// Clean up GetX registrations
  void dispose() {
    Get.reset();
  }

  /// Helper to create a basic MaterialApp for widget tests
  Widget wrapWithMaterialApp(Widget child) {
    return GetMaterialApp(home: Scaffold(body: child));
  }

  /// Helper to mock a successful GET response
  void mockGet(String path, dynamic data, {int statusCode = 200}) {
    when(
      mockDio.get(path, queryParameters: anyNamed('queryParameters')),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: path),
        statusCode: statusCode,
        data: data,
      ),
    );
  }

  /// Helper to mock a successful POST response
  void mockPost(String path, dynamic data, {int statusCode = 200}) {
    when(mockDio.post(path, data: anyNamed('data'))).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: path),
        statusCode: statusCode,
        data: data,
      ),
    );
  }

  /// Helper to mock a successful DELETE response
  void mockDelete(String path, {dynamic data, int statusCode = 200}) {
    when(mockDio.delete(path)).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: path),
        statusCode: statusCode,
        data: data ?? {'status': 'ok'},
      ),
    );
  }

  /// Helper to mock a Dio error
  void mockError(String path, {int statusCode = 500, String? message}) {
    when(
      mockDio.get(path, queryParameters: anyNamed('queryParameters')),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: path),
        response: Response(
          requestOptions: RequestOptions(path: path),
          statusCode: statusCode,
          data: {'message': message ?? 'Server error'},
        ),
        type: DioExceptionType.badResponse,
      ),
    );
  }
}
