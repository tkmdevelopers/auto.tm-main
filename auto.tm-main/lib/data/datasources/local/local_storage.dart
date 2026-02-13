import 'package:get_storage/get_storage.dart';

abstract class LocalStorage {
  T? read<T>(String key);
  Future<void> write(String key, dynamic value);
  Future<void> remove(String key);
  Future<void> clear();
}

class GetStorageImpl implements LocalStorage {
  final GetStorage _storage;

  GetStorageImpl([String container = 'GetStorage']) : _storage = GetStorage(container);

  @override
  T? read<T>(String key) => _storage.read<T>(key);

  @override
  Future<void> write(String key, dynamic value) => _storage.write(key, value);

  @override
  Future<void> remove(String key) => _storage.remove(key);

  @override
  Future<void> clear() => _storage.erase();
}
