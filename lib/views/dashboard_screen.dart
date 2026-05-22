import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';
import 'package:unitransit_admin/view_models/dashboard_view_model.dart';
import 'package:unitransit_admin/widgets/sidebar.dart';
import 'package:unitransit_admin/widgets/header.dart';
import 'package:unitransit_admin/views/students_screen.dart';
import 'package:unitransit_admin/views/drivers_screen.dart';
import 'package:unitransit_admin/views/notifications_screen.dart';
import 'package:unitransit_admin/views/support_screen.dart';
import 'package:unitransit_admin/views/settings_screen.dart';
import 'package:unitransit_admin/views/fleet_operations_screen.dart';
import 'package:unitransit_admin/views/route_planning_screen.dart';
import 'package:unitransit_admin/views/gender_config_screen.dart';
import 'package:unitransit_admin/views/admins_management_screen.dart';
import 'package:unitransit_admin/views/schedules_screen.dart';
import 'package:unitransit_admin/views/emergency_alerts_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unitransit_admin/view_models/login_view_model.dart';
import 'package:unitransit_admin/views/trip_history_screen.dart';
import 'package:unitransit_admin/views/assign_routes_screen.dart';
import 'package:unitransit_admin/core/utils/animations.dart';
import 'dart:async';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  StreamSubscription? _tripAlertsSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenToTripAlerts();
    });
  }

  void _listenToTripAlerts() {
    final viewModel = context.read<DashboardViewModel>();
    _tripAlertsSubscription = viewModel.onNewTripAlert.listen((alert) {
      if (mounted) {
        _showTripStartToast(alert);
      }
    });
  }

  void _showTripStartToast(Map<String, dynamic> alert) {
    final busNumber = alert['busNumber'] ?? 'N/A';
    final from = alert['from'] ?? 'Unknown';
    final to = alert['to'] ?? 'Unknown';
    final gender = alert['gender'] ?? 'All';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.primaryNavy,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentAmber.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.directions_bus_rounded, color: AppColors.accentAmber, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Live Trip Notification',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bus $busNumber started route: $from ➔ $to ($gender)',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tripAlertsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<DashboardViewModel, int>(
      selector: (_, vm) => vm.selectedIndex,
      builder: (context, selectedIndex, _) {
        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          drawer: !AppResponsiveUtil.isDesktop(context) ? const Drawer(width: 280, child: Sidebar()) : null,
          body: Row(
            children: [
              if (AppResponsiveUtil.isDesktop(context)) const Sidebar(),
              Expanded(
                child: Column(
                  children: [
                    const Header(),
                    Expanded(
                      child: LazyIndexedStack(
                        index: selectedIndex,
                        children: const [
                          DashboardOverview(),
                          StudentsScreen(),
                          DriversScreen(),
                          AdminsManagementScreen(),
                          FleetOperationsScreen(),
                          RoutePlanningScreen(),
                          GenderConfigScreen(),
                          TripHistoryScreen(),
                          NotificationsScreen(),
                          SupportScreen(),
                          SettingsScreen(),
                          SchedulesScreen(),
                          EmergencyAlertsScreen(),
                          AssignRoutesScreen(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late List<bool> _activated;

  @override
  void initState() {
    super.initState();
    _activated = List.generate(widget.children.length, (i) => i == widget.index);
  }

  @override
  void didUpdateWidget(LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_activated[widget.index]) {
      _activated[widget.index] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: widget.index,
      children: List.generate(widget.children.length, (i) {
        return _activated[i] ? widget.children[i] : const SizedBox.shrink();
      }),
    );
  }
}

class DashboardOverview extends StatelessWidget {
  const DashboardOverview({super.key});

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = context.read<LoginViewModel>().isSuperAdmin;
    final isMobile = AppResponsiveUtil.isMobile(context);
    final isDesktop = AppResponsiveUtil.isDesktop(context);
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'Good Morning' : now.hour < 17 ? 'Good Afternoon' : 'Good Evening';

    return SingleChildScrollView(
      controller: ScrollController(),
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInSlide(
            duration: const Duration(milliseconds: 800),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(isMobile ? 20 : 28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF283593)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                  color: const Color(0xFF1A237E).withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accentAmber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.accentAmber.withValues(alpha: 0.5)),
                            ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.accentAmber, shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  const Text('LIVE SYSTEM', style: TextStyle(color: AppColors.accentAmber, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser?.uid)
                              .snapshots(),
                          builder: (context, snapshot) {
                            String displayName = isSuperAdmin ? "Super Admin" : "Admin";
                            if (snapshot.hasData && snapshot.data!.exists) {
                              final data = snapshot.data!.data() as Map<String, dynamic>?;
                              if (data != null) {
                                final dbName = data['name']?.toString().trim();
                                if (dbName != null && dbName.isNotEmpty) {
                                  displayName = dbName;
                                }
                              }
                            }
                            if (displayName == (isSuperAdmin ? "Super Admin" : "Admin")) {
                              final authUser = FirebaseAuth.instance.currentUser;
                              if (authUser != null && authUser.displayName != null && authUser.displayName!.trim().isNotEmpty) {
                                displayName = authUser.displayName!.trim();
                              }
                            }
                            return Text(
                              '$greeting, $displayName 👋',
                              style: TextStyle(color: Colors.white, fontSize: isMobile ? 24 : 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Here\'s what\'s happening with your fleet today.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _QuickChip(
                              label: 'Add Student', 
                              icon: Icons.person_add_alt_1_rounded, 
                              onTap: () => context.read<DashboardViewModel>().setSelectedIndex(1)
                            ),
                            _QuickChip(
                              label: 'Add Driver', 
                              icon: Icons.add_road_rounded, 
                              onTap: () => context.read<DashboardViewModel>().setSelectedIndex(2)
                            ),
                            _QuickChip(
                              label: 'Send Alert', 
                              icon: Icons.campaign_rounded, 
                              onTap: () => context.read<DashboardViewModel>().setSelectedIndex(8)
                            ),
                            _QuickChip(
                              label: 'View SOS', 
                              icon: Icons.warning_rounded, 
                              onTap: () => context.read<DashboardViewModel>().setSelectedIndex(12), 
                              isAlert: true
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isDesktop)
                    const Padding(
                      padding: EdgeInsets.only(left: 24),
                      child: FloatingBusIcon(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          const DashboardStatsGrid(),
          const SizedBox(height: 32),
          if (isSuperAdmin) ...[
            const FadeInSlide(
              direction: FadeInDirection.bottomToTop,
              delay: Duration(milliseconds: 400),
              child: AdminTeamSection(),
            ),
            const SizedBox(height: 32),
          ],
          if (isDesktop)
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2, 
                  child: FadeInSlide(
                    direction: FadeInDirection.leftToRight,
                    delay: Duration(milliseconds: 500),
                    child: DashboardChart(),
                  )
                ),
                SizedBox(width: 28),
                Expanded(
                  flex: 1, 
                  child: FadeInSlide(
                    direction: FadeInDirection.rightToLeft,
                    delay: Duration(milliseconds: 600),
                    child: RecentActivity(),
                  )
                ),
              ],
            )
          else
            const Column(
              children: [
                FadeInSlide(
                  direction: FadeInDirection.bottomToTop,
                  delay: Duration(milliseconds: 500),
                  child: DashboardChart(),
                ),
                SizedBox(height: 32),
                FadeInSlide(
                  direction: FadeInDirection.bottomToTop,
                  delay: Duration(milliseconds: 600),
                  child: RecentActivity(),
                ),
              ],
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _QuickChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isAlert;
  const _QuickChip({required this.label, required this.icon, required this.onTap, this.isAlert = false});

  @override
  State<_QuickChip> createState() => _QuickChipState();
}

class _QuickChipState extends State<_QuickChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isAlert 
        ? (Colors.red.withValues(alpha: _isHovered ? 0.3 : 0.18)) 
        : (Colors.white.withValues(alpha: _isHovered ? 0.2 : 0.12));
    final border = widget.isAlert 
        ? (Colors.red.withValues(alpha: 0.5)) 
        : (Colors.white.withValues(alpha: 0.25));
    final color = widget.isAlert ? Colors.redAccent.shade100 : Colors.white;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          transform: _isHovered ? Matrix4.translationValues(0, -2, 0) : Matrix4.identity(),
          decoration: BoxDecoration(
            color: bg, 
            borderRadius: BorderRadius.circular(12), 
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                widget.label, 
                style: TextStyle(
                  color: color, 
                  fontSize: 13, 
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminTeamSection extends StatelessWidget {
  const AdminTeamSection({super.key});

  static const List<Color> _avatarColors = [
    Color(0xFF6366F1), Color(0xFF0EA5E9), Color(0xFF10B981),
    Color(0xFFF59E0B), Color(0xFFEC4899),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppResponsiveUtil.isMobile(context)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryNavy.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primaryNavy, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Admin Management Team',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => context.read<DashboardViewModel>().setSelectedIndex(3),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: const Text('Manage All'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primaryNavy, padding: EdgeInsets.zero),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryNavy.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primaryNavy, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text('Admin Management Team', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () => context.read<DashboardViewModel>().setSelectedIndex(3),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: const Text('Manage All'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primaryNavy),
                    ),
                  ],
                ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Admin').limit(5).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primaryNavy));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('No other admins added yet.', style: TextStyle(color: AppColors.textSecondary));
              }
              final admins = snapshot.data!.docs;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(admins.length, (i) {
                  final admin = admins[i].data() as Map<String, dynamic>;
                  final name = admin['name'] ?? 'Admin';
                  final email = admin['email'] ?? '';
                  final color = _avatarColors[i % _avatarColors.length];
                  return Container(
                    width: 240,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 21,
                          backgroundColor: color.withValues(alpha: 0.12),
                          child: Text(name[0].toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                              Text(email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

class DashboardStatsGrid extends StatelessWidget {
  const DashboardStatsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = context.read<LoginViewModel>().isSuperAdmin;
    final dashboardVM = context.read<DashboardViewModel>();
    
    return Selector<DashboardViewModel, Map<String, dynamic>>(
      selector: (_, vm) => {
        'students': vm.totalStudents,
        'drivers': vm.totalDrivers,
        'admins': vm.totalAdmins,
        'trips': vm.activeTrips,
        'sos': vm.activeEmergencyAlerts,
      },
      builder: (context, stats, _) {
        final cards = [
          FadeInSlide(
            delay: const Duration(milliseconds: 100),
            child: StatCard(
              title: 'Fleet Students',
              value: stats['students'].toString(),
              icon: Icons.people_alt_rounded,
              color: const Color(0xFF6366F1),
              trend: 'Total Registered',
              subtitle: 'Real-time student base',
              onTap: () => dashboardVM.setSelectedIndex(1),
            ),
          ),
          FadeInSlide(
            delay: const Duration(milliseconds: 200),
            child: StatCard(
              title: 'Active Drivers',
              value: stats['drivers'].toString(),
              icon: Icons.person_pin_circle_rounded,
              color: const Color(0xFFF59E0B),
              trend: 'On-Duty Status',
              subtitle: 'Verified operators',
              onTap: () => dashboardVM.setSelectedIndex(2),
            ),
          ),
          if (isSuperAdmin)
            FadeInSlide(
              delay: const Duration(milliseconds: 300),
              child: StatCard(
                title: 'System Admins',
                value: stats['admins'].toString(),
                icon: Icons.shield_rounded,
                color: const Color(0xFF0EA5E9),
                trend: 'Privileged Access',
                subtitle: 'Control panel users',
                onTap: () => dashboardVM.setSelectedIndex(3),
              ),
            )
          else
            FadeInSlide(
              delay: const Duration(milliseconds: 300),
              child: StatCard(
                title: 'Live Trips',
                value: stats['trips'].toString(),
                icon: Icons.local_shipping_rounded,
                color: const Color(0xFF10B981),
                trend: 'Running Now',
                subtitle: 'Current active routes',
                onTap: () => dashboardVM.setSelectedIndex(7),
              ),
            ),
          FadeInSlide(
            delay: const Duration(milliseconds: 400),
            child: StatCard(
              title: 'Emergency SOS',
              value: stats['sos'].toString(),
              icon: Icons.notification_important_rounded,
              color: const Color(0xFFEF4444),
              trend: stats['sos'] > 0 ? 'Critical Alert' : 'System Secure',
              subtitle: stats['sos'] > 0 ? 'Immediate action required' : 'No active emergencies',
              isAlert: stats['sos'] > 0,
              onTap: () => dashboardVM.setSelectedIndex(12),
            ),
          ),
        ];
        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth <= 700;
            final cols = constraints.maxWidth > 1200 ? 4 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: cols,
              crossAxisSpacing: isMobile ? 12 : 24,
              mainAxisSpacing: isMobile ? 12 : 24,
              childAspectRatio: isMobile
                  ? (constraints.maxWidth < 360 ? 1.05 : 1.15)
                  : (constraints.maxWidth > 1400
                      ? 1.5
                      : (cols == 4 ? 1.25 : 1.4)),
              children: cards,
            );
          },
        );
      },
    );
  }
}

class StatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isAlert;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
    this.subtitle,
    this.onTap,
    this.isAlert = false,
  });

  @override
  State<StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<StatCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    if (widget.isAlert) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(StatCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAlert && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isAlert && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsiveUtil.isMobile(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(isMobile ? 12 : 24),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered ? widget.color.withValues(alpha: 0.4) : AppColors.borderLight.withValues(alpha: 0.8),
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _isHovered ? 0.15 : 0.05),
                blurRadius: _isHovered ? 30 : 20,
                offset: Offset(0, _isHovered ? 12 : 8),
              ),
              if (widget.isAlert)
                BoxShadow(color: Colors.red.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 2),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 6 : 12),
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: isMobile ? 16 : 24),
                  ),
                  _buildTrendBadge(),
                ],
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    widget.value,
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: isMobile ? 22 : 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  if (widget.isAlert && widget.value != '0')
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: ScaleTransition(
                        scale: Tween(begin: 1.0, end: 1.2).animate(_pulseController),
                        child: Icon(Icons.emergency_rounded, color: Colors.red, size: isMobile ? 14 : 18),
                      ),
                    ),
                ],
              ),
              Text(
                widget.title,
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: isMobile ? 12 : 15,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  widget.subtitle!,
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    fontSize: isMobile ? 9 : 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendBadge() {
    final isMobile = AppResponsiveUtil.isMobile(context);
    final Color badgeColor = widget.isAlert ? Colors.red : widget.color;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 10, vertical: isMobile ? 3 : 6),
      decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: badgeColor.withValues(alpha: 0.2))),
      child: Text(widget.trend.toUpperCase(), style: TextStyle(color: badgeColor, fontSize: isMobile ? 8 : 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
    );
  }
}

class DashboardChart extends StatelessWidget {
  const DashboardChart({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();
    final stats = viewModel.weeklyTripStats;
    final scale = viewModel.selectedTimeScale;
    final spots = List.generate(stats.length, (i) => FlSpot(i.toDouble(), stats[i]));
    double maxVal = 10.0;
    for (var v in stats) { if (v > maxVal) maxVal = v; }
    maxVal = ((maxVal / 5).ceil() * 5).toDouble() + 2;
    final totalTrips = stats.fold(0.0, (a, b) => a + b).toInt();

    return Container(
      height: 480,
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.8)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: AppResponsiveUtil.isMobile(context)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryNavy.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.analytics_rounded, color: AppColors.primaryNavy, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Trip Analytics & Trends',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Monitoring $totalTrips total trips in this $scale',
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTimeScaleToggle(context, viewModel),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryNavy.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.analytics_rounded, color: AppColors.primaryNavy, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Text('Trip Analytics & Trends', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('Monitoring $totalTrips total trips in this $scale', style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      _buildTimeScaleToggle(context, viewModel),
                    ],
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 32, 12),
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxVal,
                  gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: AppColors.borderLight.withValues(alpha: 0.5), strokeWidth: 1, dashArray: [5, 5])),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: (value, meta) => _getBottomTitles(value, scale))),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.bold)))),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.primaryNavy,
                      barWidth: 4,
                      dotData: FlDotData(show: stats.length < 32),
                      belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.primaryNavy.withValues(alpha: 0.2), AppColors.primaryNavy.withValues(alpha: 0)])),
                    ),
                  ],
                ),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              ),
            ),
          ),
          _buildInsightFooter(context, stats, scale),
        ],
      ),
    );
  }

  Widget _buildTimeScaleToggle(BuildContext context, DashboardViewModel vm) {
    final isMobile = AppResponsiveUtil.isMobile(context);
    return Container(
      decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['Day', 'Week', 'Month', 'Year'].map((s) {
          final isSelected = vm.selectedTimeScale == s;
          return GestureDetector(
            onTap: () => vm.setTimeScale(s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 14, vertical: 8),
              decoration: BoxDecoration(color: isSelected ? AppColors.primaryNavy : Colors.transparent, borderRadius: BorderRadius.circular(8)),
              child: Text(s, style: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _getBottomTitles(double value, String scale) {
    String text = '';
    if (scale == 'Day' && value.toInt() % 4 == 0) text = '${value.toInt()}:00';
    else if (scale == 'Week' && value.toInt() >= 0 && value.toInt() < 7) text = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][value.toInt()];
    else if (scale == 'Month' && value.toInt() % 5 == 0) text = 'Day ${value.toInt() + 1}';
    else if (scale == 'Year' && value.toInt() >= 0 && value.toInt() < 12) text = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][value.toInt()];
    return Padding(padding: const EdgeInsets.only(top: 10), child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)));
  }

  Widget _buildInsightFooter(BuildContext context, List<double> stats, String scale) {
    if (stats.isEmpty) return const SizedBox();
    double avg = stats.fold(0.0, (a, b) => a + b) / stats.length;
    double max = stats.reduce((a, b) => a > b ? a : b);
    final isMobile = AppResponsiveUtil.isMobile(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: isMobile
          ? Wrap(
              spacing: 16,
              runSpacing: 12,
              alignment: WrapAlignment.spaceAround,
              children: [
                _InsightItem(label: 'Avg Trips', value: avg.toStringAsFixed(1), icon: Icons.speed_rounded, color: Colors.blue),
                _InsightItem(label: 'Peak Volume', value: max.toInt().toString(), icon: Icons.trending_up_rounded, color: Colors.orange),
                _InsightItem(label: 'Data Sync', value: 'Real-time', icon: Icons.sync_rounded, color: Colors.green),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InsightItem(label: 'Avg Trips', value: avg.toStringAsFixed(1), icon: Icons.speed_rounded, color: Colors.blue),
                _InsightItem(label: 'Peak Volume', value: max.toInt().toString(), icon: Icons.trending_up_rounded, color: Colors.orange),
                _InsightItem(label: 'Data Sync', value: 'Real-time', icon: Icons.sync_rounded, color: Colors.green),
              ],
            ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final String label, value; final IconData icon; final Color color;
  const _InsightItem({required this.label, required this.value, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(children: [Icon(icon, size: 16, color: color), const SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)), Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textDark, fontWeight: FontWeight.w800))])]);
  }
}

