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
      // 1. Create Auth first to get the UID
      final String uid = await _firebaseService.createUserAuth(email, password);
      
      String? profileUrl;
      String? frontUrl;
      String? backUrl;
      String? licenseUrl;

      // 2. Upload images using the UID as path
      if (profileImage != null) {
        profileUrl = await _firebaseService.uploadImage(profileImage, 'drivers/$uid/profile.jpg');
      }
      if (frontImage != null) {
        frontUrl = await _firebaseService.uploadImage(frontImage, 'drivers/$uid/cnic_front.jpg');
      }
      if (backImage != null) {
        backUrl = await _firebaseService.uploadImage(backImage, 'drivers/$uid/cnic_back.jpg');
      }
      if (licenseImage != null) {
        licenseUrl = await _firebaseService.uploadImage(licenseImage, 'drivers/$uid/license.jpg');
      }

      final newDriver = DriverModel(
        id: uid,
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

      // 3. Save to drivers collection
      print("Saving driver to Firestore with UID: $uid");
      await _firebaseService.addDriver(newDriver);

      // 4. Save to generic users collection (for login role check)
      print("Saving role 'Driver' to users collection for UID: $uid");
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'role': 'Driver',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Verification Step: Immediately try to read it back
      final verifyDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (verifyDoc.exists) {
        print("VERIFIED: User document successfully created for $email (UID: $uid)");
      } else {
        print("CRITICAL ERROR: User document NOT found immediately after save for UID: $uid");
        throw 'Firestore write failed: Document not found after save.';
      }

    } catch (e) {
      print("DRIVER ADDITION FAILED: $e");
      _dialogError = _getFriendlyErrorMessage(e.toString());
      rethrow;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<void> updateDriver(
    DriverModel driver, {
    Uint8List? newProfileImage,
    Uint8List? newFrontImage,
    Uint8List? newBackImage,
    Uint8List? newLicenseImage,
  }) async {
    _isUploading = true;
    notifyListeners();

    try {
      String? profileUrl = driver.profileUrl;
      String? frontUrl = driver.cnicFrontUrl;
      String? backUrl = driver.cnicBackUrl;
      String? licenseUrl = driver.licenseImageUrl;

      if (newProfileImage != null) {
        profileUrl = await _firebaseService.uploadImage(newProfileImage, 'drivers/profile_${driver.id}.jpg');
      }
      if (newFrontImage != null) {
        frontUrl = await _firebaseService.uploadImage(newFrontImage, 'drivers/cnic_front_${driver.id}.jpg');
      }
      if (newBackImage != null) {
        backUrl = await _firebaseService.uploadImage(newBackImage, 'drivers/cnic_back_${driver.id}.jpg');
      }
      if (newLicenseImage != null) {
        licenseUrl = await _firebaseService.uploadImage(newLicenseImage, 'drivers/license_${driver.id}.jpg');
      }

      final updatedDriver = driver.copyWith(
        profileUrl: profileUrl,
        cnicFrontUrl: frontUrl,
        cnicBackUrl: backUrl,
        licenseImageUrl: licenseUrl,
      );

      await _firebaseService.updateDriver(updatedDriver);
    } finally {
      _isUploading = false;
      notifyListeners();
    }
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
