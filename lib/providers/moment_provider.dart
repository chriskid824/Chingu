import 'dart:io';
import 'package:flutter/foundation.dart';
import '../services/moment_service.dart';
import '../models/moment_model.dart';

class MomentProvider extends ChangeNotifier {
  final MomentService _momentService = MomentService();

  bool _isLoading = false;
  String? _error;
  late final Stream<List<MomentModel>> _momentsStream;

  MomentProvider() {
    _momentsStream = _momentService.getMoments();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  Stream<List<MomentModel>> get momentsStream => _momentsStream;

  Future<bool> createMoment({
    required String userId,
    required String userName,
    String? userAvatarUrl,
    required String content,
    File? imageFile,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _momentService.createMoment(
        userId: userId,
        userName: userName,
        userAvatarUrl: userAvatarUrl,
        content: content,
        imageFile: imageFile,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteMoment(String momentId, String? imageUrl) async {
    try {
        await _momentService.deleteMoment(momentId, imageUrl);
    } catch (e) {
        if (kDebugMode) {
          print("Error deleting moment: $e");
        }
        // Optionally set error state
    }
  }
}
