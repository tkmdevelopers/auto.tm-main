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

    test(
      'saveTokens should write access, refresh and phone to storage',
      () async {
        // Act
        await tokenStore.saveTokens(
          accessToken: tAccess,
          refreshToken: tRefresh,
          phone: tPhone,
        );

        // Assert
        verify(
          mockStorage.write(key: 'ACCESS_TOKEN', value: tAccess),
        ).called(1);
        verify(
          mockStorage.write(key: 'REFRESH_TOKEN', value: tRefresh),
        ).called(1);
        verify(mockStorage.write(key: 'USER_PHONE', value: tPhone)).called(1);
      },
    );

    test('get accessToken should read from storage', () async {
      // Arrange
      when(
        mockStorage.read(key: 'ACCESS_TOKEN'),
      ).thenAnswer((_) async => tAccess);

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
      when(
        mockStorage.read(key: 'ACCESS_TOKEN'),
      ).thenAnswer((_) async => tAccess);

      // Act
      final result = await tokenStore.hasTokens;

      // Assert
      expect(result, true);
    });

    test('hasTokens should return false if accessToken is null', () async {
      // Arrange
      when(mockStorage.read(key: 'ACCESS_TOKEN')).thenAnswer((_) async => null);

      // Act
      final result = await tokenStore.hasTokens;

      // Assert
      expect(result, false);
    });

    test('saveTokens should set isLoggedIn to true', () async {
      // Arrange
      expect(tokenStore.isLoggedIn.value, false);

      // Act
      await tokenStore.saveTokens(
        accessToken: tAccess,
        refreshToken: tRefresh,
        phone: tPhone,
      );

      // Assert
      expect(tokenStore.isLoggedIn.value, true);
    });

    test('clearAll should set isLoggedIn to false', () async {
      // Arrange
      await tokenStore.saveTokens(accessToken: tAccess, refreshToken: tRefresh);
      expect(tokenStore.isLoggedIn.value, true);

      // Act
      await tokenStore.clearAll();

      // Assert
      expect(tokenStore.isLoggedIn.value, false);
    });

    test('init should hydrate isLoggedIn from storage', () async {
      // Arrange
      when(
        mockStorage.read(key: 'ACCESS_TOKEN'),
      ).thenAnswer((_) async => tAccess);

      // Act
      await tokenStore.init();

      // Assert
      expect(tokenStore.isLoggedIn.value, true);
    });

    test('updateAccessToken should write new access token', () async {
      // Act
      await tokenStore.updateAccessToken('new_access_token');

      // Assert
      verify(
        mockStorage.write(key: 'ACCESS_TOKEN', value: 'new_access_token'),
      ).called(1);
    });

    test('updateRefreshToken should write new refresh token', () async {
      // Act
      await tokenStore.updateRefreshToken('new_refresh_token');

      // Assert
      verify(
        mockStorage.write(key: 'REFRESH_TOKEN', value: 'new_refresh_token'),
      ).called(1);
    });
  });
}
