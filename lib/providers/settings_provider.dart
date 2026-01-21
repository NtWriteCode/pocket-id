import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';

/// Provider for managing app settings (WebDAV configuration)
class SettingsProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  
  String? _webdavUrl;
  String? _webdavUsername;
  String? _webdavPassword;
  bool _encryptionEnabled = false;
  String? _encryptionPassword;
  bool _rememberEncryptionPassword = false;
  bool _isLoading = true;

  String? get webdavUrl => _webdavUrl;
  String? get webdavUsername => _webdavUsername;
  String? get webdavPassword => _webdavPassword;
  bool get encryptionEnabled => _encryptionEnabled;
  String? get encryptionPassword => _encryptionPassword;
  bool get rememberEncryptionPassword => _rememberEncryptionPassword;
  bool get isLoading => _isLoading;
  bool get isConfigured =>
      _webdavUrl != null &&
      _webdavUsername != null &&
      _webdavPassword != null &&
      _webdavUrl!.isNotEmpty &&
      _webdavUsername!.isNotEmpty &&
      _webdavPassword!.isNotEmpty;

  SettingsProvider() {
    _loadSettings();
  }

  /// Load settings from a separate storage key
  Future<void> _loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final jsonString = await _storage.read();
      if (jsonString != null && jsonString.isNotEmpty) {
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        final settings = data['settings'] as Map<String, dynamic>?;
        
        if (settings != null) {
          _webdavUrl = settings['webdavUrl'];
          _webdavUsername = settings['webdavUsername'];
          _webdavPassword = settings['webdavPassword'];
          _encryptionEnabled = settings['encryptionEnabled'] ?? false;
          _rememberEncryptionPassword = settings['rememberEncryptionPassword'] ?? false;
          if (_rememberEncryptionPassword) {
            _encryptionPassword = settings['encryptionPassword'];
          }
        }
      }
    } catch (e) {
      print('Error loading settings: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Save WebDAV configuration
  Future<void> saveWebDAVConfig({
    required String url,
    required String username,
    required String password,
  }) async {
    _webdavUrl = url;
    _webdavUsername = username;
    _webdavPassword = password;
    
    notifyListeners();
    await _saveSettings();
  }

  /// Clear WebDAV configuration
  Future<void> clearWebDAVConfig() async {
    _webdavUrl = null;
    _webdavUsername = null;
    _webdavPassword = null;
    
    notifyListeners();
    await _saveSettings();
  }

  /// Save encryption configuration
  Future<void> saveEncryptionConfig({
    required bool enabled,
    String? password,
    required bool rememberPassword,
  }) async {
    _encryptionEnabled = enabled;
    _rememberEncryptionPassword = rememberPassword;
    
    if (enabled && rememberPassword && password != null) {
      _encryptionPassword = password;
    } else {
      _encryptionPassword = null;
    }
    
    notifyListeners();
    await _saveSettings();
  }

  /// Set session encryption password (not saved to storage)
  void setSessionEncryptionPassword(String? password) {
    _encryptionPassword = password;
    notifyListeners();
  }

  /// Clear session encryption password
  void clearSessionEncryptionPassword() {
    if (!_rememberEncryptionPassword) {
      _encryptionPassword = null;
      notifyListeners();
    }
  }

  /// Save settings to storage (merged with main data)
  Future<void> _saveSettings() async {
    try {
      // Read existing data
      final jsonString = await _storage.read();
      Map<String, dynamic> data = {};
      
      if (jsonString != null && jsonString.isNotEmpty) {
        data = jsonDecode(jsonString) as Map<String, dynamic>;
      }
      
      // Add/update settings
      data['settings'] = {
        'webdavUrl': _webdavUrl,
        'webdavUsername': _webdavUsername,
        'webdavPassword': _webdavPassword,
        'encryptionEnabled': _encryptionEnabled,
        'rememberEncryptionPassword': _rememberEncryptionPassword,
        if (_rememberEncryptionPassword && _encryptionPassword != null)
          'encryptionPassword': _encryptionPassword,
      };
      
      // Save back
      await _storage.write(jsonEncode(data));
    } catch (e) {
      print('Error saving settings: $e');
      rethrow;
    }
  }
}
