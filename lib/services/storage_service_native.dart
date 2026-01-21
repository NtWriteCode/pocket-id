import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'storage_service.dart';

/// Native platform implementation (Android, iOS, Linux, Windows, macOS)
class StorageServiceImpl implements StorageService {
  static const _fileName = 'pocket_id_data.json';

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  @override
  Future<String?> read() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) {
        return null;
      }
      return await file.readAsString();
    } catch (e) {
      print('Error reading file: $e');
      return null;
    }
  }

  @override
  Future<void> write(String data) async {
    try {
      final file = await _getFile();
      await file.writeAsString(data);
    } catch (e) {
      print('Error writing file: $e');
      rethrow;
    }
  }

  @override
  Future<void> clear() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting file: $e');
      rethrow;
    }
  }
}

StorageService createStorageService() => StorageServiceImpl();
