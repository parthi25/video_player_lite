import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VaultVideo {
  final String id;
  final String originalPath;
  final String hiddenPath;
  final String fileName;
  final int fileSize;
  final DateTime hiddenDate;
  final String thumbnail;
  final String encryptionKey;
  final String checksum;
  final bool isEncrypted;

  VaultVideo({
    required this.id,
    required this.originalPath,
    required this.hiddenPath,
    required this.fileName,
    required this.fileSize,
    required this.hiddenDate,
    required this.thumbnail,
    required this.encryptionKey,
    required this.checksum,
    this.isEncrypted = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalPath': originalPath,
      'hiddenPath': hiddenPath,
      'fileName': fileName,
      'fileSize': fileSize,
      'hiddenDate': hiddenDate.toIso8601String(),
      'thumbnail': thumbnail,
      'encryptionKey': encryptionKey,
      'checksum': checksum,
      'isEncrypted': isEncrypted,
    };
  }

  factory VaultVideo.fromJson(Map<String, dynamic> json) {
    return VaultVideo(
      id: json['id'],
      originalPath: json['originalPath'],
      hiddenPath: json['hiddenPath'],
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      hiddenDate: DateTime.parse(json['hiddenDate']),
      thumbnail: json['thumbnail'] ?? '',
      encryptionKey: json['encryptionKey'] ?? '',
      checksum: json['checksum'] ?? '',
      isEncrypted: json['isEncrypted'] ?? true,
    );
  }
}

class VaultService {
  static const String _mainVaultKey = 'main_vault_password';
  static const String _fakeVaultKey = 'fake_vault_password';
  static const String _mainVideosKey = 'main_vault_videos';
  static const String _fakeVideosKey = 'fake_vault_videos';
  static const String _isSetupKey = 'vault_is_setup';
  static const String _fakeModeKey = 'is_fake_mode';

  // Security Questions Keys
  static const String _securityQuestionsKey = 'security_questions';
  static const String _securityAnswersKey = 'security_answers';
  static const String _securitySetupKey = 'security_setup_done';

  static bool _isInFakeMode = false;
  static bool _isAuthenticated = false;

  static bool get isInFakeMode => _isInFakeMode;
  static bool get isAuthenticated => _isAuthenticated;

