import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';
import 'package:unitransit_admin/view_models/dashboard_view_model.dart';
import 'package:unitransit_admin/view_models/login_view_model.dart';
import 'package:unitransit_admin/views/faq_management_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    final userName = isSuperAdmin ? 'Super Admin' : 'Admin';

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
            badgeCount: viewModel.pendingAlerts,
            onTap: () => viewModel.setSelectedIndex(8), // Notifications Index
          ),
          
          if (!AppResponsiveUtil.isMobile(context)) ...[
            const SizedBox(width: 16),
            _buildHeaderAction(
              context, 
              Icons.help_outline_rounded, 
              onTap: () => _showFaqPopover(context)
            ),
            const SizedBox(width: 32),
            Container(height: 40, width: 1, color: AppColors.borderLight),
          ],
          
          const SizedBox(width: 32),
          
          // User Profile Info
          Row(
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
                        Text(userName, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    const Text('Admin Dashboard', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              const SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryNavy.withOpacity(0.2), width: 2),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primaryNavy.withOpacity(0.1),
                  child: Text(
                    userName[0], 
                    style: const TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFaqPopover(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        content: Container(
          width: 500,
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Popover Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryNavy,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.quiz_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Help & FAQs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          Text('Quick guide and support', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (context.read<LoginViewModel>().isSuperAdmin)
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showFaqManagementDialog(context);
                        },
                        icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
                        tooltip: 'Manage FAQs',
                      ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              // FAQ Content
              Flexible(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('faqs').orderBy('order').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()));
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(Icons.help_center_outlined, size: 48, color: AppColors.textSecondary),
                            SizedBox(height: 16),
                            Text('No FAQs available yet.', style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      );
                    }

                    final faqs = snapshot.data!.docs;

                    return ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(24),
                      itemCount: faqs.length,
                      separatorBuilder: (context, index) => const Divider(height: 32),
                      itemBuilder: (context, index) {
                        final faq = faqs[index].data() as Map<String, dynamic>;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(faq['question'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
                            const SizedBox(height: 8),
                            Text(faq['answer'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

              // Footer
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  border: const Border(top: BorderSide(color: AppColors.borderLight)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Still need help?', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<DashboardViewModel>().setSelectedIndex(9); // Navigate to Support
                      },
                      child: const Text('Contact Support'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFaqManagementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: const SizedBox(
          width: 800,
          height: 600,
          child: FaqManagementScreen(),
        ),
      ),
    );
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
