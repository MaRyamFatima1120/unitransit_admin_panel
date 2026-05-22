import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';
import 'package:intl/intl.dart';
import 'package:unitransit_admin/core/utils/animations.dart';

class AdminsManagementScreen extends StatefulWidget {
  const AdminsManagementScreen({super.key});

  @override
  State<AdminsManagementScreen> createState() => _AdminsManagementScreenState();
}

class _AdminsManagementScreenState extends State<AdminsManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isCreating = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsiveUtil.isMobile(context);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 32),
        _buildStatsRow(context),
        const SizedBox(height: 32),
        _buildSearchAndFilters(),
        const SizedBox(height: 24),
        if (isMobile)
          _buildAdminsList(isMobile: true)
        else
          Expanded(
            child: _buildAdminsList(isMobile: false),
          ),
      ],
    );

    return FadeInSlide(
      duration: const Duration(milliseconds: 600),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: isMobile
            ? SingleChildScrollView(child: content)
            : content,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        FadeInSlide(
          direction: FadeInDirection.leftToRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admins Management',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      fontSize: AppResponsiveUtil.isMobile(context) ? 24 : null,
                    ),
              ),
              const SizedBox(height: 4),
              const Text('Manage administrative access, roles and security.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
        FadeInSlide(
          direction: FadeInDirection.rightToLeft,
          child: ElevatedButton.icon(
            onPressed: () => _showAddAdminDialog(context),
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: const Text('Add New Admin'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final isMobile = AppResponsiveUtil.isMobile(context);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Admin').snapshots(),
      builder: (context, snapshot) {
        int total = snapshot.hasData ? snapshot.data!.docs.length : 0;
        if (isMobile) {
          return FadeInSlide(
            direction: FadeInDirection.bottomToTop,
            delay: const Duration(milliseconds: 200),
            child: Column(
              children: [
                _buildStatItem('Total Admins', total.toString(), Icons.admin_panel_settings_rounded, Colors.blue),
                const SizedBox(height: 12),
                _buildStatItem('Active Sessions', total.toString(), Icons.online_prediction_rounded, Colors.green),
              ],
            ),
          );
        }
        return FadeInSlide(
          direction: FadeInDirection.bottomToTop,
          delay: const Duration(milliseconds: 200),
          child: Row(
            children: [
              Expanded(child: _buildStatItem('Total Admins', total.toString(), Icons.admin_panel_settings_rounded, Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatItem('Active Sessions', total.toString(), Icons.online_prediction_rounded, Colors.green)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark), overflow: TextOverflow.ellipsis),
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return FadeInSlide(
      direction: FadeInDirection.bottomToTop,
      delay: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Search by name or email...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminsList({bool isMobile = false}) {
    return FadeInSlide(
      direction: FadeInDirection.bottomToTop,
      delay: const Duration(milliseconds: 400),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Admin').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: _buildEmptyState(),
              );
            }

            final admins = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['name'] ?? '').toString().toLowerCase();
              final email = (data['email'] ?? '').toString().toLowerCase();
              return name.contains(_searchQuery) || email.contains(_searchQuery);
            }).toList();

            if (admins.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: _buildEmptyState(isSearch: true),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: admins.length,
              shrinkWrap: isMobile,
              physics: isMobile ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
              separatorBuilder: (context, index) => Divider(height: 1, indent: isMobile ? 0 : 70, color: Colors.grey.withValues(alpha: 0.1)),
              itemBuilder: (context, index) {
                final admin = admins[index].data() as Map<String, dynamic>;
                return _AdminRow(
                  admin: admin,
                  adminId: admins[index].id,
                  onResetPassword: (email) => _resetPassword(context, email),
                  onDelete: (id, name) => _confirmDelete(context, id, name),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _resetPassword(BuildContext context, String email) async {
    try {
      await FirebaseFirestore.instance.app.options; // Just to ensure firebase is ready
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset email sent to $email'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildEmptyState({bool isSearch = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.backgroundLight, shape: BoxShape.circle),
            child: Icon(isSearch ? Icons.search_off_rounded : Icons.admin_panel_settings_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            isSearch ? 'No matching admins found.' : 'No other admins registered yet.',
            style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            isSearch ? 'Try a different search term.' : 'Click "Add New Admin" to grant someone access.',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showAddAdminDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: !_isCreating,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primaryNavy.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.person_add_rounded, color: AppColors.primaryNavy, size: 20),
                ),
                const SizedBox(width: 16),
                const Text('Grant Admin Access', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'A new administrative account will be created and registered in the system.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  _buildDialogField(nameController, 'Full Name', Icons.person_outline_rounded, TextInputAction.next),
                  const SizedBox(height: 16),
                  _buildDialogField(emailController, 'Email Address', Icons.email_outlined, TextInputAction.next, isEmail: true),
                  const SizedBox(height: 16),
                  _buildDialogField(passwordController, 'Temporary Password', Icons.lock_outline_rounded, TextInputAction.done, isPassword: true),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isCreating ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isCreating ? null : () async {
                  if (nameController.text.isEmpty || emailController.text.isEmpty || passwordController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                    return;
                  }
                  
                  setDialogState(() => _isCreating = true);
                  try {
                    await _createAdmin(context, nameController.text, emailController.text, passwordController.text);
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                    }
                  } finally {
                    setDialogState(() => _isCreating = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isCreating 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Create Account'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDialogField(TextEditingController controller, String label, IconData icon, TextInputAction action, {bool isEmail = false, bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          textInputAction: action,
          obscureText: isPassword,
          keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: AppColors.primaryNavy),
            hintText: 'Enter $label',
            filled: true,
            fillColor: AppColors.backgroundLight.withValues(alpha: 0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _createAdmin(BuildContext context, String name, String email, String password) async {
    final firebaseService = FirebaseService();
    
    // 1. Create in Firebase Auth
    final uid = await firebaseService.createUserAuth(email, password);
    
    // 2. Save Metadata to Firestore using the same UID
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'role': 'Admin',
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void _confirmDelete(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Revoke Access?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove $name? They will be immediately blocked from accessing the Admin Panel.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(id).delete();
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Confirm Remove', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _AdminRow extends StatefulWidget {
  final Map<String, dynamic> admin;
  final String adminId;
  final Function(String) onResetPassword;
  final Function(String, String) onDelete;

  const _AdminRow({
    required this.admin,
    required this.adminId,
    required this.onResetPassword,
    required this.onDelete,
  });

  @override
  State<_AdminRow> createState() => _AdminRowState();
}

class _AdminRowState extends State<_AdminRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final name = widget.admin['name'] ?? 'Unknown';
    final email = widget.admin['email'] ?? 'No Email';
    final createdAt = widget.admin['createdAt'] as Timestamp?;
    final dateStr = createdAt != null ? DateFormat('MMM dd, yyyy').format(createdAt.toDate()) : 'Recently';
    final isMobile = AppResponsiveUtil.isMobile(context);

    if (isMobile) {
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.primaryNavy.withValues(alpha: 0.02) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.1),
                    child: Text(
                      name[0].toUpperCase(),
                      style: const TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name, 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.primaryNavy.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20)),
                              child: const Text('ADMIN', style: TextStyle(color: AppColors.primaryNavy, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Added $dateStr', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Row(
                    children: [
                      _ActionIconButton(
                        icon: Icons.lock_reset_rounded,
                        color: AppColors.accentAmber,
                        onTap: () => widget.onResetPassword(email),
                        tooltip: 'Reset Password',
                      ),
                      const SizedBox(width: 8),
                      _ActionIconButton(
                        icon: Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        onTap: () => widget.onDelete(widget.adminId, name),
                        tooltip: 'Remove Access',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.primaryNavy.withValues(alpha: 0.02) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Stack(
            children: [
              AnimatedScale(
                scale: _isHovered ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.1),
                  child: Text(
                    name[0].toUpperCase(),
                    style: const TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
              Positioned(
                right: 0, bottom: 0,
                child: Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                ),
              ),
            ],
          ),
          title: Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _isHovered ? AppColors.primaryNavy : AppColors.textDark)),
          subtitle: Row(
            children: [
              Flexible(child: Text(email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13), overflow: TextOverflow.ellipsis, maxLines: 1)),
              const SizedBox(width: 12),
              const Icon(Icons.circle, size: 4, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Text('Added $dateStr', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primaryNavy.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20)),
                child: const Text('ADMIN', style: TextStyle(color: AppColors.primaryNavy, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
              const SizedBox(width: 8),
              _ActionIconButton(
                icon: Icons.lock_reset_rounded,
                color: AppColors.accentAmber,
                onTap: () => widget.onResetPassword(email),
                tooltip: 'Reset Password',
              ),
              const SizedBox(width: 4),
              _ActionIconButton(
                icon: Icons.delete_outline_rounded,
                color: Colors.redAccent,
                onTap: () => widget.onDelete(widget.adminId, name),
                tooltip: 'Remove Access',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  State<_ActionIconButton> createState() => _ActionIconButtonState();
}

class _ActionIconButtonState extends State<_ActionIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isHovered ? widget.color : widget.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: _isHovered ? Colors.white : widget.color,
            ),
          ),
        ),
      ),
    );
  }
}
