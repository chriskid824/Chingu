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

  /// Deletes all files associated with a user.
  /// Simulates folder deletion by listing and deleting all files containing the `user_images/{uid}` prefix.
  Future<void> deleteUserDirectory(String uid) async {
    try {
      // Note: Firebase Storage doesn't support folder deletion.
      // We must list all files with the prefix and delete them individually.
      final ListResult result = await _storage.ref().child('user_images/$uid').listAll();

      await Future.wait(
        result.items.map((Reference ref) => ref.delete()),
      );
    } catch (e) {
      // Log error but don't stop the process as this is cleanup
      print('Failed to delete user directory: $e');
    }
  }
}