  // Security Questions Management
  static Future<bool> isSecuritySetup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_securitySetupKey) ?? false;
  }

  static Future<bool> setSecurityQuestions(
    List<String> questions,
    List<String> answers,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Hash answers for security
      final hashedAnswers = answers
          .map((answer) => _hashPassword(answer.toLowerCase()))
          .toList();

      await prefs.setStringList(_securityQuestionsKey, questions);
      await prefs.setStringList(_securityAnswersKey, hashedAnswers);
      await prefs.setBool(_securitySetupKey, true);

      debugPrint('Security questions set up successfully');
      return true;
    } catch (e) {
      debugPrint('Error setting security questions: $e');
      return false;
    }
  }

  static Future<List<String>?> getSecurityQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_securityQuestionsKey);
  }

  static Future<bool> verifySecurityAnswers(List<String> answers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedHashedAnswers =
          prefs.getStringList(_securityAnswersKey) ?? [];

      if (storedHashedAnswers.length != answers.length) return false;

      for (int i = 0; i < answers.length; i++) {
        final inputHash = _hashPassword(answers[i].toLowerCase());
        if (inputHash != storedHashedAnswers[i]) {
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error verifying security answers: $e');
      return false;
    }
  }

  static Future<bool> resetPasswordWithSecurity(
    String newPassword,
    List<String> answers,
  ) async {
    if (!await verifySecurityAnswers(answers)) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final newHash = _hashPassword(newPassword);

      // Reset main password
      await prefs.setString(_mainVaultKey, newHash);

      debugPrint('Password reset successfully using security questions');
      return true;
    } catch (e) {
      debugPrint('Error resetting password: $e');
      return false;
    }
  }

  static Future<void> _autoSetupVault() async {
    try {
      // Default passwords for auto-setup
      final mainPassword = 'private123';
      final fakePassword = 'decoy123';

      await setupVault(mainPassword, fakePassword);
      debugPrint('Vault auto-setup completed with default passwords');
    } catch (e) {
      debugPrint('Error in auto-setup: $e');
    }
  }

  // Password Setup
  static Future<bool> setupVault(
    String mainPassword,
    String fakePassword,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Hash passwords before storing
      final mainHash = _hashPassword(mainPassword);
      final fakeHash = _hashPassword(fakePassword);

      await prefs.setString(_mainVaultKey, mainHash);
      await prefs.setString(_fakeVaultKey, fakeHash);
      await prefs.setBool(_isSetupKey, true);

      // Create vault directories
      await _createVaultDirectories();

      debugPrint('Vault setup completed');
      return true;
    } catch (e) {
      debugPrint('Error setting up vault: $e');
      return false;
    }
  }

  static Future<bool> isVaultSetup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isSetupKey) ?? false;
  }

  // Authentication with auto-setup
  static Future<bool> authenticate(String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Auto-setup if not done
      if (!await isVaultSetup()) {
        await _autoSetupVault();
      }

      final mainHash = prefs.getString(_mainVaultKey) ?? '';
      final fakeHash = prefs.getString(_fakeVaultKey) ?? '';

      final inputHash = _hashPassword(password);

      if (inputHash == mainHash) {
        _isAuthenticated = true;
        _isInFakeMode = false;
        await prefs.setBool(_fakeModeKey, false);
        debugPrint('Authenticated with main vault');

        // Check if security questions are set up
        if (!await isSecuritySetup()) {
          return true; // Return true but caller should check security setup
        }
        return true;
      } else if (inputHash == fakeHash) {
        _isAuthenticated = true;
        _isInFakeMode = true;
        await prefs.setBool(_fakeModeKey, true);
        debugPrint('Authenticated with fake vault');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Authentication error: $e');
      return false;
    }
  }

  static Future<void> logout() async {
    _isAuthenticated = false;
    _isInFakeMode = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fakeModeKey, false);
    debugPrint('Logged out from vault');
  }

  // Enhanced Video Management with Encryption
  static Future<bool> hideVideo(String videoPath) async {
    if (!_isAuthenticated) return false;

    try {
      final videoFile = File(videoPath);
      if (!await videoFile.exists()) return false;

      // Generate unique ID and encryption key for hidden video
      final videoId = _generateVideoId();
      final encryptionKey = _generateEncryptionKey();
      final hiddenFileName = '$videoId${_getFileExtension(videoPath)}';

      // Get appropriate vault directory
      final vaultDir = await _getVaultDirectory();
      final hiddenPath = '${vaultDir.path}/$hiddenFileName';

      // Read original file
      final originalBytes = await videoFile.readAsBytes();

      // Encrypt the video file
      final encryptedBytes = await _encryptData(originalBytes, encryptionKey);

      // Calculate checksum for integrity verification
      final checksum = _calculateChecksum(originalBytes);

      // Write encrypted file to vault
      final hiddenFile = File(hiddenPath);
      await hiddenFile.writeAsBytes(encryptedBytes);

      // Create vault video object with security metadata
      final vaultVideo = VaultVideo(
        id: videoId,
        originalPath: videoPath,
        hiddenPath: hiddenPath,
        fileName: videoFile.uri.pathSegments.last,
        fileSize: originalBytes.length,
        hiddenDate: DateTime.now(),
        thumbnail: '', // TODO: Generate encrypted thumbnail
        encryptionKey: encryptionKey,
        checksum: checksum,
        isEncrypted: true,
      );

      // Save to appropriate vault
      await _saveVideoToVault(vaultVideo);

      // Securely delete original file (optional - for true hiding)
      await _secureDelete(videoFile);

      debugPrint('Video securely hidden and encrypted: ${vaultVideo.fileName}');
      return true;
    } catch (e) {
      debugPrint('Error hiding video: $e');
      return false;
    }
  }

  static Future<bool> unhideVideo(String videoId) async {
    if (!_isAuthenticated) return false;

    try {
      final videos = await _getVaultVideos();
      final video = videos.firstWhere((v) => v.id == videoId);

      // Read encrypted file
      final hiddenFile = File(video.hiddenPath);
      if (!await hiddenFile.exists()) return false;

      final encryptedBytes = await hiddenFile.readAsBytes();

      // Decrypt the video file
      final decryptedBytes = await _decryptData(
        encryptedBytes,
        video.encryptionKey,
      );

      // Verify checksum for integrity
      final currentChecksum = _calculateChecksum(decryptedBytes);
      if (currentChecksum != video.checksum) {
        debugPrint('Checksum verification failed for video: ${video.fileName}');
        return false;
      }

      // Write decrypted file back to original location
      final originalFile = File(video.originalPath);
      await originalFile.writeAsBytes(decryptedBytes);

      // Remove encrypted file from vault
      await hiddenFile.delete();
      await _removeVideoFromVault(videoId);

      debugPrint('Video securely unhidden: ${video.fileName}');
      return true;
    } catch (e) {
      debugPrint('Error unhiding video: $e');
      return false;
    }
  }

  static Future<List<VaultVideo>> getVaultVideos() async {
    if (!_isAuthenticated) return [];
    return await _getVaultVideos();
  }

  // Private Helper Methods
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  static String _generateVideoId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch;
    return '${timestamp}_$random';
  }

  static String _getFileExtension(String filePath) {
    return filePath.substring(filePath.lastIndexOf('.'));
  }

  static Future<Directory> _getVaultDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final vaultName = _isInFakeMode ? 'fake_vault' : 'main_vault';
    final vaultDir = Directory('${appDir.path}/$vaultName');

    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }

    return vaultDir;
  }

  static Future<void> _createVaultDirectories() async {
    final appDir = await getApplicationDocumentsDirectory();

    final mainVaultDir = Directory('${appDir.path}/main_vault');
    final fakeVaultDir = Directory('${appDir.path}/fake_vault');

    if (!await mainVaultDir.exists()) {
      await mainVaultDir.create(recursive: true);
    }

    if (!await fakeVaultDir.exists()) {
      await fakeVaultDir.create(recursive: true);
    }
  }

  static Future<void> _saveVideoToVault(VaultVideo video) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _isInFakeMode ? _fakeVideosKey : _mainVideosKey;

    final videosJson = prefs.getString(key) ?? '[]';
    final videosList = json.decode(videosJson) as List;
    videosList.add(video.toJson());

    await prefs.setString(key, json.encode(videosList));
  }

  static Future<List<VaultVideo>> _getVaultVideos() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _isInFakeMode ? _fakeVideosKey : _mainVideosKey;

    final videosJson = prefs.getString(key) ?? '[]';
    final videosList = json.decode(videosJson) as List;

    return videosList.map((json) => VaultVideo.fromJson(json)).toList();
  }

  static Future<void> _removeVideoFromVault(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _isInFakeMode ? _fakeVideosKey : _mainVideosKey;

    final videosJson = prefs.getString(key) ?? '[]';
    final videosList = json.decode(videosJson) as List;

    videosList.removeWhere((video) => video['id'] == videoId);

    await prefs.setString(key, json.encode(videosList));
  }

  // Enhanced Security Helper Methods
  static String _generateEncryptionKey() {
    // Generate a cryptographically secure key
    final key = encrypt.Key.fromSecureRandom(32); // 256-bit key
    return key.base64;
  }

  static Future<List<int>> _encryptData(
    List<int> data,
    String keyBase64,
  ) async {
    try {
      final key = encrypt.Key.fromBase64(keyBase64);
      final iv = encrypt.IV.fromSecureRandom(16); // 128-bit IV
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      final encrypted = encrypter.encryptBytes(data, iv: iv);

      // Return IV + encrypted data for storage
      return [...iv.bytes, ...encrypted.bytes];
    } catch (e) {
      debugPrint('Encryption error: $e');
      rethrow;
    }
  }

  static Future<List<int>> _decryptData(
    List<int> encryptedData,
    String keyBase64,
  ) async {
    try {
      if (encryptedData.length < 16) {
        throw Exception('Invalid encrypted data format');
      }

      final key = encrypt.Key.fromBase64(keyBase64);
      final iv = encrypt.IV(Uint8List.fromList(encryptedData.sublist(0, 16)));
      final cipherText = Uint8List.fromList(encryptedData.sublist(16));

      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final decrypted = encrypter.decryptBytes(
        encrypt.Encrypted(cipherText),
        iv: iv,
      );

      return decrypted;
    } catch (e) {
      debugPrint('Decryption error: $e');
      rethrow;
    }
  }

  static String _calculateChecksum(List<int> data) {
    final digest = sha256.convert(data);
    return digest.toString();
  }

  static Future<void> _secureDelete(File file) async {
    try {
      if (!await file.exists()) return;

      // Overwrite file with random data multiple times
      final fileSize = await file.length();
      final random = Random.secure();

      for (int i = 0; i < 3; i++) {
        final randomData = List<int>.generate(
          fileSize,
          (_) => random.nextInt(256),
        );
        await file.writeAsBytes(randomData);
      }

      // Finally delete the file
      await file.delete();
      debugPrint('File securely deleted: ${file.path}');
    } catch (e) {
      debugPrint('Secure delete error: $e');
      // Fallback to regular delete
      try {
        await file.delete();
      } catch (deleteError) {
        debugPrint('Fallback delete also failed: $deleteError');
      }
    }
  }

  // Legacy method for backward compatibility
  static Future<bool> deleteFromVault(String videoId) async {
    if (!_isAuthenticated) return false;

    try {
      final videos = await _getVaultVideos();
      final video = videos.firstWhere((v) => v.id == videoId);

      // Delete encrypted file
      final hiddenFile = File(video.hiddenPath);
      if (await hiddenFile.exists()) {
        await _secureDelete(hiddenFile);
      }

      // Remove from vault records
      await _removeVideoFromVault(videoId);

      debugPrint('Video securely deleted from vault: ${video.fileName}');
      return true;
    } catch (e) {
      debugPrint('Error deleting from vault: $e');
      return false;
    }
  }

  static Future<void> clearVault() async {
    if (!_isAuthenticated) return;

    try {
      final videos = await _getVaultVideos();

      // Securely delete all hidden files
      for (final video in videos) {
        final hiddenFile = File(video.hiddenPath);
        if (await hiddenFile.exists()) {
          await _secureDelete(hiddenFile);
        }
      }

      // Clear vault records
      final prefs = await SharedPreferences.getInstance();
      final key = _isInFakeMode ? _fakeVideosKey : _mainVideosKey;
      await prefs.setString(key, '[]');

      debugPrint('Vault securely cleared');
    } catch (e) {
      debugPrint('Error clearing vault: $e');
    }
  }

  static Future<int> getVaultSize() async {
    if (!_isAuthenticated) return 0;

    try {
      final videos = await _getVaultVideos();
      int totalSize = 0;

      for (final video in videos) {
        final hiddenFile = File(video.hiddenPath);
        if (await hiddenFile.exists()) {
          totalSize += await hiddenFile.length();
        }
      }

      return totalSize;
    } catch (e) {
      debugPrint('Error calculating vault size: $e');
      return 0;
    }
  }

  // Additional Security Methods
  static Future<bool> verifyVaultIntegrity() async {
    if (!_isAuthenticated) return false;

    try {
      final videos = await _getVaultVideos();

      for (final video in videos) {
        final hiddenFile = File(video.hiddenPath);
        if (!await hiddenFile.exists()) {
          debugPrint('Missing file detected: ${video.fileName}');
          return false;
        }

        if (video.isEncrypted) {
          final encryptedBytes = await hiddenFile.readAsBytes();
          try {
            final decryptedBytes = await _decryptData(
              encryptedBytes,
              video.encryptionKey,
            );
            final currentChecksum = _calculateChecksum(decryptedBytes);

            if (currentChecksum != video.checksum) {
              debugPrint('Checksum mismatch detected: ${video.fileName}');
              return false;
            }
          } catch (e) {
            debugPrint(
              'Decryption failed during integrity check: ${video.fileName} - $e',
            );
            return false;
          }
        }
      }

      debugPrint('Vault integrity verification passed');
      return true;
    } catch (e) {
      debugPrint('Error during vault integrity check: $e');
      return false;
    }
  }

  static Future<bool> changePassword(
    String oldPassword,
    String newMainPassword,
    String newFakePassword,
  ) async {
    if (!_isAuthenticated) return false;

    try {
      // Verify old password
      if (!await authenticate(oldPassword)) return false;

      final prefs = await SharedPreferences.getInstance();

      // Update passwords
      final newMainHash = _hashPassword(newMainPassword);
      final newFakeHash = _hashPassword(newFakePassword);

      await prefs.setString(_mainVaultKey, newMainHash);
      await prefs.setString(_fakeVaultKey, newFakeHash);

      debugPrint('Passwords changed successfully');
      return true;
    } catch (e) {
      debugPrint('Error changing passwords: $e');
      return false;
    }
  }
}
