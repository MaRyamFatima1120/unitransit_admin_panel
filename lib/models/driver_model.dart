import 'package:cloud_firestore/cloud_firestore.dart';

class DriverModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String email;
  final String cnic;
  final String licenseNumber;
  final DateTime licenseExpiry;
  final String assignedBus;
  final List<String> assignedRoutes;
  final String experience;
  final String status; // 'Online', 'Offline', 'Busy'
  final String? cnicFrontUrl;
  final String? cnicBackUrl;
  final String? profileUrl;
  final String? licenseImageUrl;
  final bool isVerified;
  final bool isBlocked;
  final DateTime createdAt;

  DriverModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.cnic,
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.assignedBus,
    this.assignedRoutes = const [],
    required this.experience,
    required this.status,
    this.cnicFrontUrl,
    this.cnicBackUrl,
    this.profileUrl,
    this.licenseImageUrl,
    this.isVerified = false,
    this.isBlocked = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'cnic': cnic,
      'licenseNumber': licenseNumber,
      'licenseExpiry': Timestamp.fromDate(licenseExpiry),
      'assignedBus': assignedBus,
      'assignedRoutes': assignedRoutes,
      'experience': experience,
      'status': status,
      'cnicFrontUrl': cnicFrontUrl,
      'cnicBackUrl': cnicBackUrl,
      'profileUrl': profileUrl,
      'licenseImageUrl': licenseImageUrl,
      'isVerified': isVerified,
      'isBlocked': isBlocked,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory DriverModel.fromMap(Map<String, dynamic> map) {
    return DriverModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'] ?? '',
      cnic: map['cnic'] ?? '',
      licenseNumber: map['licenseNumber'] ?? '',
      licenseExpiry: (map['licenseExpiry'] as Timestamp).toDate(),
      assignedBus: map['assignedBus'] ?? '',
      assignedRoutes: map['assignedRoutes'] != null ? List<String>.from(map['assignedRoutes']) : const [],
      experience: map['experience'] ?? '',
      status: map['status'] ?? 'Offline',
      cnicFrontUrl: map['cnicFrontUrl'],
      cnicBackUrl: map['cnicBackUrl'],
      profileUrl: map['profileUrl'],
      licenseImageUrl: map['licenseImageUrl'],
      isVerified: map['isVerified'] ?? false,
      isBlocked: map['isBlocked'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  DriverModel copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? email,
    String? cnic,
    String? licenseNumber,
    DateTime? licenseExpiry,
    String? assignedBus,
    List<String>? assignedRoutes,
    String? experience,
    String? status,
    String? cnicFrontUrl,
    String? cnicBackUrl,
    String? profileUrl,
    String? licenseImageUrl,
    bool? isVerified,
    bool? isBlocked,
    DateTime? createdAt,
  }) {
    return DriverModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      cnic: cnic ?? this.cnic,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      licenseExpiry: licenseExpiry ?? this.licenseExpiry,
      assignedBus: assignedBus ?? this.assignedBus,
      assignedRoutes: assignedRoutes ?? this.assignedRoutes,
      experience: experience ?? this.experience,
      status: status ?? this.status,
      cnicFrontUrl: cnicFrontUrl ?? this.cnicFrontUrl,
      cnicBackUrl: cnicBackUrl ?? this.cnicBackUrl,
      profileUrl: profileUrl ?? this.profileUrl,
      licenseImageUrl: licenseImageUrl ?? this.licenseImageUrl,
      isVerified: isVerified ?? this.isVerified,
      isBlocked: isBlocked ?? this.isBlocked,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
