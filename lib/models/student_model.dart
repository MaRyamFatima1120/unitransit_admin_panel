import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String id;
  final String name;
  final String studentId; // Roll Number
  final String department;
  final String phoneNumber;
  final String route;
  final String stop;
  final String status; // 'Active', 'Inactive'
  final DateTime createdAt;

  StudentModel({
    required this.id,
    required this.name,
    required this.studentId,
    required this.department,
    required this.phoneNumber,
    required this.route,
    required this.stop,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'studentId': studentId,
      'department': department,
      'phoneNumber': phoneNumber,
      'route': route,
      'stop': stop,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      studentId: map['studentId'] ?? '',
      department: map['department'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      route: map['route'] ?? '',
      stop: map['stop'] ?? '',
      status: map['status'] ?? 'Active',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
