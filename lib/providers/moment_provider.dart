import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/moment_model.dart';
import '../services/moment_service.dart';

class MomentProvider extends ChangeNotifier {
  final MomentService _momentService = MomentService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> addMoment(MomentModel moment, File? imageFile) async {
    _setLoading(true);
    try {
      await _momentService.createMoment(moment, imageFile);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteMoment(String momentId) async {
    try {
      await _momentService.deleteMoment(momentId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    }
  }

  Stream<List<MomentModel>> getMomentsStream(String userId) {
    return _momentService.getMoments(userId);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
