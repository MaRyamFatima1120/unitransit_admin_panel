import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';
import 'package:unitransit_admin/view_models/gender_config_view_model.dart';
import 'package:unitransit_admin/view_models/login_view_model.dart';
import 'package:unitransit_admin/core/utils/animations.dart';

class GenderConfigScreen extends StatefulWidget {
  const GenderConfigScreen({super.key});

  @override
  State<GenderConfigScreen> createState() => _GenderConfigScreenState();
}

class _GenderConfigScreenState extends State<GenderConfigScreen> {
  final _nameController = TextEditingController();
  Color _selectedColor = AppColors.primaryNavy;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showAddDialog(BuildContext context, [String? oldName, Color? oldColor]) {
    if (oldName != null) {
      _nameController.text = oldName;
      _selectedColor = oldColor ?? AppColors.primaryNavy;
    } else {
      _nameController.clear();
      _selectedColor = AppColors.primaryNavy;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: 500,
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        oldName == null ? 'New Category' : 'Edit Category',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        style: IconButton.styleFrom(backgroundColor: AppColors.backgroundLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // PREVIEW SECTION
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      children: [
                        const Text('STUDENT APP PREVIEW', 
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _selectedColor.withValues(alpha: 0.5), width: 1.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person_rounded, color: _selectedColor, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                _nameController.text.isEmpty ? 'Category' : _nameController.text,
                                style: TextStyle(color: _selectedColor, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  const Text('Category Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    onChanged: (v) => setDialogState(() {}),
                    decoration: InputDecoration(
                      hintText: 'e.g. Staff',
                      filled: true,
                      fillColor: AppColors.backgroundLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  const Text('Brand Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 12),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _colorDot(setDialogState, Colors.blue),
                      _colorDot(setDialogState, Colors.pink),
                      _colorDot(setDialogState, Colors.green),
                      _colorDot(setDialogState, Colors.orange),
                      _colorDot(setDialogState, AppColors.primaryNavy),
                      GestureDetector(
                        onTap: () => _showDetailedColorPicker(context, setDialogState),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.borderLight, width: 2)),
                          child: const Icon(Icons.colorize_rounded, size: 14, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_nameController.text.isNotEmpty) {
                          await context.read<GenderConfigViewModel>().saveGender(
                            _nameController.text.trim(),
                            _selectedColor,
                          );
                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Configuration', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _colorDot(StateSetter setDialogState, Color color) {
    bool isSelected = _selectedColor.value == color.value;
    return GestureDetector(
      onTap: () => setDialogState(() => _selectedColor = color),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
      ),
    );
  }

  void _showDetailedColorPicker(BuildContext context, StateSetter setDialogState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setDialogState(() => _selectedColor = color);
            },
            pickerAreaHeightPercent: 0.8,
            enableAlpha: false,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Select')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GenderConfigViewModel>();
    final isSuperAdmin = context.watch<LoginViewModel>().isSuperAdmin;
    final isDesktop = AppResponsiveUtil.isDesktop(context);
    final isMobile = AppResponsiveUtil.isMobile(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FadeInSlide(
        duration: const Duration(milliseconds: 600),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, isMobile, isSuperAdmin),
              const SizedBox(height: 32),
              Expanded(
                child: viewModel.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : viewModel.genderConfigs.isEmpty
                        ? _buildEmptyState()
                        : _buildGenderGrid(viewModel, isDesktop, isSuperAdmin),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile, bool isSuperAdmin) {
    return FadeInSlide(
      direction: FadeInDirection.leftToRight,
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryNavy.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.category_rounded, color: AppColors.primaryNavy, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gender Config',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark, letterSpacing: -0.5),
                  ),
                  if (!isMobile)
                    const Text('Manage categories and colors.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ],
          ),
          FadeInSlide(
            direction: FadeInDirection.rightToLeft,
            child: ElevatedButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Category'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeInSlide(
        direction: FadeInDirection.bottomToTop,
        child: Text('No categories found.', style: TextStyle(color: AppColors.textSecondary))
      ),
    );
  }

  Widget _buildGenderGrid(GenderConfigViewModel viewModel, bool isDesktop, bool isSuperAdmin) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 3 : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 160,
      ),
      itemCount: viewModel.genderConfigs.length,
      itemBuilder: (context, index) {
        String name = viewModel.genderConfigs.keys.elementAt(index);
        String hexColor = viewModel.genderConfigs.values.elementAt(index);
        Color color = Color(int.parse(hexColor.replaceFirst('#', '0xFF')));

        return FadeInSlide(
          direction: FadeInDirection.bottomToTop,
          delay: Duration(milliseconds: 100 * index),
          child: _GenderConfigCard(
            name: name,
            hexColor: hexColor,
            color: color,
            isSuperAdmin: isSuperAdmin,
            onEdit: () => _showAddDialog(context, name, color),
            onDelete: () => _showDeleteConfirm(context, name),
          ),
        );
      },
    );
  }
}

class _GenderConfigCard extends StatefulWidget {
  final String name;
  final String hexColor;
  final Color color;
  final bool isSuperAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GenderConfigCard({
    required this.name,
    required this.hexColor,
    required this.color,
    required this.isSuperAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_GenderConfigCard> createState() => _GenderConfigCardState();
}

class _GenderConfigCardState extends State<_GenderConfigCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _isHovered ? widget.color.withValues(alpha: 0.5) : AppColors.borderLight),
          boxShadow: _isHovered ? [
            BoxShadow(color: widget.color.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 8)),
          ] : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedScale(
                    scale: _isHovered ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: widget.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.person_rounded, color: widget.color, size: 20),
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') widget.onEdit();
                      if (v == 'delete') widget.onDelete();
                    },
                    icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textSecondary),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              Text(widget.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _isHovered ? widget.color : AppColors.textDark)),
              Text(widget.hexColor, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

  void _showDeleteConfirm(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete?'),
        content: Text('Remove "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () { context.read<GenderConfigViewModel>().deleteGender(name); Navigator.pop(context); }, child: const Text('Delete')),
        ],
      ),
    );
  }

