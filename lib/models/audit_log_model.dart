import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogModel {
  final String id;
  final String adminId;
  final String adminName;
  final String action; // e.g., "Deleted Driver", "Updated Schedule"
  final String target; // e.g., "Driver: John Doe"
  final DateTime timestamp;
  final String? details;
  final String? ipAddress;

  AuditLogModel({
    required this.id,
    required this.adminId,
    required this.adminName,
    required this.action,
    required this.target,
    required this.timestamp,
    this.details,
    this.ipAddress,
  });

  factory AuditLogModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return AuditLogModel(
      id: doc.id,
      adminId: data['adminId'] ?? '',
      adminName: data['adminName'] ?? 'Unknown Admin',
      action: data['action'] ?? '',
      target: data['target'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      details: data['details'],
      ipAddress: data['ipAddress'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'adminId': adminId,
      'adminName': adminName,
      'action': action,
      'target': target,
      'timestamp': FieldValue.serverTimestamp(),
      'details': details,
      'ipAddress': ipAddress,
    };
  }
}
