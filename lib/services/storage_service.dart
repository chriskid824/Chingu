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
}
