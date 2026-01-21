import 'storage_service.dart';

/// Stub implementation (should never be called)
class StorageServiceImpl implements StorageService {
  @override
  Future<String?> read() async {
    throw UnimplementedError('Platform not supported');
  }

  @override
  Future<void> write(String data) async {
    throw UnimplementedError('Platform not supported');
  }

  @override
  Future<void> clear() async {
    throw UnimplementedError('Platform not supported');
  }
}

StorageService createStorageService() => StorageServiceImpl();
