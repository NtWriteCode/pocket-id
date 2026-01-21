import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

/// Service for encrypting and decrypting data with AES-256-GCM
class EncryptionService {
  static const int _pbkdf2Iterations = 100000;
  static const int _saltLength = 32;
  static const int _keyLength = 32; // 256 bits

  /// Encrypts JSON string with password
  /// Returns encrypted data with metadata as JSON string
  Future<String> encrypt(String jsonData, String password) async {
    try {
      // Generate random salt
      final salt = _generateRandomBytes(_saltLength);
      
      // Derive key from password using PBKDF2
      final algorithm = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: _pbkdf2Iterations,
        bits: _keyLength * 8,
      );
      
      final secretKey = await algorithm.deriveKey(
        secretKey: SecretKey(utf8.encode(password)),
        nonce: salt,
      );
      
      // Encrypt data with AES-256-GCM
      final aesGcm = AesGcm.with256bits();
      final secretBox = await aesGcm.encrypt(
        utf8.encode(jsonData),
        secretKey: secretKey,
      );
      
      // Build encrypted payload
      final encryptedPayload = {
        'version': 1,
        'encrypted': true,
        'algorithm': 'AES-256-GCM',
        'kdf': 'PBKDF2-HMAC-SHA256',
        'iterations': _pbkdf2Iterations,
        'salt': base64Encode(salt),
        'nonce': base64Encode(secretBox.nonce),
        'data': base64Encode(secretBox.cipherText),
        'mac': base64Encode(secretBox.mac.bytes),
      };
      
      return jsonEncode(encryptedPayload);
    } catch (e) {
      throw EncryptionException('Encryption failed: $e');
    }
  }

  /// Decrypts encrypted JSON string with password
  /// Returns decrypted JSON string
  Future<String> decrypt(String encryptedJson, String password) async {
    try {
      final payload = jsonDecode(encryptedJson) as Map<String, dynamic>;
      
      // Check if data is encrypted
      if (payload['encrypted'] != true) {
        throw EncryptionException('Data is not encrypted');
      }
      
      // Validate version
      if (payload['version'] != 1) {
        throw EncryptionException('Unsupported encryption version');
      }
      
      // Extract encrypted data
      final salt = base64Decode(payload['salt']);
      final nonce = base64Decode(payload['nonce']);
      final cipherText = base64Decode(payload['data']);
      final mac = base64Decode(payload['mac']);
      final iterations = payload['iterations'] as int;
      
      // Derive key from password using same parameters
      final algorithm = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: iterations,
        bits: _keyLength * 8,
      );
      
      final secretKey = await algorithm.deriveKey(
        secretKey: SecretKey(utf8.encode(password)),
        nonce: salt,
      );
      
      // Decrypt data
      final aesGcm = AesGcm.with256bits();
      final secretBox = SecretBox(
        cipherText,
        nonce: nonce,
        mac: Mac(mac),
      );
      
      final decryptedBytes = await aesGcm.decrypt(
        secretBox,
        secretKey: secretKey,
      );
      
      return utf8.decode(decryptedBytes);
    } on SecretBoxAuthenticationError {
      throw EncryptionException('Wrong password or corrupted data');
    } catch (e) {
      if (e is EncryptionException) rethrow;
      throw EncryptionException('Decryption failed: $e');
    }
  }

  /// Checks if a JSON string is encrypted
  bool isEncrypted(String jsonData) {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      return data['encrypted'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Generates random bytes for salt/nonce
  Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (i) => random.nextInt(256))
    );
  }
}

/// Exception thrown when encryption/decryption fails
class EncryptionException implements Exception {
  final String message;
  
  EncryptionException(this.message);
  
  @override
  String toString() => message;
}
