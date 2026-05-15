import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unitransit_admin/view_models/login_view_model.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
                          Center(child: Text('Trip History - Coming Soon')),
                          NotificationsScreen(),
                          SupportScreen(),
                          SettingsScreen(),
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
    
    return SingleChildScrollView(
      controller: ScrollController(),
      padding: EdgeInsets.all(AppResponsiveUtil.isMobile(context) ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard Overview',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          letterSpacing: -0.5,
                          fontSize: AppResponsiveUtil.isMobile(context) ? 24 : null,
                        ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Welcome back, here\'s what\'s happening today.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => context.read<DashboardViewModel>().refreshData(),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const DashboardStatsGrid(),
          const SizedBox(height: 32),
          
          // Super Admin Specific Section: Admin Team
          if (isSuperAdmin) ...[
            const AdminTeamSection(),
            const SizedBox(height: 32),
          ],

          if (AppResponsiveUtil.isDesktop(context))
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: DashboardChart()),
                SizedBox(width: 32),
                Expanded(flex: 1, child: RecentActivity()),
              ],
            )
          else
            const Column(
              children: [
                DashboardChart(),
                SizedBox(height: 32),
                RecentActivity(),
              ],
            ),
        ],
      ),
    );
  }
}

class AdminTeamSection extends StatelessWidget {
  const AdminTeamSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Admin Management Team',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
              TextButton.icon(
                onPressed: () => context.read<DashboardViewModel>().setSelectedIndex(3),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('Manage All'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Admin').limit(5).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('No other admins added yet.', style: TextStyle(color: AppColors.textSecondary));
              }

              final admins = snapshot.data!.docs;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: admins.map((doc) {
                  final admin = doc.data() as Map<String, dynamic>;
                  final name = admin['name'] ?? 'Admin';
                  final role = admin['role'] ?? 'Admin';
                  
                  return Container(
                    width: 250,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primaryNavy.withOpacity(0.1),
                          child: Text(name[0].toUpperCase(), style: const TextStyle(color: AppColors.primaryNavy, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text(role, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
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
    // Optimization: Selector to only rebuild stats when they change
    final isSuperAdmin = context.read<LoginViewModel>().isSuperAdmin;

    return Selector<DashboardViewModel, Map<String, dynamic>>(
      selector: (_, vm) => {
        'students': vm.totalStudents,
        'drivers': vm.totalDrivers,
        'revenue': vm.totalRevenue,
        'alerts': vm.pendingAlerts,
        'admins': vm.totalAdmins,
      },
      builder: (context, stats, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: constraints.maxWidth > 1400 ? 4 : (constraints.maxWidth > 700 ? 2 : 1),
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: constraints.maxWidth > 1400 ? 2.2 : 2.5,
              children: [
                StatCard(
                  title: 'Total Students',
                  value: stats['students'].toString(),
                  icon: Icons.people_outline_rounded,
                  color: AppColors.primaryNavy,
                  trend: '+${stats['students'] > 0 ? "100" : "0"}%',
                ),
                StatCard(
                  title: 'Total Drivers',
                  value: stats['drivers'].toString(),
                  icon: Icons.drive_eta_rounded,
                  color: AppColors.accentAmber,
                  trend: '+${stats['drivers'] > 0 ? "100" : "0"}%',
                ),
                if (isSuperAdmin)
                  StatCard(
                    title: 'Total Admins',
                    value: stats['admins'].toString(),
                    icon: Icons.admin_panel_settings_rounded,
                    color: Colors.deepPurple,
                    trend: stats['admins'] > 0 ? '+${stats['admins']}' : '0',
                  )
                else
                  StatCard(
                    title: 'Total Revenue',
                    value: '\$${stats['revenue'].toStringAsFixed(0)}',
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppColors.staffOnly,
                    trend: '+8%',
                  ),
                StatCard(
                  title: 'Pending Alerts',
                  value: stats['alerts'].toString(),
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.error,
                  trend: '-2%',
                ),
              ],
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

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: trend.startsWith('+') ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        trend,
                        style: TextStyle(
                          color: trend.startsWith('+') ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
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
    return Container(
      height: 450,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Trips Analytics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: 'Weekly',
                  underline: const SizedBox(),
                  dropdownColor: AppColors.cardWhite,
                  icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 20),
                  items: ['Daily', 'Weekly', 'Monthly'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true, drawVerticalLine: false),
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
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Text(days[value.toInt()], style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 30), FlSpot(1, 45), FlSpot(2, 35), FlSpot(3, 60), FlSpot(4, 50), FlSpot(5, 80), FlSpot(6, 70),
                    ],
                    isCurved: true,
                    color: AppColors.accentAmber,
                    barWidth: 4,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.accentAmber.withOpacity(0.2), AppColors.accentAmber.withOpacity(0)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RecentActivity extends StatelessWidget {
  const RecentActivity({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 450,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Activity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: 6,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final activities = [
                  {'title': 'Bus #42 Arrived', 'time': '2 mins ago', 'icon': Icons.location_on_rounded, 'color': Colors.green},
                  {'title': 'New Route Created', 'time': '15 mins ago', 'icon': Icons.add_road_rounded, 'color': AppColors.primaryNavy},
                  {'title': 'Driver #12 Online', 'time': '22 mins ago', 'icon': Icons.person_rounded, 'color': Colors.blue},
                  {'title': 'Maintenance Alert', 'time': '45 mins ago', 'icon': Icons.build_rounded, 'color': Colors.orange},
                  {'title': 'Bus #09 Delay', 'time': '1 hour ago', 'icon': Icons.timer_rounded, 'color': Colors.red},
                  {'title': 'Shift Completed', 'time': '2 hours ago', 'icon': Icons.check_circle_rounded, 'color': Colors.purple},
                ];
                final activity = activities[index % activities.length];
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: (activity['color'] as Color).withOpacity(0.1), shape: BoxShape.circle),
                      child: Icon(activity['icon'] as IconData, color: activity['color'] as Color, size: 18),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(activity['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          Text(activity['time'] as String, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
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
