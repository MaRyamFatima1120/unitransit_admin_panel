import 'dart:async';
import 'package:flutter/material.dart';
import 'package:unitransit_admin/core/services/firebase_service.dart';

class GenderConfigViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService;
  
  Map<String, String> _genderConfigs = {};
  bool _isLoading = true;
  StreamSubscription? _subscription;

  GenderConfigViewModel(this._firebaseService) {
    _init();
  }

  Map<String, String> get genderConfigs => _genderConfigs;
  bool get isLoading => _isLoading;

  void _init() {
    _subscription = _firebaseService.getGenderConfigs().listen((configs) {
      _genderConfigs = configs;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> saveGender(String name, Color color) async {
    // Convert color to hex string (e.g., #FF4081)
    String hex = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
    await _firebaseService.updateGenderConfig(name, hex);
  }

  Future<void> deleteGender(String name) async {
    await _firebaseService.deleteGenderConfig(name);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
