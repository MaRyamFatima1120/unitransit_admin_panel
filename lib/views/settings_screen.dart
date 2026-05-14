import 'package:flutter/material.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppResponsiveUtil.isMobile(context) ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              fontSize: AppResponsiveUtil.isMobile(context) ? 24 : null,
            ),
          ),
          const SizedBox(height: 4),
          const Text('Configure system preferences and admin profile.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),
          _buildSettingsSection(
            'General Settings',
            [
              _buildSettingItem(Icons.language_rounded, 'Language', 'English (United States)'),
              _buildSettingItem(Icons.dark_mode_outlined, 'Dark Mode', 'Off'),
              _buildSettingItem(Icons.notifications_none_rounded, 'System Notifications', 'Enabled'),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            'Security',
            [
              _buildSettingItem(Icons.lock_outline_rounded, 'Change Password', 'Update your password regularly'),
              _buildSettingItem(Icons.verified_user_outlined, 'Two-Factor Authentication', 'Not set up'),
              _buildSettingItem(Icons.history_rounded, 'Login History', 'View your recent sessions'),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            'Admin Profile',
            [
              _buildSettingItem(Icons.person_outline_rounded, 'Profile Information', 'Name, Email, Phone'),
              _buildSettingItem(Icons.admin_panel_settings_outlined, 'Admin Permissions', 'Full Access'),
            ],
          ),
          const SizedBox(height: 40),
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text('Version 1.0.0 (Build 2026)', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryNavy)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.textDark, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
      onTap: () {},
    );
  }
}
