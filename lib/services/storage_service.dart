import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a file to the specified path.
  /// Returns an [UploadTask] that can be used to monitor progress.
  UploadTask uploadFile(File file, String path) {
    try {
      final ref = _storage.ref().child(path);
      return ref.putFile(file);
    } catch (e) {
      throw Exception('Failed to start upload: $e');
    }
  }

  /// Gets the download URL for a stored file.
  Future<String> getDownloadUrl(String path) async {
    try {
      return await _storage.ref().child(path).getDownloadURL();
    } catch (e) {
      throw Exception('Failed to get download URL: $e');
    }
  }

  /// Deletes a file at the specified path.
  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref().child(path).delete();
    } catch (e) {
      // If the file doesn't exist, we can consider it deleted
      if (e is FirebaseException && e.code == 'object-not-found') {
        return;
      }
      throw Exception('Failed to delete file: $e');
    }
  }

  /// Deletes all files in a directory.
  /// Note: Firebase Storage doesn't strictly support directories.
  /// This iterates over files with the given prefix and deletes them.
  Future<void> deleteUserDirectory(String uid) async {
    try {
      // Common paths for user data
      final paths = [
        'user_images/$uid',
        'user_avatars', // Requires filtering, tricky without consistent naming.
        // Assuming user_avatars stores as ${uid}_timestamp.jpg based on EditProfileScreen
      ];

      // 1. Try to delete specific folder if used
      try {
        final ListResult result = await _storage.ref().child('user_images/$uid').listAll();
        for (final ref in result.items) {
          await ref.delete();
        }
      } catch (e) {
        // Ignore if folder not found
      }

      // 2. We can't easily list 'user_avatars' and filter by UID efficiently
      // if there are many users. We rely on the caller to provide the avatar URL
      // or we accept that we might leave the avatar file if we don't know the exact path.
      // However, we can try to rely on a standardized path in the future.
    } catch (e) {
      throw Exception('Failed to delete user directory: $e');
    }
  }
}
