import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:auto_tm/services/auth/auth_service.dart';
import 'package:auto_tm/services/network/api_client.dart';
import 'package:auto_tm/services/token_service/token_store.dart';

import 'auth_service_test.mocks.dart';

@GenerateNiceMocks([MockSpec<Dio>(), MockSpec<FlutterSecureStorage>()])
void main() {
  late AuthService authService;
  late MockDio mockDio;
  late MockFlutterSecureStorage mockStorage;
  late TokenStore tokenStore;
  late ApiClient apiClient;

  setUp(() {
    Get.reset();
    mockDio = MockDio();
    mockStorage = MockFlutterSecureStorage();

    // Use Real Services with Injected Mocks
    tokenStore = TokenStore(storage: mockStorage);
    apiClient = ApiClient(dio: mockDio);

    // Register with GetX
    Get.put<TokenStore>(tokenStore);
    Get.put<ApiClient>(apiClient);

    authService = AuthService();
    Get.put<AuthService>(authService);
  });

  group('AuthService', () {
    const subscriber = '65000000'; // 65 00 00 00
    const fullPhone = '99365000000';

    test('sendOtp should call API and return success', () async {
      // Arrange
      when(mockDio.post(
        'otp/send',
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: 'otp/send'),
            statusCode: 200,
            data: {'status': 'ok', 'message': 'Sent'},
          ));

      // Act
      final result = await authService.sendOtp(subscriber);

      // Assert
      expect(result.success, true);
      verify(mockDio.post('otp/send', data: {'phone': fullPhone})).called(1);
    });

    test('verifyOtp should save tokens on success', () async {
      // Arrange
      const code = '12345';
      const accessToken = 'access_123';
      const refreshToken = 'refresh_456';

      when(mockDio.post(
        'otp/verify',
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: 'otp/verify'),
            statusCode: 200,
            data: {
              'status': 'ok',
              'accessToken': accessToken,
              'refreshToken': refreshToken
            },
          ));

      // Mock storage writes
      when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
          .thenAnswer((_) async => {});

      // Act
      final result = await authService.verifyOtp(subscriber, code);

      // Assert
      expect(result.success, true);
      expect(result.accessToken, accessToken);
      
      // Verify API call
      verify(mockDio.post('otp/verify', data: {
        'phone': fullPhone,
        'otp': code,
      })).called(1);

      // Verify Token Save (using the real TokenStore logic which calls mockStorage)
      verify(mockStorage.write(key: 'ACCESS_TOKEN', value: accessToken)).called(1);
      verify(mockStorage.write(key: 'REFRESH_TOKEN', value: refreshToken)).called(1);
    });

    test('logout should clear storage', () async {
      // Arrange
      when(mockDio.post('auth/logout')).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: 'auth/logout'),
            statusCode: 200,
          ));
      
      when(mockStorage.delete(key: anyNamed('key'))).thenAnswer((_) async => {});

      // Act
      await authService.logout();

      // Assert
      verify(mockDio.post('auth/logout')).called(1);
      verify(mockStorage.delete(key: 'ACCESS_TOKEN')).called(1);
      verify(mockStorage.delete(key: 'REFRESH_TOKEN')).called(1);
    });
  });
}
