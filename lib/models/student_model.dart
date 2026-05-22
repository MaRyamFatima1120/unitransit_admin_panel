import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String id;
  final String name;
  final String email;
  final String studentId; // Roll Number
  final String regNo;
  final String department;
  final String semester;
  final String phoneNumber;
  final String profileImage;
  final String status; // 'Active', 'Inactive', 'Online', 'Offline'
  final bool isVerified;
  final bool isBlocked;
  final DateTime createdAt;

  StudentModel({
    required this.id,
    required this.name,
    required this.email,
    required this.studentId,
    required this.regNo,
    required this.department,
    required this.semester,
    required this.phoneNumber,
    required this.profileImage,
    this.status = 'Offline',
    this.isVerified = true,
    this.isBlocked = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': id,
      'name': name,
      'email': email,
      'studentId': studentId,
      'rollNo': studentId,
      'regNo': regNo,
      'department': department,
      'semester': semester,
      'phoneNumber': phoneNumber,
      'phone': phoneNumber,
      'role': 'Student',
      'profileImage': profileImage,
      'status': status,
      'isVerified': isVerified,
      'isBlocked': isBlocked,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory StudentModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return StudentModel(
      id: map['id'] ?? map['uid'] ?? docId ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      studentId: map['studentId'] ?? map['rollNo'] ?? 'N/A',
      regNo: map['regNo'] ?? 'N/A',
      department: map['department'] ?? 'N/A',
      semester: map['semester'] ?? 'N/A',
      phoneNumber: map['phoneNumber'] ?? map['phone'] ?? 'N/A',
      profileImage: map['profileImage'] ?? map['profileImageUrl'] ?? '',
      status: map['status'] ?? 'Offline',
      isVerified: map['isVerified'] ?? true,
      isBlocked: map['isBlocked'] ?? false,
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] is Timestamp ? (map['createdAt'] as Timestamp).toDate() : DateTime.now()) 
          : DateTime.now(),
    );
  }

  StudentModel copyWith({
    String? id,
    String? name,
    String? email,
    String? studentId,
    String? regNo,
    String? department,
    String? semester,
    String? phoneNumber,
    String? profileImage,
    String? status,
    bool? isVerified,
    bool? isBlocked,
    DateTime? createdAt,
  }) {
    return StudentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      studentId: studentId ?? this.studentId,
      regNo: regNo ?? this.regNo,
      department: department ?? this.department,
      semester: semester ?? this.semester,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImage: profileImage ?? this.profileImage,
      status: status ?? this.status,
      isVerified: isVerified ?? this.isVerified,
      isBlocked: isBlocked ?? this.isBlocked,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
