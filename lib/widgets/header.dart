import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';
import 'package:unitransit_admin/view_models/dashboard_view_model.dart';

class Header extends StatefulWidget {
  const Header({super.key});

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  late TextEditingController _searchController;
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<DashboardViewModel>();
    _searchController = TextEditingController(text: viewModel.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getUserName() {
    if (user == null) return 'Guest Admin';
    if (user!.displayName != null && user!.displayName!.isNotEmpty) {
      return user!.displayName!;
    }
    // Fallback: use email part before @
    if (user!.email != null) {
      return user!.email!.split('@')[0].toUpperCase();
    }
    return 'Admin';
  }

  String _getUserInitials() {
    String name = _getUserName();
    List<String> parts = name.split(' ');
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return name.substring(0, name.length > 1 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();
    final userName = _getUserName();
    
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: AppColors.cardWhite,
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        children: [
          // Menu Button for Mobile/Tablet
          if (!AppResponsiveUtil.isDesktop(context))
            IconButton(
              onPressed: () => Scaffold.of(context).openDrawer(),
              icon: const Icon(Icons.menu_rounded, color: AppColors.textDark),
            ),
          if (!AppResponsiveUtil.isDesktop(context)) const SizedBox(width: 16),

          // Search Bar
          Expanded(
            child: Container(
              height: 40,
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => viewModel.updateSearchQuery(v),
                style: const TextStyle(color: AppColors.textDark, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search anything...',
                  hintStyle: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.textSecondary.withValues(alpha: 0.5), size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  suffixIcon: _searchController.text.isNotEmpty 
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          viewModel.updateSearchQuery('');
                        },
                      )
                    : (!AppResponsiveUtil.isMobile(context) ? Container(
                    margin: const EdgeInsets.all(6),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: const Center(
                      widthFactor: 1,
                      child: Text('⌘ K', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ) : null),
                ),
              ),
            ),
          ),
          
          SizedBox(width: AppResponsiveUtil.isMobile(context) ? 12 : 32),
          
          // Action Icons
          _buildHeaderAction(Icons.notifications_none_rounded, hasBadge: true),
          
          if (!AppResponsiveUtil.isMobile(context)) ...[
            const SizedBox(width: 16),
            _buildHeaderAction(Icons.help_outline_rounded),
            const SizedBox(width: 32),
            // Divider
            Container(
              height: 40,
              width: 1,
              color: AppColors.borderLight,
            ),
          ],
          
          SizedBox(width: AppResponsiveUtil.isMobile(context) ? 12 : 32),
          
          // Profile Section
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                children: [
                  if (!AppResponsiveUtil.isMobile(context) && !AppResponsiveUtil.isTablet(context))
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Text(
                          'System Administrator',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  if (!AppResponsiveUtil.isMobile(context) && !AppResponsiveUtil.isTablet(context)) const SizedBox(width: 16),
                  Stack(
                    children: [
                      Container(
                        height: AppResponsiveUtil.isMobile(context) ? 36 : 48,
                        width: AppResponsiveUtil.isMobile(context) ? 36 : 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.5), width: 2),
                          image: DecorationImage(
                            image: NetworkImage('https://ui-avatars.com/api/?name=${userName.replaceAll(' ', '+')}&background=FFD600&color=2A367E'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          height: 10,
                          width: 10,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.cardWhite, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon, {bool hasBadge = false}) {
    return Stack(
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Icon(icon, color: AppColors.textSecondary, size: 22),
        ),
        if (hasBadge)
          Positioned(
            right: 12,
            top: 12,
            child: Container(
              height: 8,
              width: 8,
              decoration: BoxDecoration(
                color: AppColors.accentAmber,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardWhite, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}
