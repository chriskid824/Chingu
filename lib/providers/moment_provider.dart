import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/moment_model.dart';
import '../services/moment_service.dart';

class MomentProvider extends ChangeNotifier {
  final MomentService _momentService = MomentService();

  List<MomentModel> _moments = [];
  List<MomentModel> get moments => _moments;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription<List<MomentModel>>? _momentsSubscription;

  void fetchMoments(String userId) {
    _isLoading = true;
    // notifyListeners(); // Delay this or avoid if called in build? Better to call in initState.

    _momentsSubscription?.cancel();
    _momentsSubscription = _momentService.getMoments(userId).listen((momentsData) {
      _moments = momentsData;
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      debugPrint('Error fetching moments: $error');
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> addMoment(MomentModel moment, List<File> images) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _momentService.createMoment(moment, images);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteMoment(String momentId) async {
    try {
      await _momentService.deleteMoment(momentId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    _momentsSubscription?.cancel();
    super.dispose();
  }
}
