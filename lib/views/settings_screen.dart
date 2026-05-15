import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';
import 'package:unitransit_admin/view_models/app_settings_view_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _visionController = TextEditingController();
  final TextEditingController _versionController = TextEditingController();
  final TextEditingController _universityController = TextEditingController();

  @override
  void dispose() {
    _visionController.dispose();
    _versionController.dispose();
    _universityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppSettingsViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.appInfo != null) {
          if (_visionController.text.isEmpty) _visionController.text = viewModel.appInfo!.vision;
          if (_versionController.text.isEmpty) _versionController.text = viewModel.appInfo!.version;
          if (_universityController.text.isEmpty) _universityController.text = viewModel.appInfo!.university;
        }

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
              const Text('Configure system preferences and app information.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 24),
              
              if (viewModel.isLoading)
                const Center(child: LinearProgressIndicator(color: AppColors.primaryNavy))
              else ...[
                _buildAboutAppSection(context, viewModel),
                const SizedBox(height: 32),
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
                  ],
                ),
              ],
              
              const SizedBox(height: 40),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Version ${viewModel.appInfo?.version ?? "1.0.0"}', 
                    style: const TextStyle(color: AppColors.textSecondary)
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAboutAppSection(BuildContext context, AppSettingsViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text('About App Information (Public)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryNavy)),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: viewModel.updateAppLogo,
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight,
                            borderRadius: BorderRadius.circular(16),
                            image: viewModel.appInfo?.appLogoUrl != null && viewModel.appInfo!.appLogoUrl.isNotEmpty
                                ? DecorationImage(image: NetworkImage(viewModel.appInfo!.appLogoUrl), fit: BoxFit.contain)
                                : null,
                          ),
                          child: viewModel.appInfo?.appLogoUrl == null || viewModel.appInfo!.appLogoUrl.isEmpty
                              ? const Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.textSecondary)
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: AppColors.primaryNavy, shape: BoxShape.circle),
                            child: const Icon(Icons.edit, size: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      children: [
                        _buildTextField('University Name', _universityController),
                        const SizedBox(height: 16),
                        _buildTextField('App Version', _versionController),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildTextField('Project Vision', _visionController, maxLines: 3),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    viewModel.saveAppInfo(
                      vision: _visionController.text,
                      version: _versionController.text,
                      university: _universityController.text,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('App Information updated successfully!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save App Information', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryNavy)),
            filled: true,
            fillColor: AppColors.backgroundLight.withOpacity(0.5),
          ),
        ),
      ],
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