class RecentActivity extends StatelessWidget {
  const RecentActivity({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();
    final activities = viewModel.recentActivities;
    return Container(
      height: 460,
      decoration: BoxDecoration(color: AppColors.cardWhite, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.borderLight), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.bolt_rounded, color: Color(0xFF10B981), size: 18)), const SizedBox(width: 10), const Text('Live Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark))]),
                if (activities.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)), child: Text('${activities.length} events', style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          Expanded(
            child: activities.isEmpty
                ? const Center(child: Text('No recent activity', style: TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: activities.length,
                    itemBuilder: (context, index) {
                      final activity = activities[index];
                      final isLast = index == activities.length - 1;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(children: [Container(width: 32, height: 32, decoration: BoxDecoration(color: (activity['color'] as Color).withValues(alpha: 0.12), shape: BoxShape.circle), child: Icon(activity['icon'] as IconData, color: activity['color'] as Color, size: 16)), if (!isLast) Container(width: 2, height: 20, color: AppColors.borderLight)]),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(activity['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Text(activity['subtitle'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11))])),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class FloatingBusIcon extends StatefulWidget {
  const FloatingBusIcon({super.key});
  @override
  State<FloatingBusIcon> createState() => _FloatingBusIconState();
}

class _FloatingBusIconState extends State<FloatingBusIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller; late Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 15).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) { return AnimatedBuilder(animation: _animation, builder: (context, child) => Transform.translate(offset: Offset(0, -_animation.value), child: const Opacity(opacity: 0.12, child: Icon(Icons.directions_bus_rounded, size: 140, color: Colors.white)))); }
}
