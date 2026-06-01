import 'package:cloud_firestore/cloud_firestore.dart';

class SupportTicketModel {
  final String id;
  final String email;
  final String issue;
  final String name;
  final String phone;
  final String status;
  final DateTime timestamp;
  final String userEmail;
  final String userId;
  final String userName;
  final String userRole;
  final String? adminReply;
  final bool userRead;
  final bool adminRead;

  SupportTicketModel({
    required this.id,
    required this.email,
    required this.issue,
    required this.name,
    required this.phone,
    required this.status,
    required this.timestamp,
    required this.userEmail,
    required this.userId,
    required this.userName,
    required this.userRole,
    this.adminReply,
    this.userRead = false,
    this.adminRead = false,
  });

  factory SupportTicketModel.fromMap(String id, Map<String, dynamic> map) {
    return SupportTicketModel(
      id: id,
      email: map['email'] ?? '',
      issue: map['issue'] ?? 'No issue description provided',
      name: map['name'] ?? 'Anonymous',
      phone: map['phone'] ?? 'No phone',
      status: map['status'] ?? 'Pending',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userEmail: map['userEmail'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userRole: map['userRole'] ?? 'Unknown',
      adminReply: map['adminReply'],
      userRead: map['userRead'] ?? false,
      adminRead: map['adminRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'issue': issue,
      'name': name,
      'phone': phone,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'userEmail': userEmail,
      'userId': userId,
      'userName': userName,
      'userRole': userRole,
      'adminReply': adminReply,
      'userRead': userRead,
      'adminRead': adminRead,
    };
  }

  SupportTicketModel copyWith({
    String? status,
    String? adminReply,
    bool? userRead,
    bool? adminRead,
  }) {
    return SupportTicketModel(
      id: id,
      email: email,
      issue: issue,
      name: name,
      phone: phone,
      status: status ?? this.status,
      timestamp: timestamp,
      userEmail: userEmail,
      userId: userId,
      userName: userName,
      userRole: userRole,
      adminReply: adminReply ?? this.adminReply,
      userRead: userRead ?? this.userRead,
      adminRead: adminRead ?? this.adminRead,
    );
  }
}
