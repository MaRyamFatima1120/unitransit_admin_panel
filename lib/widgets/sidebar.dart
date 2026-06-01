import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/constants/app_assets.dart';
import 'package:unitransit_admin/view_models/dashboard_view_model.dart';
import 'package:unitransit_admin/view_models/login_view_model.dart';
import 'package:unitransit_admin/view_models/app_settings_view_model.dart';
import 'package:unitransit_admin/views/login_screen.dart';

class Sidebar extends StatelessWidget {
  final bool isCollapsed;
  const Sidebar({super.key, this.isCollapsed = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final accentColor = theme.colorScheme.secondary;
    final loginVM = context.watch<LoginViewModel>();
    final isSuperAdmin = loginVM.isSuperAdmin;
    final settingsVM = context.watch<AppSettingsViewModel>();
    final sidebarColor = Color(int.parse(settingsVM.adminSidebarColor.replaceFirst('#', '0xFF')));

    return Container(
      width: isCollapsed ? 80 : 280,
      height: double.infinity,
      decoration: BoxDecoration(
        color: sidebarColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
        border: const Border(right: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Logo Section
          _buildLogoSection(),
          const SizedBox(height: 24),
          // Navigation Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 12 : 16, vertical: 8),
              children: [
                if (isSuperAdmin ||
                    [
                      'All',
                      'Admin',
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
                      'Admin',
                      'Fleet Manager',
                      'Support Admin',
                      'System Monitor',
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
                      'Admin',
                      'Fleet Manager',
                      'Support Admin',
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
                    [
                      'All',
                      'Admin',
                      'Fleet Manager',
                      'Support Admin',
                      'System Monitor',
                    ].contains(loginVM.subRole))
                  _buildMenuItem(
                    context,
                    14,
                    Icons.directions_bus_filled_rounded,
                    'Buses',
                    primaryColor,
                    accentColor,
                  ),

                if (isSuperAdmin ||
                    [
                      'All',
                      'Admin',
                      'Fleet Manager',
                      'Support Admin',
                      'System Monitor',
                    ].contains(loginVM.subRole))
                  _buildMenuItem(
                    context,
                    13,
                    Icons.add_road_rounded,
                    'Assign Routes',
                    primaryColor,
                    accentColor,
                  ),

                if (isSuperAdmin ||
                    [
                      'All',
                      'Admin',
                      'Fleet Manager',
                      'Support Admin',
                      'System Monitor',
                    ].contains(loginVM.subRole))
                  _buildMenuItem(
                    context,
                    5,
                    Icons.map_rounded,
                    'Route Planning',
                    primaryColor,
                    accentColor,
                  ),

                if (isSuperAdmin ||
                    [
                      'All',
                      'Admin',
                      'Fleet Manager',
                      'Support Admin',
                      'System Monitor',
                    ].contains(loginVM.subRole))
                  _buildMenuItem(
                    context,
                    11,
                    Icons.calendar_today_rounded,
                    'Bus Schedules',
                    primaryColor,
                    accentColor,
                  ),

                if (isSuperAdmin)
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
                      'Admin',
                      'Fleet Manager',
                      'Support Admin',
                      'System Monitor',
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
                      'Admin',
                      'Fleet Manager',
                      'Support Admin',
                      'System Monitor',
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
                      'Admin',
                      'Fleet Manager',
                      'Support Admin',
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
                      'Admin',
                      'Fleet Manager',
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

                if (isSuperAdmin)
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
                      'Admin',
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
                  if (isCollapsed)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: Colors.white24, height: 1),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Text(
                        'SYSTEM ADMINISTRATION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white38,
                          letterSpacing: 1.5,
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
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.05),
            border: Border.all(color: Colors.white12),
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                AppAssets.unitransitLogo,
                width: isCollapsed ? 44 : 70,
                height: isCollapsed ? 44 : 70,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        if (!isCollapsed) ...[
          const SizedBox(height: 12),
          const Text(
            'UNI-TRANSIT',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 1.5,
            ),
          ),
          Text(
            'ADMIN PANEL',
            style: TextStyle(
              color: AppColors.accentAmber.withOpacity(0.8),
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24, top: 12),
        child: IconButton(
          onPressed: () => _handleLogout(context),
          icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          style: IconButton.styleFrom(
            backgroundColor: Colors.redAccent.withOpacity(0.1),
            padding: const EdgeInsets.all(12),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () => _handleLogout(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.redAccent.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
              const SizedBox(width: 12),
              const Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: AppColors.cardWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Logout'),
            content: const Text('Are you sure you want to sign out of the portal?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Stay', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Logout'),
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
    
    final itemAccentColor = index == 12 ? Colors.redAccent : AppColors.accentAmber;
    final iconColor = isActive ? itemAccentColor : Colors.white.withOpacity(0.5);
    final textColor = isActive ? Colors.white : Colors.white.withOpacity(0.6);

    int badgeCount = 0;
    Color badgeBg = Colors.redAccent;
    if (index == 12 && viewModel.activeEmergencyAlerts > 0) {
      badgeCount = viewModel.activeEmergencyAlerts;
    } else if (index == 8 && viewModel.unreadNotificationsCount > 0) {
      badgeCount = viewModel.unreadNotificationsCount;
    } else if (index == 9 && viewModel.pendingAlerts > 0) {
      badgeCount = viewModel.pendingAlerts;
      badgeBg = Colors.orange;
    }

    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Tooltip(
          message: title,
          child: InkWell(
            onTap: () {
              viewModel.setSelectedIndex(index);
              if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
            },
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(icon, color: iconColor, size: 22),
                  if (badgeCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: badgeBg, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () {
          viewModel.setSelectedIndex(index);
          if (Scaffold.of(context).isDrawerOpen) Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              if (badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              if (isActive)
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(color: itemAccentColor, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}