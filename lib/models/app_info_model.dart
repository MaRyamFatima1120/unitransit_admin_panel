import 'package:cloud_firestore/cloud_firestore.dart';

class AppInfoModel {
  final String appName;
  final String appTagline;
  final String visionHeader;
  final String vision;
  final String version;
  final String university;
  final String appLogoUrl;
  
  // Mobile App Design System
  final String appPrimaryColor;
  final String appAccentColor;
  final String appBackgroundColor;
  final String appCardColor;
  final String appTextPrimaryColor;
  final String appTextSecondaryColor;

  // Admin Panel Design System
  final String adminPrimaryColor;
  final String adminAccentColor;
  final String adminBackgroundColor;
  final String adminCardColor;
  final String adminTextPrimaryColor;
  final String adminTextSecondaryColor;
  
  final List<ContributorModel> contributors;

  AppInfoModel({
    required this.appName,
    required this.appTagline,
    required this.visionHeader,
    required this.vision,
    required this.version,
    required this.university,
    required this.appLogoUrl,
    required this.appPrimaryColor,
    required this.appAccentColor,
    required this.appBackgroundColor,
    required this.appCardColor,
    required this.appTextPrimaryColor,
    required this.appTextSecondaryColor,
    required this.adminPrimaryColor,
    required this.adminAccentColor,
    required this.adminBackgroundColor,
    required this.adminCardColor,
    required this.adminTextPrimaryColor,
    required this.adminTextSecondaryColor,
    required this.contributors,
  });

  factory AppInfoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    return AppInfoModel(
      appName: data['appName'] ?? 'UniTransit',
      appTagline: data['appTagline'] ?? 'Smart University Transport System',
      visionHeader: data['visionHeader'] ?? 'PROJECT VISION',
      vision: data['vision'] ?? '',
      version: data['version'] ?? '',
      university: data['university'] ?? '',
      appLogoUrl: data['appLogoUrl'] ?? '',
      
      // Mobile Defaults
      appPrimaryColor: data['appPrimaryColor'] ?? '#1A237E',
      appAccentColor: data['appAccentColor'] ?? '#FFC107',
      appBackgroundColor: data['appBackgroundColor'] ?? '#F8FAFC',
      appCardColor: data['appCardColor'] ?? '#FFFFFF',
      appTextPrimaryColor: data['appTextPrimaryColor'] ?? '#0F172A',
      appTextSecondaryColor: data['appTextSecondaryColor'] ?? '#64748B',

      // Admin Defaults
      adminPrimaryColor: data['adminPrimaryColor'] ?? '#1A237E',
      adminAccentColor: data['adminAccentColor'] ?? '#FFC107',
      adminBackgroundColor: data['adminBackgroundColor'] ?? '#F8FAFC',
      adminCardColor: data['adminCardColor'] ?? '#FFFFFF',
      adminTextPrimaryColor: data['adminTextPrimaryColor'] ?? '#0F172A',
      adminTextSecondaryColor: data['adminTextSecondaryColor'] ?? '#64748B',
      
      contributors: (data['contributors'] as List? ?? [])
          .map((item) => ContributorModel.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appName': appName,
      'appTagline': appTagline,
      'visionHeader': visionHeader,
      'vision': vision,
      'version': version,
      'university': university,
      'appLogoUrl': appLogoUrl,
      'appPrimaryColor': appPrimaryColor,
      'appAccentColor': appAccentColor,
      'appBackgroundColor': appBackgroundColor,
      'appCardColor': appCardColor,
      'appTextPrimaryColor': appTextPrimaryColor,
      'appTextSecondaryColor': appTextSecondaryColor,
      'adminPrimaryColor': adminPrimaryColor,
      'adminAccentColor': adminAccentColor,
      'adminBackgroundColor': adminBackgroundColor,
      'adminCardColor': adminCardColor,
      'adminTextPrimaryColor': adminTextPrimaryColor,
      'adminTextSecondaryColor': adminTextSecondaryColor,
      'contributors': contributors.map((c) => c.toMap()).toList(),
    };
  }
}

class ContributorModel {
  final String name;
  final String role;
  final String subtitle;

  ContributorModel({required this.name, required this.role, required this.subtitle});

  factory ContributorModel.fromMap(Map<String, dynamic> map) {
    return ContributorModel(
      name: map['name'] ?? '',
      role: map['role'] ?? '',
      subtitle: map['subtitle'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'name': name, 'role': role, 'subtitle': subtitle};
}
