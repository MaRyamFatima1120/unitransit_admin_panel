import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/constants/app_assets.dart';
import 'package:unitransit_admin/view_models/dashboard_view_model.dart';
import 'package:unitransit_admin/view_models/login_view_model.dart';
import 'package:unitransit_admin/views/login_screen.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final accentColor = theme.colorScheme.secondary;
    final loginVM = context.watch<LoginViewModel>();
    final isSuperAdmin = loginVM.isSuperAdmin;

    return Container(
      width: 280,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(right: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 48),
          // Logo Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    AppAssets.unitransitLogo,
                    width: 110,
                    height: 110,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Uni-Transit',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Admin Panel',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                if (isSuperAdmin ||
                    [
                      'All',
                      'Fleet Manager',
                      'Support Admin',
                      'System Monitor',
                    ].contains(loginVM.subRole))
                  _buildMenuItem(
                    context,
                    0,
                    Icons.dashboard_rounded,
                    'Dashboard',
                    primaryColor,
                    accentColor,
                  ),

                if (isSuperAdmin ||
                    [
                      'All',
                      'System Monitor',
                      'Support Admin',
                    ].contains(loginVM.subRole))
                  _buildMenuItem(
                    context,
                    1,
                    Icons.people_alt_rounded,
                    'Students',
                    primaryColor,
                    accentColor,
                  ),

                if (isSuperAdmin ||
                    [
                      'All',
                      'Fleet Manager',
                      'System Monitor',
                    ].contains(loginVM.subRole))
                  _buildMenuItem(
                    context,
                    2,
                    Icons.drive_eta_rounded,
                    'Drivers',
                    primaryColor,
                    accentColor,
                  ),

                if (isSuperAdmin ||
                    ['All', 'Fleet Manager'].contains(loginVM.subRole))
                  _buildMenuItem(
                    context,
                    14,
                    Icons.directions_bus_filled_rounded,
                    'Buses',
                    primaryColor,
                    accentColor,
                  ),

                if (isSuperAdmin ||
                    ['All', 'Fleet Manager'].contains(loginVM.subRole))
                  _buildMenuItem(
                    context,
                    13,
                    Icons.add_road_rounded,
                    'Assign Routes',
                    primaryColor,
                    accentColor,
                  ),

                if (isSuperAdmin ||
                    ['All', 'Fleet Manager'].contains(loginVM.subRole))
                  _buildMenuItem(
                    context,
                    5,
                    Icons.map_rounded,
                    'Route Planning',
                    primaryColor,
                    accentColor,
                  ),

                if (isSuperAdmin ||
                    ['All', 'Fleet Manager'].contains(loginVM.subRole))
                  _buildMenuItem(
                    context,
                    11,
                    Icons.calendar_today_rounded,
                    'Bus Schedules',
                    primaryColor,
                    accentColor,
                  ),

                if (isSuperAdmin ||
                    ['All', 'System Monitor'].contains(loginVM.subRole))
                  _buildMenuItem(
                    context,
                    6,
                    Icons.category_rounded,
                    'Gender Config',
                    primaryColor,
                    accentColor,
                  ),

                if (isSuperAdmin ||
                    [
                      'All',
                      'Fleet Manager',
                      'System Monitor',
                      'Support Admin',
                    ].contains(loginVM.subRole))
                  _buildMenuItem(
                    context,
                    4,
                    Icons.directions_bus_rounded,
                    'Live Bus Tracking',
                    primaryColor,
                    accentColor,
                  ),

                if (isSuperAdmin ||
                    [
                      'All',
                      'Fleet Manager',
                      'System Monitor',
                      'Support Admin',
                    ].contains(loginVM.subRole))
                  _buildMenuItem(
                    context,
                    12,
                    Icons.warning_amber_rounded,
                    'Emergency SOS',
                    primaryColor,
                    Colors.redAccent,
                  ),

                if (isSuperAdmin ||
                    [
                      'All',
                      'Fleet Manager',
                      'System Monitor',
                    ].contains(loginVM.subRole))
                  _buildMenuItem(
                    context,
                    7,
                    Icons.history_rounded,
                    'Trip History',
                    primaryColor,
                    accentColor,
                  ),

                if (isSuperAdmin ||
                    [
                      'All',
                      'Support Admin',
                      'System Monitor',
                    ].contains(loginVM.subRole))
                  _buildMenuItem(
                    context,
                    8,
                    Icons.notifications_active_rounded,
                    'Notifications',
                    primaryColor,
                    accentColor,
                  ),

                if (isSuperAdmin ||
                    [
                      'All',
                      'Support Admin',
                      'System Monitor',
                    ].contains(loginVM.subRole))
                  _buildMenuItem(
                    context,
                    9,
                    Icons.support_agent_rounded,
                    'Support Center',
                    primaryColor,
                    accentColor,
                  ),

                if (isSuperAdmin ||
                    [
                      'All',
                      'Fleet Manager',
                      'Support Admin',
                      'System Monitor',
                    ].contains(loginVM.subRole))
                  _buildMenuItem(
                    context,
                    10,
                    Icons.settings_rounded,
                    'Settings',
                    primaryColor,
                    accentColor,
                  ),

                // Super Admin Only: Systems Management Section
                if (isSuperAdmin) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                    child: Text(
                      'SYSTEM ADMINISTRATION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    context,
                    3,
                    Icons.admin_panel_settings_rounded,
                    'Manage Admins',
                    primaryColor,
                    accentColor,
                  ),
                  _buildMenuItem(
                    context,
                    15,
                    Icons.assignment_rounded,
                    'Audit Logs',
                    primaryColor,
                    accentColor,
                  ),
                  _buildMenuItem(
                    context,
                    16,
                    Icons.analytics_rounded,
                    'Analytics & Reports',
                    primaryColor,
                    accentColor,
                  ),
                  _buildMenuItem(
                    context,
                    17,
                    Icons.app_settings_alt_rounded,
                    'App Control',
                    primaryColor,
                    accentColor,
                  ),
                  _buildMenuItem(
                    context,
                    18,
                    Icons.settings_suggest_rounded,
                    'Fleet Maintenance',
                    primaryColor,
                    accentColor,
                  ),
                  _buildMenuItem(
                    context,
                    19,
                    Icons.security_update_warning_rounded,
                    'Safety Alerts',
                    primaryColor,
                    accentColor,
                  ),
                ],
              ],
            ),
          ),
          // Footer / Logout
          Padding(
            padding: const EdgeInsets.all(24),
            child: InkWell(
              onTap: () => _handleLogout(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.logout_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.redAccent.withOpacity(0.3),
                      size: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  context.read<DashboardViewModel>().resetToDashboard();
                  await context.read<LoginViewModel>().logout();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    int index,
    IconData icon,
    String title,
    Color primaryColor,
    Color accentColor,
  ) {
    final viewModel = context.watch<DashboardViewModel>();
    final isActive = viewModel.selectedIndex == index;
    final itemAccentColor = index == 12 ? Colors.redAccent : accentColor;
    final itemBgColor =
        isActive
            ? (index == 12
                ? Colors.redAccent.withOpacity(0.12)
                : primaryColor.withOpacity(0.12))
            : Colors.transparent;
    final itemBorderColor =
        isActive
            ? (index == 12
                ? Colors.redAccent.withOpacity(0.2)
                : primaryColor.withOpacity(0.2))
            : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: itemBgColor,
        borderRadius: BorderRadius.circular(12),
        border:
            itemBorderColor != null ? Border.all(color: itemBorderColor) : null,
      ),
      child: ListTile(
        onTap: () {
          viewModel.setSelectedIndex(index);
          if (Scaffold.of(context).isDrawerOpen) {
            Navigator.pop(context);
          }
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          icon,
          color:
              index == 12
                  ? Colors.redAccent
                  : (isActive ? itemAccentColor : AppColors.textSecondary),
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? AppColors.textDark : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        trailing:
            isActive
                ? Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: itemAccentColor,
                    shape: BoxShape.circle,
                  ),
                )
                : (index == 12 && viewModel.activeEmergencyAlerts > 0)
                ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    viewModel.activeEmergencyAlerts.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                : (index == 8 && viewModel.unreadNotificationsCount > 0)
                ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    viewModel.unreadNotificationsCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                : (index == 9 && viewModel.pendingAlerts > 0)
                ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    viewModel.pendingAlerts.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                : null,
      ),
    );
  }
}
