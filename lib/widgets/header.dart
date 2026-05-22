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
        border: const Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          if (!AppResponsiveUtil.isDesktop(context))
            IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu_rounded, color: AppColors.textDark),
            ),
          
          const Spacer(),
          
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
              String name = isSuperAdmin ? 'Super Admin' : 'Admin';
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                if (data != null) {
                  final dbName = data['name']?.toString().trim();
                  if (dbName != null && dbName.isNotEmpty) {
                    name = dbName;
                  }
                }
              }
              if (name == (isSuperAdmin ? 'Super Admin' : 'Admin')) {
                final authUser = FirebaseAuth.instance.currentUser;
                if (authUser != null && authUser.displayName != null && authUser.displayName!.trim().isNotEmpty) {
                  name = authUser.displayName!.trim();
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
                            Text(name, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        Text(
                          _getPageSubtitle(viewModel.selectedIndex),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
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
                        style: const TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold)
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

  String _getPageSubtitle(int index) {
    switch (index) {
      case 0:
        return 'Dashboard Overview';
      case 1:
        return 'Students';
      case 2:
        return 'Drivers';
      case 3:
        return 'Admin Management';
      case 4:
        return 'Live Bus Tracking';
      case 5:
        return 'Route Planning';
      case 6:
        return 'Gender Config';
      case 7:
        return 'Trip History';
      case 8:
        return 'Notifications';
      case 9:
        return 'Support Center';
      case 10:
        return 'Settings';
      case 11:
        return 'Bus Schedules';
      case 12:
        return 'Emergency SOS';
      default:
        return 'Admin Panel';
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
