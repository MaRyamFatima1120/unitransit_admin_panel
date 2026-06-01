import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:unitransit_admin/core/services/firebase_service.dart';

class NotificationsViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService;
  final ImagePicker _picker = ImagePicker();

  NotificationsViewModel(this._firebaseService);

  String _title = '';
  String _message = '';
  String _targetAudience = 'All'; // 'Students', 'Drivers', 'All', 'Specific'
  String _alertType = 'info';     // 'info', 'alert', 'system'
  String? _selectedUserId;
  bool _isSending = false;
  List<Map<String, dynamic>> _eligibleUsers = [];
  bool _isLoadingUsers = false;
  
  // Image handling
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  // Getters
  String get title => _title;
  String get message => _message;
  String get targetAudience => _targetAudience;
  String get alertType => _alertType;
  String? get selectedUserId => _selectedUserId;
  bool get isSending => _isSending;
  List<Map<String, dynamic>> get eligibleUsers => _eligibleUsers;
  bool get isLoadingUsers => _isLoadingUsers;
  XFile? get selectedImage => _selectedImage;
  Uint8List? get selectedImageBytes => _selectedImageBytes;

  // Setters/actions
  void setTitle(String value) {
    _title = value;
    notifyListeners();
  }

  void setMessage(String value) {
    _message = value;
    notifyListeners();
  }

  void setTargetAudience(String value) {
    _targetAudience = value;
    if (value == 'Specific' && _eligibleUsers.isEmpty) {
      loadEligibleUsers();
    }
    notifyListeners();
  }

  void setAlertType(String value) {
    _alertType = value;
    notifyListeners();
  }

  void setSelectedUserId(String? value) {
    _selectedUserId = value;
    notifyListeners();
  }

  Future<void> pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        _selectedImage = pickedFile;
        _selectedImageBytes = await pickedFile.readAsBytes();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void removeImage() {
    _selectedImage = null;
    _selectedImageBytes = null;
    notifyListeners();
  }

  void resetForm() {
    _title = '';
    _message = '';
    _targetAudience = 'All';
    _alertType = 'info';
    _selectedUserId = null;
    _isSending = false;
    _selectedImage = null;
    _selectedImageBytes = null;
    notifyListeners();
  }

  Future<void> loadEligibleUsers() async {
    _isLoadingUsers = true;
    notifyListeners();
    try {
      _eligibleUsers = await _firebaseService.getAllNotificationUsers();
      if (_eligibleUsers.isNotEmpty && _selectedUserId == null) {
        _selectedUserId = _eligibleUsers.first['uid'];
      }
    } catch (e) {
      debugPrint("Error loading eligible notification users: $e");
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  Future<String?> _uploadImageToStorage() async {
    if (_selectedImageBytes == null) return null;
    
    try {
      final fileName = 'notification_${DateTime.now().millisecondsSinceEpoch}_${_selectedImage!.name}';
      final storageRef = FirebaseStorage.instance.ref().child('notifications/$fileName');
      
      final uploadTask = storageRef.putData(
        _selectedImageBytes!,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint("Error uploading image: $e");
      return null;
    }
  }

  Future<void> sendNotification() async {
    _isSending = true;
    notifyListeners();
    try {
      String? imageUrl = await _uploadImageToStorage();

      if (_targetAudience == 'Specific') {
        if (_selectedUserId == null) {
          throw 'Please select a recipient user';
        }
        await _firebaseService.sendUserNotification(
          userId: _selectedUserId!,
          title: _title.trim(),
          message: _message.trim(),
          type: _alertType,
          imageUrl: imageUrl,
        );
      } else {
        await _firebaseService.sendCustomNotification(
          title: _title.trim(),
          message: _message.trim(),
          targetAudience: _targetAudience,
          type: _alertType,
          imageUrl: imageUrl,
        );
      }
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Stream<List<Map<String, dynamic>>> getSentNotifications() {
    return _firebaseService.getSentNotifications();
  }
}
