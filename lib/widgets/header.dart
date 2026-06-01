import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';
import 'package:unitransit_admin/view_models/dashboard_view_model.dart';
import 'package:unitransit_admin/view_models/login_view_model.dart';
import 'package:unitransit_admin/views/faq_management_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Header extends StatefulWidget {
  const Header({super.key});

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();
    final isSuperAdmin = context.read<LoginViewModel>().isSuperAdmin;

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          if (AppResponsiveUtil.isMobile(context))
            IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: Icon(Icons.menu_rounded, color: AppColors.textDark),
            ),
          
          if (!AppResponsiveUtil.isMobile(context))
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getPageTitle(viewModel.selectedIndex),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      _getPageSubtitle(viewModel.selectedIndex),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          if (AppResponsiveUtil.isMobile(context)) const Spacer(),
          
          _buildHeaderAction(
            context, 
            Icons.notifications_none_rounded, 
            badgeCount: viewModel.unreadNotificationsCount,
            onTap: () => viewModel.setSelectedIndex(8), // Notifications Index
          ),
          
          const SizedBox(width: 32),
          
          // User Profile Info
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              String name = "";
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                if (data != null) {
                  final dbName = data['name']?.toString().trim();
                  if (dbName != null && dbName.isNotEmpty) {
                    name = dbName;
                  }
                }
              }
              
              // Fallback sequence
              if (name.isEmpty) {
                final authUser = FirebaseAuth.instance.currentUser;
                if (authUser != null && authUser.displayName != null && authUser.displayName!.isNotEmpty) {
                  name = authUser.displayName!.trim();
                } else {
                  name = isSuperAdmin ? "Super Admin" : "Admin";
                }
              }
              
              final displayInitial = name.isNotEmpty ? name[0].toUpperCase() : 'A';

              return Row(
                children: [
                  if (!AppResponsiveUtil.isMobile(context) && !AppResponsiveUtil.isTablet(context))
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            if (isSuperAdmin)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Colors.amber, Colors.orange]),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'MASTER',
                                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900),
                                ),
                              ),
                            Text(name, style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        Text(
                          isSuperAdmin ? 'Full Access' : 'Admin Access',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryNavy.withValues(alpha: 0.2), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.1),
                      child: Text(
                        displayInitial, 
                        style: TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _getPageTitle(int index) {
    switch (index) {
      case 0: return 'Dashboard Overview';
      case 1: return 'Student Management';
      case 2: return 'Driver Profiles';
      case 3: return 'Admin Management';
      case 4: return 'Fleet Operations';
      case 5: return 'Route & Map';
      case 6: return 'Gender Configurations';
      case 7: return 'Trip History';
      case 8: return 'System Notifications';
      case 9: return 'Support Center';
      case 10: return 'Application Settings';
      case 11: return 'Bus Schedules';
      case 12: return 'Emergency SOS';
      case 13: return 'Assign Routes';
      case 14: return 'Bus Fleet Management';
      default: return 'Admin Panel';
    }
  }

  String _getPageSubtitle(int index) {
    switch (index) {
      case 0: return 'Live metrics and system status at a glance';
      case 1: return 'Manage and monitor student profiles and access';
      case 2: return 'Oversee bus drivers and their assignments';
      case 3: return 'Manage administrator access and roles';
      case 4: return 'Live tracking and dispatch management';
      case 5: return 'Configure campuses, routes, and custom paths';
      case 6: return 'Adjust specific vehicle/route configurations';
      case 7: return 'View past logs and historical tracking data';
      case 8: return 'Recent alerts and updates from the system';
      case 9: return 'Manage inquiries and support tickets';
      case 10: return 'Configure global application parameters';
      case 11: return 'Manage schedules grouped by time and routes';
      case 12: return 'Respond to critical alerts from the fleet';
      case 13: return 'Link active buses with specific schedules';
      case 14: return 'Manage your list of physical vehicles';
      default: return 'Centralized administration dashboard';
    }
  }


  Widget _buildHeaderAction(BuildContext context, IconData icon, {int badgeCount = 0, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Icon(icon, color: AppColors.textSecondary, size: 22),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Center(
                  child: Text(
                    badgeCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}