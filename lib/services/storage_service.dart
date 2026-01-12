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

  /// Deletes all files associated with a user (e.g., in 'user_images/{uid}/').
  Future<void> deleteUserDirectory(String uid) async {
    try {
      final listResult = await _storage.ref().child('user_images/$uid').listAll();

      // Delete all files in the directory
      await Future.wait(listResult.items.map((ref) => ref.delete()));

      // Note: Firebase Storage folders are virtual. Deleting all files "removes" the folder.
      // If there are subfolders, listAll() returns them in `prefixes`.
      // We are assuming a flat structure for user images.
    } catch (e) {
      // If the path doesn't exist, it's fine.
      if (e is FirebaseException && e.code == 'object-not-found') {
        return;
      }
      throw Exception('Failed to delete user files: $e');
    }
  }
}
