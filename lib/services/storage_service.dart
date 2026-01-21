import 'storage_service_stub.dart'
    if (dart.library.io) 'storage_service_native.dart'
    if (dart.library.html) 'storage_service_web.dart';

/// Abstract storage service interface
abstract class StorageService {
  /// Factory that returns platform-specific implementation
  factory StorageService() => createStorageService();

  /// Read the JSON data from storage
  Future<String?> read();

  /// Write JSON data to storage
  Future<void> write(String data);

  /// Delete all data
  Future<void> clear();
}
