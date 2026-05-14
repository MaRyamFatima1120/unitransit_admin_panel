import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:unitransit_admin/core/services/firebase_service.dart';
import 'package:unitransit_admin/models/driver_model.dart';

class DriversViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService;

  DriversViewModel(this._firebaseService);

  String _selectedTab = 'All';
  String get selectedTab => _selectedTab;

  void setSelectedTab(String tab) {
    _selectedTab = tab;
    notifyListeners();
  }

  // Dialog / Form State
  bool _isUploading = false;
  bool get isUploading => _isUploading;

  String? _dialogError;
  String? get dialogError => _dialogError;

  void setDialogError(String? error) {
    _dialogError = error;
    notifyListeners();
  }

  Future<void> addDriver({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String cnic,
    required String license,
    required DateTime expiry,
    required String bus,
    required String experience,
    Uint8List? profileImage,
    Uint8List? frontImage,
    Uint8List? backImage,
    Uint8List? licenseImage,
  }) async {
    _isUploading = true;
    _dialogError = null;
    notifyListeners();

    try {
      final driverId = FirebaseFirestore.instance.collection('drivers').doc().id;
      
      String? profileUrl;
      String? frontUrl;
      String? backUrl;
      String? licenseUrl;

      if (profileImage != null) {
        profileUrl = await _firebaseService.uploadImage(profileImage, 'drivers/$driverId/profile.jpg');
      }
      if (frontImage != null) {
        frontUrl = await _firebaseService.uploadImage(frontImage, 'drivers/$driverId/cnic_front.jpg');
      }
      if (backImage != null) {
        backUrl = await _firebaseService.uploadImage(backImage, 'drivers/$driverId/cnic_back.jpg');
      }
      if (licenseImage != null) {
        licenseUrl = await _firebaseService.uploadImage(licenseImage, 'drivers/$driverId/license.jpg');
      }

      await _firebaseService.createDriverAuth(email, password);

      final newDriver = DriverModel(
        id: driverId,
        name: name,
        phoneNumber: phone,
        email: email,
        cnic: cnic,
        licenseNumber: license,
        licenseExpiry: expiry,
        assignedBus: bus,
        experience: experience,
        status: 'Offline',
        profileUrl: profileUrl,
        cnicFrontUrl: frontUrl,
        cnicBackUrl: backUrl,
        licenseImageUrl: licenseUrl,
        isVerified: false,
        createdAt: DateTime.now(),
      );

      await _firebaseService.addDriver(newDriver);

      await FirebaseFirestore.instance.collection('users').doc(driverId).set({
        'uid': driverId,
        'name': name,
        'email': email,
        'role': 'driver',
        'createdAt': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      _dialogError = _getFriendlyErrorMessage(e.toString());
      rethrow;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<void> updateDriver(DriverModel driver) async {
    await _firebaseService.updateDriver(driver);
    notifyListeners();
  }

  Future<void> deleteDriver(String id) async {
    await _firebaseService.deleteDriver(id);
    notifyListeners();
  }

  String _getFriendlyErrorMessage(String error) {
    if (error.contains('weak-password')) return "The password is too weak.";
    if (error.contains('email-already-in-use')) return "This email is already registered.";
    if (error.contains('invalid-email')) return "Invalid email format.";
    if (error.contains('unauthorized')) return "Permission Denied: Storage error.";
    return error;
  }
}
