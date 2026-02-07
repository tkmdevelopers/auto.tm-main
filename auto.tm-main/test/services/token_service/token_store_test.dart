import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:auto_tm/services/token_service/token_store.dart';

import 'token_store_test.mocks.dart';

@GenerateMocks([FlutterSecureStorage])
void main() {
  late TokenStore tokenStore;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    tokenStore = TokenStore(storage: mockStorage);
  });

  group('TokenStore', () {
    const tAccess = 'access_token_123';
    const tRefresh = 'refresh_token_456';
    const tPhone = '+99365000000';

    test('saveTokens should write access, refresh and phone to storage',
        () async {
      // Act
      await tokenStore.saveTokens(
        accessToken: tAccess,
        refreshToken: tRefresh,
        phone: tPhone,
      );

      // Assert
      verify(mockStorage.write(key: 'ACCESS_TOKEN', value: tAccess)).called(1);
      verify(mockStorage.write(key: 'REFRESH_TOKEN', value: tRefresh)).called(1);
      verify(mockStorage.write(key: 'USER_PHONE', value: tPhone)).called(1);
    });

    test('get accessToken should read from storage', () async {
      // Arrange
      when(mockStorage.read(key: 'ACCESS_TOKEN'))
          .thenAnswer((_) async => tAccess);

      // Act
      final result = await tokenStore.accessToken;

      // Assert
      expect(result, tAccess);
      verify(mockStorage.read(key: 'ACCESS_TOKEN')).called(1);
    });

    test('clearAll should delete all keys', () async {
      // Act
      await tokenStore.clearAll();

      // Assert
      verify(mockStorage.delete(key: 'ACCESS_TOKEN')).called(1);
      verify(mockStorage.delete(key: 'REFRESH_TOKEN')).called(1);
      verify(mockStorage.delete(key: 'USER_PHONE')).called(1);
    });

    test('hasTokens should return true if accessToken exists', () async {
      // Arrange
      when(mockStorage.read(key: 'ACCESS_TOKEN'))
          .thenAnswer((_) async => tAccess);

      // Act
      final result = await tokenStore.hasTokens;

      // Assert
      expect(result, true);
    });

    test('hasTokens should return false if accessToken is null', () async {
      // Arrange
      when(mockStorage.read(key: 'ACCESS_TOKEN'))
          .thenAnswer((_) async => null);

      // Act
      final result = await tokenStore.hasTokens;

      // Assert
      expect(result, false);
    });
  });
}
