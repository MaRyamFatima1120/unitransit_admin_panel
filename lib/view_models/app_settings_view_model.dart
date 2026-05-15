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
  Uint8List? _pickedImageBytes;
  
  // Mobile Temp Colors
  String? _tempAppPrimaryColor;
  String? _tempAppAccentColor;
  String? _tempAppBackgroundColor;
  String? _tempAppCardColor;
  String? _tempAppTextPrimaryColor;
  String? _tempAppTextSecondaryColor;

  // Admin Temp Colors
  String? _tempAdminPrimaryColor;
  String? _tempAdminAccentColor;
  String? _tempAdminBackgroundColor;
  String? _tempAdminCardColor;
  String? _tempAdminTextPrimaryColor;
  String? _tempAdminTextSecondaryColor;

  AppInfoModel? get appInfo => _appInfo;
  bool get isLoading => _isLoading;
  Uint8List? get pickedImageBytes => _pickedImageBytes;
  
  // Mobile Getters
  String get appPrimaryColor => _tempAppPrimaryColor ?? _appInfo?.appPrimaryColor ?? '#1A237E';
  String get appAccentColor => _tempAppAccentColor ?? _appInfo?.appAccentColor ?? '#FFC107';
  String get appBackgroundColor => _tempAppBackgroundColor ?? _appInfo?.appBackgroundColor ?? '#F8FAFC';
  String get appCardColor => _tempAppCardColor ?? _appInfo?.appCardColor ?? '#FFFFFF';
  String get appTextPrimaryColor => _tempAppTextPrimaryColor ?? _appInfo?.appTextPrimaryColor ?? '#0F172A';
  String get appTextSecondaryColor => _tempAppTextSecondaryColor ?? _appInfo?.appTextSecondaryColor ?? '#64748B';

  // Admin Getters
  String get adminPrimaryColor => _tempAdminPrimaryColor ?? _appInfo?.adminPrimaryColor ?? '#1A237E';
  String get adminAccentColor => _tempAdminAccentColor ?? _appInfo?.adminAccentColor ?? '#FFC107';
  String get adminBackgroundColor => _tempAdminBackgroundColor ?? _appInfo?.adminBackgroundColor ?? '#F8FAFC';
  String get adminCardColor => _tempAdminCardColor ?? _appInfo?.adminCardColor ?? '#FFFFFF';
  String get adminTextPrimaryColor => _tempAdminTextPrimaryColor ?? _appInfo?.adminTextPrimaryColor ?? '#0F172A';
  String get adminTextSecondaryColor => _tempAdminTextSecondaryColor ?? _appInfo?.adminTextSecondaryColor ?? '#64748B';

  AppSettingsViewModel(this._firebaseService) {
    _fetchAppInfo();
  }

  Future<void> _fetchAppInfo() async {
    _isLoading = true;
    notifyListeners();
    try {
      final doc = await FirebaseFirestore.instance.collection('app_settings').doc('about').get();
      _appInfo = AppInfoModel.fromFirestore(doc);
      _syncTempColors();
    } catch (e) {
      debugPrint('Error fetching app info: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _syncTempColors() {
    if (_appInfo == null) return;
    _tempAppPrimaryColor = _appInfo!.appPrimaryColor;
    _tempAppAccentColor = _appInfo!.appAccentColor;
    _tempAppBackgroundColor = _appInfo!.appBackgroundColor;
    _tempAppCardColor = _appInfo!.appCardColor;
    _tempAppTextPrimaryColor = _appInfo!.appTextPrimaryColor;
    _tempAppTextSecondaryColor = _appInfo!.appTextSecondaryColor;

    _tempAdminPrimaryColor = _appInfo!.adminPrimaryColor;
    _tempAdminAccentColor = _appInfo!.adminAccentColor;
    _tempAdminBackgroundColor = _appInfo!.adminBackgroundColor;
    _tempAdminCardColor = _appInfo!.adminCardColor;
    _tempAdminTextPrimaryColor = _appInfo!.adminTextPrimaryColor;
    _tempAdminTextSecondaryColor = _appInfo!.adminTextSecondaryColor;
  }

  // Mobile Setters
  void setAppPrimaryColor(String hex) { _tempAppPrimaryColor = hex; notifyListeners(); }
  void setAppAccentColor(String hex) { _tempAppAccentColor = hex; notifyListeners(); }
  void setAppBackgroundColor(String hex) { _tempAppBackgroundColor = hex; notifyListeners(); }
  void setAppCardColor(String hex) { _tempAppCardColor = hex; notifyListeners(); }
  void setAppTextPrimaryColor(String hex) { _tempAppTextPrimaryColor = hex; notifyListeners(); }
  void setAppTextSecondaryColor(String hex) { _tempAppTextSecondaryColor = hex; notifyListeners(); }

  // Admin Setters
  void setAdminPrimaryColor(String hex) { _tempAdminPrimaryColor = hex; notifyListeners(); }
  void setAdminAccentColor(String hex) { _tempAdminAccentColor = hex; notifyListeners(); }
  void setAdminBackgroundColor(String hex) { _tempAdminBackgroundColor = hex; notifyListeners(); }
  void setAdminCardColor(String hex) { _tempAdminCardColor = hex; notifyListeners(); }
  void setAdminTextPrimaryColor(String hex) { _tempAdminTextPrimaryColor = hex; notifyListeners(); }
  void setAdminTextSecondaryColor(String hex) { _tempAdminTextSecondaryColor = hex; notifyListeners(); }

  Future<void> saveAppInfo({
    required String appName,
    required String appTagline,
    required String visionHeader,
    required String vision,
    required String version,
    required String university,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final updatedInfo = AppInfoModel(
        appName: appName,
        appTagline: appTagline,
        visionHeader: visionHeader,
        vision: vision,
        version: version,
        university: university,
        appLogoUrl: _appInfo?.appLogoUrl ?? '',
        
        appPrimaryColor: appPrimaryColor,
        appAccentColor: appAccentColor,
        appBackgroundColor: appBackgroundColor,
        appCardColor: appCardColor,
        appTextPrimaryColor: appTextPrimaryColor,
        appTextSecondaryColor: appTextSecondaryColor,
        
        adminPrimaryColor: adminPrimaryColor,
        adminAccentColor: adminAccentColor,
        adminBackgroundColor: adminBackgroundColor,
        adminCardColor: adminCardColor,
        adminTextPrimaryColor: adminTextPrimaryColor,
        adminTextSecondaryColor: adminTextSecondaryColor,
        
        contributors: _appInfo?.contributors ?? [],
      );
      await _firebaseService.updateAppInfo(updatedInfo.toMap());
      _appInfo = updatedInfo;
      _syncTempColors();
    } catch (e) {
      debugPrint('Error saving app info: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateAppLogo() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _isLoading = true;
      notifyListeners();
      try {
        Uint8List fileBytes = await image.readAsBytes();
        _pickedImageBytes = fileBytes;
        notifyListeners();
        String fileName = 'app_logo_${DateTime.now().millisecondsSinceEpoch}.png';
        String url = await _firebaseService.uploadImage(fileBytes, 'app_assets/$fileName');
        if (_appInfo != null) {
          final updatedInfo = AppInfoModel(
            appName: _appInfo!.appName,
            appTagline: _appInfo!.appTagline,
            visionHeader: _appInfo!.visionHeader,
            vision: _appInfo!.vision,
            version: _appInfo!.version,
            university: _appInfo!.university,
            appLogoUrl: url,
            appPrimaryColor: _appInfo!.appPrimaryColor,
            appAccentColor: _appInfo!.appAccentColor,
            appBackgroundColor: _appInfo!.appBackgroundColor,
            appCardColor: _appInfo!.appCardColor,
            appTextPrimaryColor: _appInfo!.appTextPrimaryColor,
            appTextSecondaryColor: _appInfo!.appTextSecondaryColor,
            adminPrimaryColor: _appInfo!.adminPrimaryColor,
            adminAccentColor: _appInfo!.adminAccentColor,
            adminBackgroundColor: _appInfo!.adminBackgroundColor,
            adminCardColor: _appInfo!.adminCardColor,
            adminTextPrimaryColor: _appInfo!.adminTextPrimaryColor,
            adminTextSecondaryColor: _appInfo!.adminTextSecondaryColor,
            contributors: _appInfo!.contributors,
          );
          await _firebaseService.updateAppInfo(updatedInfo.toMap());
          _appInfo = updatedInfo;
        }
      } catch (e) { debugPrint('Error uploading logo: $e'); }
      _isLoading = false;
      notifyListeners();
    }
  }

  void addContributor() { if (_appInfo == null) return; _appInfo!.contributors.add(ContributorModel(name: '', role: '', subtitle: '')); notifyListeners(); }
  void removeContributor(int index) { if (_appInfo == null || _appInfo!.contributors.length <= index) return; _appInfo!.contributors.removeAt(index); notifyListeners(); }
  void updateContributor(int index, String name, String role, String subtitle) { if (_appInfo == null || _appInfo!.contributors.length <= index) return; _appInfo!.contributors[index] = ContributorModel(name: name, role: role, subtitle: subtitle); }
}
