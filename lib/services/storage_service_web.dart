import 'package:web/web.dart' as web;
import 'storage_service.dart';

/// Web platform implementation using localStorage
class StorageServiceImpl implements StorageService {
  static const _storageKey = 'pocket_id_data';

  @override
  Future<String?> read() async {
    try {
      return web.window.localStorage.getItem(_storageKey);
    } catch (e) {
      print('Error reading localStorage: $e');
      return null;
    }
  }

  @override
  Future<void> write(String data) async {
    try {
      web.window.localStorage.setItem(_storageKey, data);
    } catch (e) {
      print('Error writing to localStorage: $e');
      rethrow;
    }
  }

  @override
  Future<void> clear() async {
    try {
      web.window.localStorage.removeItem(_storageKey);
    } catch (e) {
      print('Error clearing localStorage: $e');
      rethrow;
    }
  }
}

StorageService createStorageService() => StorageServiceImpl();
