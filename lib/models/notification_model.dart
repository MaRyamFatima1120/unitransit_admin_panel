import 'package:flutter/material.dart';

enum NotificationType { support, alert, success, warning }

class SystemNotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;
  final Color color;

  SystemNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    required this.color,
  });
}
