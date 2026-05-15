import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/services/firebase_service.dart';
import '../models/app_info_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppSettingsViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService;
  AppInfoModel? _appInfo;
  bool _isLoading = false;

  AppInfoModel? get appInfo => _appInfo;
  bool get isLoading => _isLoading;

  AppSettingsViewModel(this._firebaseService) {
    _fetchAppInfo();
  }

  Future<void> _fetchAppInfo() async {
    _isLoading = true;
    notifyListeners();
    try {
      final doc = await FirebaseFirestore.instance.collection('app_settings').doc('about').get();
      _appInfo = AppInfoModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('Error fetching app info: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateAppLogo() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      _isLoading = true;
      notifyListeners();
      try {
        Uint8List fileBytes = await image.readAsBytes();
        String fileName = 'app_logo_${DateTime.now().millisecondsSinceEpoch}.png';
        String url = await _firebaseService.uploadImage(fileBytes, 'app_assets/$fileName');
        
        if (_appInfo != null) {
          final updatedInfo = AppInfoModel(
            vision: _appInfo!.vision,
            version: _appInfo!.version,
            university: _appInfo!.university,
            appLogoUrl: url,
            contributors: _appInfo!.contributors,
          );
          await _firebaseService.updateAppInfo(updatedInfo.toMap());
          _appInfo = updatedInfo;
        }
      } catch (e) {
        debugPrint('Error uploading logo: $e');
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveAppInfo({
    required String vision,
    required String version,
    required String university,
  }) async {
    if (_appInfo == null) return;
    
    _isLoading = true;
    notifyListeners();
    try {
      final updatedInfo = AppInfoModel(
        vision: vision,
        version: version,
        university: university,
        appLogoUrl: _appInfo!.appLogoUrl,
        contributors: _appInfo!.contributors,
      );
      await _firebaseService.updateAppInfo(updatedInfo.toMap());
      _appInfo = updatedInfo;
    } catch (e) {
      debugPrint('Error saving app info: $e');
    }
    _isLoading = false;
    notifyListeners();
  }
}
