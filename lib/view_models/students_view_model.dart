import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:unitransit_admin/core/services/firebase_service.dart';
import 'package:unitransit_admin/models/student_model.dart';

class StudentsViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService;

  StudentsViewModel(this._firebaseService);

  String _selectedTab = 'All';
  String get selectedTab => _selectedTab;

  void setSelectedTab(String tab) {
    _selectedTab = tab;
    notifyListeners();
  }

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  Future<void> addStudent({
    required String name,
    required String email,
    required String studentId,
    required String regNo,
    required String department,
    required String semester,
    required String phone,
    String profileImage = '',
  }) async {
    _isSaving = true;
    notifyListeners();

    try {
      final id = FirebaseFirestore.instance.collection('users').doc().id;
      final student = StudentModel(
        id: id,
        name: name,
        email: email,
        studentId: studentId,
        regNo: regNo,
        department: department,
        semester: semester,
        phoneNumber: phone,
        profileImage: profileImage,
        createdAt: DateTime.now(),
      );
      await _firebaseService.addStudent(student);
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> updateStudent(StudentModel student) async {
    _isSaving = true;
    notifyListeners();

    try {
      await _firebaseService.updateStudent(student);
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> deleteStudent(String id) async {
    await _firebaseService.deleteStudent(id);
    notifyListeners();
  }
}
