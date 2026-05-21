import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 28),
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
                _buildMenuItem(context, 0, Icons.dashboard_rounded, 'Dashboard', primaryColor, accentColor),
                _buildMenuItem(context, 1, Icons.people_alt_rounded, 'Students', primaryColor, accentColor),
                _buildMenuItem(context, 2, Icons.drive_eta_rounded, 'Drivers', primaryColor, accentColor),
                _buildMenuItem(context, 13, Icons.add_road_rounded, 'Assign Routes', primaryColor, accentColor),
                
                // Super Admin Only: Admins Management (Index 3)
                if (isSuperAdmin) ...[
                  _buildMenuItem(context, 3, Icons.admin_panel_settings_rounded, 'Manage Admins', primaryColor, accentColor),
                ],
                
                _buildMenuItem(context, 5, Icons.map_rounded, 'Route Planning', primaryColor, accentColor),
                _buildMenuItem(context, 11, Icons.calendar_today_rounded, 'Bus Schedules', primaryColor, accentColor),
                
                // Gender Config (Index 6)
                _buildMenuItem(context, 6, Icons.category_rounded, 'Gender Config', primaryColor, accentColor),
                
                _buildMenuItem(context, 4, Icons.directions_bus_rounded, 'Live Bus Tracking', primaryColor, accentColor),
                _buildMenuItem(context, 12, Icons.warning_amber_rounded, 'Emergency SOS', primaryColor, Colors.redAccent),
                
                _buildMenuItem(context, 7, Icons.history_rounded, 'Trip History', primaryColor, accentColor),
                _buildMenuItem(context, 8, Icons.notifications_active_rounded, 'Notifications', primaryColor, accentColor),
                _buildMenuItem(context, 9, Icons.support_agent_rounded, 'Support Center', primaryColor, accentColor),
                
                _buildMenuItem(context, 10, Icons.settings_rounded, 'Settings', primaryColor, accentColor),
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
                    const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
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
                    Icon(Icons.arrow_forward_ios_rounded, color: Colors.redAccent.withOpacity(0.3), size: 12),
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
      builder: (context) => AlertDialog(
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
              await context.read<LoginViewModel>().logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, int index, IconData icon, String title, Color primaryColor, Color accentColor) {
    final viewModel = context.watch<DashboardViewModel>();
    final isActive = viewModel.selectedIndex == index;
    final itemAccentColor = index == 12 ? Colors.redAccent : accentColor;
    final itemBgColor = isActive 
        ? (index == 12 ? Colors.redAccent.withOpacity(0.12) : primaryColor.withOpacity(0.12))
        : Colors.transparent;
    final itemBorderColor = isActive
        ? (index == 12 ? Colors.redAccent.withOpacity(0.2) : primaryColor.withOpacity(0.2))
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: itemBgColor,
        borderRadius: BorderRadius.circular(12),
        border: itemBorderColor != null ? Border.all(color: itemBorderColor) : null,
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
          color: index == 12 ? Colors.redAccent : (isActive ? itemAccentColor : AppColors.textSecondary),
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
        trailing: isActive 
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                : (index == 8 && viewModel.notifications.length > 0)
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          viewModel.notifications.length.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : (index == 9 && viewModel.pendingAlerts > 0)
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
