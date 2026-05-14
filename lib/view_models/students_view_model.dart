import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:unitransit_admin/core/services/firebase_service.dart';
import 'package:unitransit_admin/models/student_model.dart';

class StudentsViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService;

  StudentsViewModel(this._firebaseService);

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  Future<void> addStudent({
    required String name,
    required String studentId,
    required String department,
    required String phone,
    required String route,
    required String stop,
  }) async {
    _isSaving = true;
    notifyListeners();

    try {
      final id = FirebaseFirestore.instance.collection('students').doc().id;
      final student = StudentModel(
        id: id,
        name: name,
        studentId: studentId,
        department: department,
        phoneNumber: phone,
        route: route,
        stop: stop,
        status: 'Active',
        createdAt: DateTime.now(),
      );
      await _firebaseService.addStudent(student);
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
