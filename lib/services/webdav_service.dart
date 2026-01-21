import 'dart:typed_data';
import 'package:webdav_client/webdav_client.dart';

/// Service for WebDAV backup and restore operations
class WebDAVService {
  static const _appFolder = 'pocket-id';
  static const _backupFileName = 'pocket_id_backup.json';
  static const _backupFilePath = '$_appFolder/$_backupFileName';

  String? url;
  String? username;
  String? password;

  WebDAVService({
    this.url,
    this.username,
    this.password,
  });

  /// Ensures the pocket-id folder exists on the WebDAV server
  Future<void> _ensureFolderExists(Client client) async {
    try {
      // Try to list the folder
      await client.readDir('/$_appFolder');
    } catch (e) {
      // Folder doesn't exist, create it
      try {
        await client.mkdir('/$_appFolder');
      } catch (mkdirError) {
        print('Error creating folder: $mkdirError');
        // Ignore if folder already exists (race condition)
      }
    }
  }

  /// Test connection to WebDAV server
  Future<bool> testConnection() async {
    if (url == null || username == null || password == null) {
      throw Exception('WebDAV credentials not configured');
    }

    try {
      final client = newClient(
        url!,
        user: username!,
        password: password!,
      );

      // Try to list files to test connection
      await client.readDir('/');
      
      // Ensure our app folder exists
      await _ensureFolderExists(client);
      
      return true;
    } catch (e) {
      print('WebDAV connection test failed: $e');
      return false;
    }
  }

  /// Upload backup to WebDAV server
  Future<void> uploadBackup(String jsonData) async {
    if (url == null || username == null || password == null) {
      throw Exception('WebDAV credentials not configured');
    }

    try {
      final client = newClient(
        url!,
        user: username!,
        password: password!,
      );

      // Ensure the pocket-id folder exists
      await _ensureFolderExists(client);

      // Upload the file to pocket-id folder
      await client.write(_backupFilePath, Uint8List.fromList(jsonData.codeUnits));
    } catch (e) {
      print('WebDAV upload failed: $e');
      rethrow;
    }
  }

  /// Download backup from WebDAV server
  Future<String> downloadBackup() async {
    if (url == null || username == null || password == null) {
      throw Exception('WebDAV credentials not configured');
    }

    try {
      final client = newClient(
        url!,
        user: username!,
        password: password!,
      );

      // Download the file from pocket-id folder
      final bytes = await client.read(_backupFilePath);
      return String.fromCharCodes(bytes);
    } catch (e) {
      print('WebDAV download failed: $e');
      rethrow;
    }
  }
}
