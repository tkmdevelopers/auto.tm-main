import 'package:auto_tm/global_controllers/connection_controller.dart';
import 'package:auto_tm/screens/profile_screen/controller/profile_controller.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:auto_tm/services/token_service/token_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:get_storage/get_storage.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../factories/profile_factory.dart';
import 'profile_controller_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<Dio>(),
  MockSpec<FlutterSecureStorage>(),
  MockSpec<GetStorage>(),
])

class FakeConnectionController extends GetxController implements ConnectionController {
  @override
  var hasConnection = true.obs;
  @override
  void onInit() {}
  @override
  void onReady() {}
  @override
  void onClose() {}
}

void main() {
  late ProfileController controller;
  late ApiClient apiClient;
  late MockDio mockDio;
  late TokenStore tokenStore;
  late MockFlutterSecureStorage mockStorage;
  late MockGetStorage mockBox;
  late FakeConnectionController fakeConnectionController;

  setUp(() async {
    Get.reset();
    Get.testMode = true;
    try {
      await dotenv.load(fileName: ".env");
    } catch (_) {
      dotenv.testLoad(fileInput: "API_BASE=http://localhost:3080/");
    }

    mockDio = MockDio();
    mockStorage = MockFlutterSecureStorage();
    mockBox = MockGetStorage();
    fakeConnectionController = FakeConnectionController();

    tokenStore = TokenStore(storage: mockStorage);
    apiClient = ApiClient(dio: mockDio);

    when(mockDio.interceptors).thenReturn(Interceptors());
    when(mockDio.options).thenReturn(BaseOptions());

    Get.put<TokenStore>(tokenStore);
    Get.put<ApiClient>(apiClient);
    Get.put<ConnectionController>(fakeConnectionController);

    when(mockStorage.read(key: 'ACCESS_TOKEN')).thenAnswer((_) async => 'valid_token_string_long_enough');
    when(mockBox.read(any)).thenReturn(null);
    when(mockBox.write(any, any)).thenAnswer((_) async {});

    controller = ProfileController(storage: mockBox);
  });

  tearDown(() {
    Get.reset();
  });

  group('ProfileController', () {
    testWidgets('fetchProfile success should update profile state', (tester) async {
      await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));

      // Arrange
      final profileData = ProfileFactory.makeJson();
      when(mockDio.get('auth/me')).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: 'auth/me'),
            statusCode: 200,
            data: profileData,
          ));

      // Act
      // Get.put triggers onInit -> fetchProfile
      Get.put<ProfileController>(controller);
      
      // Wait for async fetch to complete (onInit is fire-and-forget)
      // We pump for a few seconds to let the future resolve and update state
      await tester.pump(const Duration(seconds: 2));

      // Assert
      expect(controller.profile.value, isNotNull);
      expect(controller.profile.value?.name, 'Test User');
      
      // Cleanup manually to cancel timer
      controller.onClose();
    });
  });
}
