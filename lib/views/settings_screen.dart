import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';
import 'package:unitransit_admin/view_models/app_settings_view_model.dart';
import 'package:unitransit_admin/core/utils/animations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _visionController = TextEditingController();
  final TextEditingController _versionController = TextEditingController();
  final TextEditingController _universityController = TextEditingController();
  final TextEditingController _appNameController = TextEditingController();
  final TextEditingController _appTaglineController = TextEditingController();
  final TextEditingController _visionHeaderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _visionController.dispose();
    _versionController.dispose();
    _universityController.dispose();
    _appNameController.dispose();
    _appTaglineController.dispose();
    _visionHeaderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    
    return Consumer<AppSettingsViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.appInfo != null) {
          if (_visionController.text.isEmpty) _visionController.text = viewModel.appInfo!.vision;
          if (_versionController.text.isEmpty) _versionController.text = viewModel.appInfo!.version;
          if (_universityController.text.isEmpty) _universityController.text = viewModel.appInfo!.university;
          if (_appNameController.text.isEmpty) _appNameController.text = viewModel.appInfo!.appName;
          if (_appTaglineController.text.isEmpty) _appTaglineController.text = viewModel.appInfo!.appTagline;
          if (_visionHeaderController.text.isEmpty) _visionHeaderController.text = viewModel.appInfo!.visionHeader;
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: FadeInSlide(
            duration: const Duration(milliseconds: 600),
            child: Padding(
              padding: EdgeInsets.all(AppResponsiveUtil.isMobile(context) ? 16 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, textTheme),
                  const SizedBox(height: 32),
                  _buildTabBar(textTheme),
                  const SizedBox(height: 24),
                  
                  if (viewModel.isLoading)
                    const Expanded(child: Center(child: CircularProgressIndicator(color: AppColors.primaryNavy)))
                  else
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAboutTab(context, viewModel, textTheme),
                          _buildConfigTab(context, viewModel, textTheme),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  _buildActionButtons(context, viewModel),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, TextTheme textTheme) {
    return FadeInSlide(
      direction: FadeInDirection.leftToRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primaryNavy.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.settings_suggest_rounded, color: AppColors.primaryNavy, size: 28),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin Settings', style: textTheme.displayMedium),
                  Text('Complete control over Mobile App and Admin Dashboard branding', style: textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(TextTheme textTheme) {
    return FadeInSlide(
      direction: FadeInDirection.leftToRight,
      delay: const Duration(milliseconds: 100),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent,
          isScrollable: AppResponsiveUtil.isMobile(context),
          tabAlignment: AppResponsiveUtil.isMobile(context) ? TabAlignment.start : null,
          tabs: const [
            Tab(text: 'App Content', icon: Icon(Icons.info_outline_rounded, size: 20)),
            Tab(text: 'Design System', icon: Icon(Icons.palette_outlined, size: 20)),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutTab(BuildContext context, AppSettingsViewModel viewModel, TextTheme textTheme) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          FadeInSlide(
            direction: FadeInDirection.bottomToTop,
            delay: const Duration(milliseconds: 200),
            child: _buildSectionCard(
              context, title: 'App Identity', subtitle: 'Global branding and naming.', icon: Icons.badge_rounded, textTheme: textTheme,
              child: Column(
                children: [
                  Center(child: _buildLogoPicker(viewModel, textTheme)),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(child: _buildCustomField('App Name', _appNameController, Icons.label_rounded, textTheme)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildCustomField('Version', _versionController, Icons.numbers_rounded, textTheme)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildCustomField('App Tagline', _appTaglineController, Icons.auto_fix_high_rounded, textTheme),
                  const SizedBox(height: 20),
                  _buildCustomField('University Name', _universityController, Icons.school_rounded, textTheme),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FadeInSlide(
            direction: FadeInDirection.bottomToTop,
            delay: const Duration(milliseconds: 300),
            child: _buildSectionCard(
              context, title: 'Vision & Team', subtitle: 'Project mission and contributors.', icon: Icons.groups_rounded, textTheme: textTheme,
              child: Column(
                children: [
                  _buildCustomField('Section Title', _visionHeaderController, Icons.title_rounded, textTheme),
                  const SizedBox(height: 20),
                  _buildCustomField('Vision Statement', _visionController, Icons.description_rounded, textTheme, maxLines: 5),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Divider()),
                  _buildContributorsList(viewModel, textTheme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigTab(BuildContext context, AppSettingsViewModel viewModel, TextTheme textTheme) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // 📱 MOBILE APP DESIGN SYSTEM
          FadeInSlide(
            direction: FadeInDirection.bottomToTop,
            delay: const Duration(milliseconds: 200),
            child: Column(
              children: [
                _buildPlatformHeader(context, '📱 MOBILE APP DESIGN SYSTEM', textTheme),
                const SizedBox(height: 16),
                _buildSectionCard(
                  context, title: 'Mobile Colors', subtitle: 'Branding and Interface for Mobile.', icon: Icons.phone_android_rounded, textTheme: textTheme,
                  child: Column(
                    children: [
                      _buildColorPickerRow(context, 'App Primary', 'Main branding', viewModel.appPrimaryColor, (c) => viewModel.setAppPrimaryColor(_colorToHex(c)), textTheme),
                      const Divider(height: 32),
                      _buildColorPickerRow(context, 'App Accent', 'Highlights', viewModel.appAccentColor, (c) => viewModel.setAppAccentColor(_colorToHex(c)), textTheme),
                      const Divider(height: 32),
                      _buildColorPickerRow(context, 'App Background', 'Scaffold color', viewModel.appBackgroundColor, (c) => viewModel.setAppBackgroundColor(_colorToHex(c)), textTheme),
                      const Divider(height: 32),
                      _buildColorPickerRow(context, 'App Card', 'Container color', viewModel.appCardColor, (c) => viewModel.setAppCardColor(_colorToHex(c)), textTheme),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FadeInSlide(
            direction: FadeInDirection.bottomToTop,
            delay: const Duration(milliseconds: 300),
            child: _buildSectionCard(
              context, title: 'Mobile Typography', subtitle: 'Text colors for Mobile.', icon: Icons.text_fields_rounded, textTheme: textTheme,
              child: Column(
                children: [
                  _buildColorPickerRow(context, 'App Text Primary', 'Headings', viewModel.appTextPrimaryColor, (c) => viewModel.setAppTextPrimaryColor(_colorToHex(c)), textTheme),
                  const Divider(height: 32),
                  _buildColorPickerRow(context, 'App Text Secondary', 'Subtitles', viewModel.appTextSecondaryColor, (c) => viewModel.setAppTextSecondaryColor(_colorToHex(c)), textTheme),
                ],
              ),
            ),
          ),

          const SizedBox(height: 48),
          
          // 🖥️ ADMIN PANEL DESIGN SYSTEM
          FadeInSlide(
            direction: FadeInDirection.bottomToTop,
            delay: const Duration(milliseconds: 400),
            child: Column(
              children: [
                _buildPlatformHeader(context, '🖥️ ADMIN PANEL DESIGN SYSTEM', textTheme),
                const SizedBox(height: 16),
                _buildSectionCard(
                  context, title: 'Admin Colors', subtitle: 'Branding and Interface for Dashboard.', icon: Icons.desktop_windows_rounded, textTheme: textTheme,
                  child: Column(
                    children: [
                      _buildColorPickerRow(context, 'Admin Primary', 'Main branding', viewModel.adminPrimaryColor, (c) => viewModel.setAdminPrimaryColor(_colorToHex(c)), textTheme),
                      const Divider(height: 32),
                      _buildColorPickerRow(context, 'Admin Accent', 'Highlights', viewModel.adminAccentColor, (c) => viewModel.setAdminAccentColor(_colorToHex(c)), textTheme),
                      const Divider(height: 32),
                      _buildColorPickerRow(context, 'Admin Background', 'Scaffold color', viewModel.adminBackgroundColor, (c) => viewModel.setAdminBackgroundColor(_colorToHex(c)), textTheme),
                      const Divider(height: 32),
                      _buildColorPickerRow(context, 'Admin Card', 'Container color', viewModel.adminCardColor, (c) => viewModel.setAdminCardColor(_colorToHex(c)), textTheme),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FadeInSlide(
            direction: FadeInDirection.bottomToTop,
            delay: const Duration(milliseconds: 500),
            child: _buildSectionCard(
              context, title: 'Admin Typography', subtitle: 'Text colors for Dashboard.', icon: Icons.text_format_rounded, textTheme: textTheme,
              child: Column(
                children: [
                  _buildColorPickerRow(context, 'Admin Text Primary', 'Headings', viewModel.adminTextPrimaryColor, (c) => viewModel.setAdminTextPrimaryColor(_colorToHex(c)), textTheme),
                  const Divider(height: 32),
                  _buildColorPickerRow(context, 'Admin Text Secondary', 'Subtitles', viewModel.adminTextSecondaryColor, (c) => viewModel.setAdminTextSecondaryColor(_colorToHex(c)), textTheme),
                ],
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildPlatformHeader(BuildContext context, String title, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: AppColors.primaryNavy.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primaryNavy.withValues(alpha: 0.1))),
      child: Text(title, style: textTheme.labelLarge?.copyWith(color: AppColors.primaryNavy, letterSpacing: 2, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildColorPickerRow(BuildContext context, String title, String subtitle, String hex, Function(Color) onColor, TextTheme textTheme) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => _showColorPickerDialog(context, _hexToColor(hex), onColor),
          child: Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: _hexToColor(hex), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight, width: 2), boxShadow: [BoxShadow(color: _hexToColor(hex).withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))]),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: textTheme.titleMedium), Text(subtitle, style: textTheme.bodySmall)]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(8)),
          child: Text(hex.toUpperCase(), style: textTheme.labelLarge?.copyWith(color: AppColors.primaryNavy, fontFamily: 'monospace')),
        ),
      ],
    );
  }

  void _showColorPickerDialog(BuildContext context, Color initialColor, Function(Color) onColorChanged) {
    Color pickedColor = initialColor;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.colorize_rounded, color: AppColors.primaryNavy),
            const SizedBox(width: 12),
            const Text('Select Color'),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ColorPicker(
                pickerColor: initialColor,
                onColorChanged: (color) => pickedColor = color,
                pickerAreaHeightPercent: 0.7,
                enableAlpha: false,
                displayThumbColor: true,
                showLabel: true,
                labelTypes: const [ColorLabelType.hex],
                pickerAreaBorderRadius: BorderRadius.circular(16),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
          ElevatedButton(child: const Text('Select'), onPressed: () { onColorChanged(pickedColor); Navigator.of(context).pop(); }),
        ],
      ),
    );
  }

  String _colorToHex(Color color) => '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  Color _hexToColor(String hex) => Color(int.parse(hex.replaceFirst('#', '0xFF')));

  Widget _buildSectionCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required TextTheme textTheme, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))], border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.primaryNavy.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 20, color: AppColors.primaryNavy)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: textTheme.titleMedium), Text(subtitle, style: textTheme.bodySmall)])),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(24), child: child),
        ],
      ),
    );
  }

  Widget _buildLogoPicker(AppSettingsViewModel viewModel, TextTheme textTheme) {
    return GestureDetector(
      onTap: viewModel.updateAppLogo,
      child: Column(
        children: [
          Stack(
            children: [
              Container(width: 120, height: 120, decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderLight, width: 2)), child: ClipRRect(borderRadius: BorderRadius.circular(22), child: _buildLogoImage(viewModel))),
              Positioned(right: -4, bottom: -4, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primaryNavy, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3)), child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white))),
            ],
          ),
          const SizedBox(height: 12),
          Text('BRAND LOGO', style: textTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _buildLogoImage(AppSettingsViewModel viewModel) {
    if (viewModel.pickedImageBytes != null) return Image.memory(viewModel.pickedImageBytes!, fit: BoxFit.contain);
    if (viewModel.appInfo?.appLogoUrl != null && viewModel.appInfo!.appLogoUrl.isNotEmpty) {
      return Image.network(viewModel.appInfo!.appLogoUrl, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_outlined, color: Colors.red));
    }
    return const Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.textSecondary);
  }

  Widget _buildCustomField(String label, TextEditingController controller, IconData icon, TextTheme textTheme, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: textTheme.labelSmall),
        const SizedBox(height: 8),
        TextField(
          controller: controller, maxLines: maxLines, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          decoration: InputDecoration(isDense: true, prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), filled: true, fillColor: AppColors.backgroundLight.withValues(alpha: 0.5), hintText: 'Enter $label...'),
        ),
      ],
    );
  }

  Widget _buildContributorsList(AppSettingsViewModel viewModel, TextTheme textTheme) {
    final contributors = viewModel.appInfo?.contributors ?? [];
    bool isMobile = AppResponsiveUtil.isMobile(context);
    return Column(
      children: [
        if (contributors.isEmpty) const Text('No team members added.', style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.textSecondary))
        else Wrap(
            spacing: 16, runSpacing: 16,
            children: List.generate(contributors.length, (index) {
              final contributor = contributors[index];
              return _ContributorCard(index: index, contributor: contributor, viewModel: viewModel, textTheme: textTheme, isMobile: isMobile);
            }),
          ),
        const SizedBox(height: 24),
        OutlinedButton.icon(onPressed: viewModel.addContributor, icon: const Icon(Icons.add_rounded), label: const Text('Add Team Member'),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), side: const BorderSide(color: AppColors.primaryNavy), foregroundColor: AppColors.primaryNavy)),
      ],
    );
  }


  Widget _buildActionButtons(BuildContext context, AppSettingsViewModel viewModel) {
    return FadeInSlide(
      direction: FadeInDirection.bottomToTop,
      delay: const Duration(milliseconds: 600),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                viewModel.saveAppInfo(
                  appName: _appNameController.text,
                  appTagline: _appTaglineController.text,
                  visionHeader: _visionHeaderController.text,
                  vision: _visionController.text,
                  version: _versionController.text,
                  university: _universityController.text,
                );
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Design systems updated independently!'), behavior: SnackBarBehavior.floating, backgroundColor: AppColors.primaryNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
              },
              icon: const Icon(Icons.sync_rounded),
              label: const Text('Save & Synchronize'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20), elevation: 4, shadowColor: AppColors.primaryNavy.withValues(alpha: 0.3)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContributorCard extends StatefulWidget {
  final int index;
  final dynamic contributor;
  final AppSettingsViewModel viewModel;
  final TextTheme textTheme;
  final bool isMobile;
  const _ContributorCard({required this.index, required this.contributor, required this.viewModel, required this.textTheme, required this.isMobile});

  @override
  State<_ContributorCard> createState() => _ContributorCardState();
}

class _ContributorCardState extends State<_ContributorCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final contributor = widget.contributor;
    final viewModel = widget.viewModel;
    final index = widget.index;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.isMobile ? double.infinity : (MediaQuery.of(context).size.width / 2) - 80,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.primaryNavy.withValues(alpha: 0.02) : AppColors.backgroundLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _isHovered ? AppColors.primaryNavy.withValues(alpha: 0.2) : AppColors.borderLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                AnimatedScale(
                  scale: _isHovered ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: CircleAvatar(radius: 14, backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.1), child: Text('${index + 1}', style: const TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold, fontSize: 10))),
                ),
                const Spacer(),
                IconButton(onPressed: () => viewModel.removeContributor(index), icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildSmallField('Name', contributor.name, widget.textTheme, (val) => viewModel.updateContributor(index, val, contributor.role, contributor.subtitle))),
                const SizedBox(width: 8),
                Expanded(child: _buildSmallField('Role', contributor.role, widget.textTheme, (val) => viewModel.updateContributor(index, contributor.name, val, contributor.subtitle))),
              ],
            ),
            const SizedBox(height: 8),
            _buildSmallField('Details', contributor.subtitle, widget.textTheme, (val) => viewModel.updateContributor(index, contributor.name, contributor.role, val), maxLines: 5),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallField(String label, String initialValue, TextTheme textTheme, Function(String) onChanged, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: textTheme.labelSmall),
        const SizedBox(height: 6),
        TextFormField(initialValue: initialValue, onChanged: onChanged, maxLines: maxLines, style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.textDark),
          decoration: InputDecoration(isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), filled: true, fillColor: Colors.white)),
      ],
    );
  }
}
