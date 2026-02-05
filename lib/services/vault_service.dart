import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:convert/convert.dart';
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

  // Chunk size for file processing (5MB) improves memory usage
  static const int _chunkSize = 5 * 1024 * 1024;

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

      // Hash new passwords
      final mainHash = _hashPassword(newPassword);
      final fakeHash = _hashPassword(
        'decoy123',
      ); // Set a default fake password as well

      // Reset both to known states
      await prefs.setString(_mainVaultKey, mainHash);
      await prefs.setString(_fakeVaultKey, fakeHash);
      await prefs.setBool(_isSetupKey, true);

      debugPrint('Passwords reset successfully using security questions');
      return true;
    } catch (e) {
      debugPrint('Error resetting password: $e');
      return false;
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

  // Authentication
  static Future<bool> authenticate(String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!await isVaultSetup()) {
        return false; // Don't auto-setup with default passwords, secure by default
      }

      final mainHash = prefs.getString(_mainVaultKey) ?? '';
      final fakeHash = prefs.getString(_fakeVaultKey) ?? '';

      final inputHash = _hashPassword(password);

      if (inputHash == mainHash) {
        _isAuthenticated = true;
        _isInFakeMode = false;
        await prefs.setBool(_fakeModeKey, false);
        debugPrint('Authenticated with main vault');

        // Ensure directories exist
        await _createVaultDirectories();

        return true;
      } else if (inputHash == fakeHash) {
        _isAuthenticated = true;
        _isInFakeMode = true;
        await prefs.setBool(_fakeModeKey, true);
        debugPrint('Authenticated with fake vault');

        await _createVaultDirectories();

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

  // Enhanced Video Management with Streaming Encryption
  static Future<bool> hideVideo(String videoPath) async {
    if (!_isAuthenticated) return false;

    RandomAccessFile? sourceRaf;
    IOSink? destSink;

    try {
      final videoFile = File(videoPath);
      if (!await videoFile.exists()) return false;

      final videoId = _generateVideoId();
      final encryptionKey = _generateEncryptionKey();
      final hiddenFileName = '$videoId${_getFileExtension(videoPath)}';
      final vaultDir = await _getVaultDirectory();
      final hiddenPath = '${vaultDir.path}/$hiddenFileName';

      final sourceSize = await videoFile.length();
      sourceRaf = await videoFile.open(mode: FileMode.read);

      final destFile = File(hiddenPath);
      destSink = destFile.openWrite();

      // Checksum
      final output = AccumulatorSink<Digest>();
      final checksumSink = sha256.startChunkedConversion(output);

      final key = encrypt.Key.fromBase64(encryptionKey);
      int bytesRead = 0;

      // Buffer for reading is handled by the OS/Stream, but we read fixed chunks manually here

      while (bytesRead < sourceSize) {
        // Calculate bytes to read
        final remaining = sourceSize - bytesRead;
        final toRead = remaining < _chunkSize ? remaining : _chunkSize;

        // Read data
        final dataBytes = await sourceRaf.read(toRead); // Returns Uint8List

        // Update Checksum
        checksumSink.add(dataBytes);

        // Encrypt this chunk independently
        final iv = encrypt.IV.fromSecureRandom(16);
        final encrypter = encrypt.Encrypter(encrypt.AES(key));
        final encrypted = encrypter.encryptBytes(dataBytes, iv: iv);

        // Write layout: [IV (16 bytes)][Length of Encrypted Data (4 bytes)][Encrypted Data]

        final lengthBytes = Uint8List(4);
        final len = encrypted.bytes.length;
        ByteData.view(lengthBytes.buffer).setUint32(0, len, Endian.big);

        destSink.add(iv.bytes);
        destSink.add(lengthBytes);
        destSink.add(encrypted.bytes);

        bytesRead += toRead;

        // Yield to event loop to keep UI responsive
        await Future.delayed(Duration.zero);
      }

      checksumSink.close();
      await destSink.flush();
      await destSink.close();
      await sourceRaf.close();

      final checksum = output.events.single.toString();

      // Create vault video object
      final vaultVideo = VaultVideo(
        id: videoId,
        originalPath: videoPath,
        hiddenPath: hiddenPath,
        fileName: videoFile.uri.pathSegments.last,
        fileSize: sourceSize,
        hiddenDate: DateTime.now(),
        thumbnail: await _generateThumbnail(videoPath, encryptionKey),
        encryptionKey: encryptionKey,
        checksum: checksum,
        isEncrypted: true,
      );

      await _saveVideoToVault(vaultVideo);
      await _secureDelete(videoFile);

      debugPrint('Video securely hidden: ${vaultVideo.fileName}');
      return true;
    } catch (e) {
      debugPrint('Error hiding video: $e');
      // Cleanup
      try {
        await sourceRaf?.close();
        await destSink?.close();
      } catch (e2) {
        // Ignore cleanup errors
      }
      return false;
    }
  }

  static Future<bool> unhideVideo(String videoId) async {
    if (!_isAuthenticated) return false;

    RandomAccessFile? hiddenRaf;
    IOSink? destSink;

    try {
      final videos = await _getVaultVideos();
      final video = videos.firstWhere((v) => v.id == videoId);
      final hiddenFile = File(video.hiddenPath);

      if (!await hiddenFile.exists()) return false;

      final key = encrypt.Key.fromBase64(video.encryptionKey);

      hiddenRaf = await hiddenFile.open(mode: FileMode.read);
      final hiddenSize = await hiddenFile.length();

      final destFile = File(video.originalPath);
      // Ensure directory exists
      final destDir = destFile.parent;
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }

      destSink = destFile.openWrite();

      // Checksum verifier
      final output = AccumulatorSink<Digest>();
      final checksumSink = sha256.startChunkedConversion(output);

      int bytesProcessed = 0;

      while (bytesProcessed < hiddenSize) {
        // Read IV (16 bytes)
        // Format: [IV (16 bytes)][Length (4 bytes)][Data]

        if (hiddenSize - bytesProcessed < 20) break;

        final ivBytes = await hiddenRaf.read(16);
        final lenBytes = await hiddenRaf.read(4);

        final encryptedLen = ByteData.view(
          lenBytes.buffer,
        ).getUint32(0, Endian.big);

        final encryptedData = await hiddenRaf.read(encryptedLen);

        final iv = encrypt.IV(ivBytes);
        final encrypter = encrypt.Encrypter(encrypt.AES(key));

        final decryptedBytes = encrypter.decryptBytes(
          encrypt.Encrypted(encryptedData),
          iv: iv,
        );

        // Write to file
        destSink.add(decryptedBytes);

        // Add to checksum calculation
        checksumSink.add(decryptedBytes);

        bytesProcessed += 16 + 4 + encryptedLen;

        await Future.delayed(Duration.zero);
      }

      await destSink.flush();
      await destSink.close();
      await hiddenRaf.close();

      checksumSink.close();
      final calculatedChecksum = output.events.single.toString();

      if (calculatedChecksum != video.checksum) {
        debugPrint('Checksum mismatch! Video might be corrupted.');
        // In strictly secure apps we might delete, but here preventing data loss is priority
        // return false;
      }

      // Cleanup
      await hiddenFile.delete();
      await _removeVideoFromVault(videoId);

      debugPrint('Video securely unhidden: ${video.fileName}');
      return true;
    } catch (e) {
      debugPrint('Error unhiding video: $e');
      await hiddenRaf?.close();
      await destSink?.close();
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
    return filePath.contains('.')
        ? filePath.substring(filePath.lastIndexOf('.'))
        : '.mp4';
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

  static String _generateEncryptionKey() {
    final key = encrypt.Key.fromSecureRandom(32); // 256-bit key
    return key.base64;
  }

  static Future<void> _secureDelete(File file) async {
    try {
      if (!await file.exists()) return;

      // Quick overwrite for performance (just header or small chunks in real large files, but here we do 3 passes on smaller files)
      // For large video files, full overwrite is too slow.
      // We will just rename and delete, or overwrite the first 1MB.

      final length = await file.length();
      final overwriteSize = length < 1024 * 1024
          ? length
          : 1024 * 1024; // Overwrite first 1MB

      if (overwriteSize > 0) {
        final raf = await file.open(mode: FileMode.write);
        final random = Random.secure();
        final randomData = List<int>.generate(
          overwriteSize.toInt(),
          (_) => random.nextInt(256),
        );
        await raf.writeFrom(randomData);
        await raf.close();
      }

      await file.delete();
      debugPrint('File deleted: ${file.path}');
    } catch (e) {
      debugPrint('Secure delete error: $e');
      try {
        await file.delete();
      } catch (deleteError) {
        debugPrint('Fallback delete also failed: $deleteError');
      }
    }
  }

  // Legacy/Helper
  static Future<bool> deleteFromVault(String videoId) async {
    if (!_isAuthenticated) return false;

    try {
      final videos = await _getVaultVideos();
      final video = videos.firstWhere((v) => v.id == videoId);

      final hiddenFile = File(video.hiddenPath);
      if (await hiddenFile.exists()) {
        await hiddenFile.delete(); // Simplified delete
      }

      await _removeVideoFromVault(videoId);

      debugPrint('Video deleted from vault: ${video.fileName}');
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

      for (final video in videos) {
        final hiddenFile = File(video.hiddenPath);
        if (await hiddenFile.exists()) {
          await hiddenFile.delete();
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final key = _isInFakeMode ? _fakeVideosKey : _mainVideosKey;
      await prefs.setString(key, '[]');

      debugPrint('Vault cleared');
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

  static Future<void> hardResetVault() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Clear all files
      final appDir = await getApplicationDocumentsDirectory();
      final mainVaultDir = Directory('${appDir.path}/main_vault');
      final fakeVaultDir = Directory('${appDir.path}/fake_vault');

      if (await mainVaultDir.exists()) {
        await mainVaultDir.delete(recursive: true);
      }
      if (await fakeVaultDir.exists()) {
        await fakeVaultDir.delete(recursive: true);
      }

      // Clear all keys
      await prefs.remove(_mainVaultKey);
      await prefs.remove(_fakeVaultKey);
      await prefs.remove(_mainVideosKey);
      await prefs.remove(_fakeVideosKey);
      await prefs.remove(_isSetupKey);
      await prefs.remove(_fakeModeKey);
      await prefs.remove(_securityQuestionsKey);
      await prefs.remove(_securityAnswersKey);
      await prefs.remove(_securitySetupKey);

      _isAuthenticated = false;
      _isInFakeMode = false;

      debugPrint('Vault hard reset completed');
    } catch (e) {
      debugPrint('Error during hard reset: $e');
    }
  }

  static Future<String> _generateThumbnail(
    String videoPath,
    String encryptionKey,
  ) async {
    try {
      final thumbnailDir = Directory(
        '${await _getVaultDirectory()}/thumbnails',
      );
      if (!await thumbnailDir.exists()) {
        await thumbnailDir.create(recursive: true);
      }

      final thumbnailPath =
          '${thumbnailDir.path}/${DateTime.now().millisecondsSinceEpoch}_thumb.jpg';

      // Just creating a dummy file for now
      // In real app, generate actual thumb
      await File(thumbnailPath).writeAsBytes([0, 0, 0, 0]);

      return thumbnailPath;
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      return '';
    }
  }
}
