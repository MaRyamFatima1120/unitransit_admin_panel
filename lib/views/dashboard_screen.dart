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
import 'package:unitransit_admin/view_models/login_view_model.dart';
import 'package:unitransit_admin/views/trip_history_screen.dart';
import 'package:unitransit_admin/views/assign_routes_screen.dart';
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
            border: Border.all(color: AppColors.accentAmber.withOpacity(0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
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
                  color: AppColors.accentAmber.withOpacity(0.2),
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
                        color: Colors.white.withOpacity(0.9),
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
    // Optimization: Using Selector to only rebuild when selectedIndex changes
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

// Optimization: LazyIndexedStack only builds children when they are first shown
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
    final dateStr = DateFormat('EEEE, MMMM d, yyyy').format(now);

    return SingleChildScrollView(
      controller: ScrollController(),
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Welcome Banner ──
          Container(
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
                  color: const Color(0xFF1A237E).withOpacity(0.35),
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
                              color: AppColors.accentAmber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.accentAmber.withOpacity(0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.accentAmber, shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                const Text('LIVE', style: TextStyle(color: AppColors.accentAmber, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '$greeting, ${isSuperAdmin ? "Super Admin" : "Admin"} 👋',
                        style: TextStyle(color: Colors.white, fontSize: isMobile ? 20 : 26, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dateStr,
                        style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: isMobile ? 12 : 13),
                      ),
                      const SizedBox(height: 20),
                      // Quick Action Chips
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _QuickChip(label: 'Add Student', icon: Icons.person_add_alt_1_rounded, onTap: () => context.read<DashboardViewModel>().setSelectedIndex(1)),
                          _QuickChip(label: 'Add Driver', icon: Icons.add_road_rounded, onTap: () => context.read<DashboardViewModel>().setSelectedIndex(2)),
                          _QuickChip(label: 'Send Alert', icon: Icons.campaign_rounded, onTap: () => context.read<DashboardViewModel>().setSelectedIndex(8)),
                          _QuickChip(label: 'View SOS', icon: Icons.warning_rounded, onTap: () => context.read<DashboardViewModel>().setSelectedIndex(12), isAlert: true),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isDesktop)
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Opacity(
                      opacity: 0.12,
                      child: Icon(Icons.directions_bus_rounded, size: 140, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const DashboardStatsGrid(),
          const SizedBox(height: 28),

          if (isSuperAdmin) ...[
            const AdminTeamSection(),
            const SizedBox(height: 28),
          ],

          if (isDesktop)
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: DashboardChart()),
                SizedBox(width: 28),
                Expanded(flex: 1, child: RecentActivity()),
              ],
            )
          else
            const Column(
              children: [
                DashboardChart(),
                SizedBox(height: 28),
                RecentActivity(),
              ],
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isAlert;
  const _QuickChip({required this.label, required this.icon, required this.onTap, this.isAlert = false});

  @override
  Widget build(BuildContext context) {
    final bg = isAlert ? Colors.red.withOpacity(0.18) : Colors.white.withOpacity(0.12);
    final border = isAlert ? Colors.red.withOpacity(0.5) : Colors.white.withOpacity(0.25);
    final color = isAlert ? Colors.redAccent.shade100 : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.primaryNavy.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
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
                return const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppColors.primaryNavy),
                ));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    children: [
                      Icon(Icons.group_off_rounded, color: AppColors.textSecondary),
                      SizedBox(width: 12),
                      Text('No other admins added yet.', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                );
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
                      color: color.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                          child: Center(child: Text(name[0].toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
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
    return Selector<DashboardViewModel, Map<String, dynamic>>(
      selector: (_, vm) => {
        'students': vm.totalStudents,
        'drivers': vm.totalDrivers,
        'revenue': vm.totalRevenue,
        'alerts': vm.pendingAlerts,
        'admins': vm.totalAdmins,
        'trips': vm.activeTrips,
        'sos': vm.activeEmergencyAlerts,
      },
      builder: (context, stats, _) {
        final cards = [
          StatCard(
            title: 'Total Students',
            value: stats['students'].toString(),
            icon: Icons.school_rounded,
            color: AppColors.primaryNavy,
            trend: stats['students'] > 0 ? '+Active' : '0',
            subtitle: 'Registered users',
          ),
          StatCard(
            title: 'Total Drivers',
            value: stats['drivers'].toString(),
            icon: Icons.drive_eta_rounded,
            color: const Color(0xFFF59E0B),
            trend: stats['drivers'] > 0 ? '+Active' : '0',
            subtitle: 'Fleet operators',
          ),
          if (isSuperAdmin)
            StatCard(
              title: 'Total Admins',
              value: stats['admins'].toString(),
              icon: Icons.admin_panel_settings_rounded,
              color: const Color(0xFF6366F1),
              trend: stats['admins'] > 0 ? '+Active' : '0',
              subtitle: 'Panel managers',
            )
          else
            StatCard(
              title: 'Active Trips',
              value: stats['trips'].toString(),
              icon: Icons.directions_bus_rounded,
              color: const Color(0xFF10B981),
              trend: stats['trips'] > 0 ? '+Running' : '0',
              subtitle: 'Live on roads',
            ),
          StatCard(
            title: 'Pending Alerts',
            value: stats['alerts'].toString(),
            icon: Icons.support_agent_rounded,
            color: const Color(0xFFEF4444),
            trend: stats['alerts'] > 0 ? '-Needs Action' : '0 pending',
            subtitle: 'Support requests',
          ),
        ];
        return LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 650 ? 2 : 1);
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: cols,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: cols == 4 ? 1.6 : (cols == 2 ? 1.7 : 2.2),
              children: cards,
            );
          },
        );
      },
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;
  final String? subtitle;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = trend.startsWith('+');
    final trendColor = isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6)),
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: trendColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: trendColor, size: 13),
                    const SizedBox(width: 3),
                    Text(trend, style: TextStyle(color: trendColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(color: AppColors.textDark, fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ],
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.65,
              minHeight: 3,
              backgroundColor: color.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.5)),
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardChart extends StatelessWidget {
  const DashboardChart({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();
    final stats = viewModel.weeklyTripStats;
    final spots = List.generate(stats.length, (i) => FlSpot(i.toDouble(), stats[i]));
    double maxVal = 10.0;
    for (var v in stats) { if (v > maxVal) maxVal = v; }
    maxVal = ((maxVal / 5).ceil() * 5).toDouble();
    final totalTrips = stats.fold(0.0, (a, b) => a + b).toInt();

    return Container(
      height: 460,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFF1A237E).withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.show_chart_rounded, color: Color(0xFF1A237E), size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Text('Trips Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('$totalTrips trips this week', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
                Row(
                  children: [
                    _LegendDot(color: AppColors.accentAmber, label: 'Trips'),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFF1A237E).withOpacity(0.06), borderRadius: BorderRadius.circular(20)),
                      child: const Text('This Week', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 24, 16),
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxVal,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(color: AppColors.borderLight, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          if (value.toInt() >= 0 && value.toInt() < days.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(days[value.toInt()], style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                        '${s.y.toInt()} trips',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      )).toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: AppColors.accentAmber,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2.5,
                          strokeColor: AppColors.accentAmber,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.accentAmber.withOpacity(0.22), AppColors.accentAmber.withOpacity(0)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        const SizedBox(width: 12),
      ],
    );
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
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.bolt_rounded, color: Color(0xFF10B981), size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text('Live Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  ],
                ),
                if (activities.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                    child: Text('${activities.length} events', style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: activities.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: AppColors.backgroundLight, shape: BoxShape.circle),
                          child: Icon(Icons.history_rounded, size: 36, color: Colors.grey.shade400),
                        ),
                        const SizedBox(height: 16),
                        const Text('No recent activity', style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        const Text('Activity will appear here when buses are active', style: TextStyle(color: AppColors.textSecondary, fontSize: 11), textAlign: TextAlign.center),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: activities.length,
                    itemBuilder: (context, index) {
                      final activity = activities[index];
                      final title = activity['title'] ?? '';
                      final subtitle = activity['subtitle'] ?? '';
                      final timestamp = activity['timestamp'] as DateTime?;
                      final icon = activity['icon'] as IconData? ?? Icons.notifications_none_rounded;
                      final color = activity['color'] as Color? ?? Colors.blue;
                      final isLast = index == activities.length - 1;

                      String timeText = 'Just now';
                      if (timestamp != null) {
                        final diff = DateTime.now().difference(timestamp);
                        if (diff.inMinutes < 1) timeText = 'Just now';
                        else if (diff.inMinutes < 60) timeText = '${diff.inMinutes}m ago';
                        else if (diff.inHours < 24) timeText = '${diff.inHours}h ago';
                        else timeText = DateFormat('MMM dd').format(timestamp);
                      }

                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Timeline bar
                            SizedBox(
                              width: 36,
                              child: Column(
                                children: [
                                  Container(
                                    width: 32, height: 32,
                                    decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                                    child: Icon(icon, color: color, size: 16),
                                  ),
                                  if (!isLast)
                                    Expanded(
                                      child: Container(
                                        width: 2,
                                        margin: const EdgeInsets.symmetric(vertical: 3),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [color.withOpacity(0.3), Colors.transparent],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ),
                                        Text(timeText, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
