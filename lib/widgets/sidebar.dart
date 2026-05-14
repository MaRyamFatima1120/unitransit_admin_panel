import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/view_models/dashboard_view_model.dart';
import 'package:unitransit_admin/views/login_screen.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
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
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryNavy, Color(0xFF4F46E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryNavy.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Uni-Transit',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Admin Panel',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
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
                _buildMenuItem(context, 0, Icons.dashboard_rounded, 'Dashboard'),
                _buildMenuItem(context, 1, Icons.people_alt_rounded, 'Students'),
                _buildMenuItem(context, 2, Icons.drive_eta_rounded, 'Drivers'),
                _buildMenuItem(context, 3, Icons.directions_bus_rounded, 'Fleet Operations'),
                _buildMenuItem(context, 4, Icons.map_rounded, 'Route Planning'),
                _buildMenuItem(context, 5, Icons.bar_chart_rounded, 'Performance Reports'),
                _buildMenuItem(context, 6, Icons.history_rounded, 'Trip History'),
                _buildMenuItem(context, 7, Icons.notifications_active_rounded, 'Notifications'),
                _buildMenuItem(context, 8, Icons.support_agent_rounded, 'Support Center'),
                _buildMenuItem(context, 9, Icons.settings_rounded, 'Settings'),
              ],
            ),
          ),
          // Footer / Logout
          Padding(
            padding: const EdgeInsets.all(24),
            child: InkWell(
              onTap: () {
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
                          Navigator.pop(context); // Close dialog
                          await FirebaseAuth.instance.signOut();
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
              },
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
                    Icon(Icons.arrow_forward_ios_rounded, color: Colors.redAccent.withValues(alpha: 0.3), size: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildMenuItem(BuildContext context, int index, IconData icon, String title) {
    final viewModel = context.watch<DashboardViewModel>();
    final isActive = viewModel.selectedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryNavy.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isActive ? Border.all(color: AppColors.primaryNavy.withValues(alpha: 0.3)) : null,
      ),
      child: ListTile(
        onTap: () {
          viewModel.setSelectedIndex(index);
          // Auto-close drawer on mobile
          if (Scaffold.of(context).isDrawerOpen) {
            Navigator.pop(context);
          }
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(
          icon,
          color: isActive ? AppColors.accentAmber : AppColors.textSecondary,
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
        trailing: isActive ? Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.accentAmber,
            shape: BoxShape.circle,
          ),
        ) : null,
      ),
    );
  }
}
