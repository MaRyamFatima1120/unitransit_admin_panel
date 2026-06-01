import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';
import 'package:unitransit_admin/core/services/firebase_service.dart';
import 'package:unitransit_admin/view_models/dashboard_view_model.dart';
import 'package:unitransit_admin/core/utils/animations.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsiveUtil.isMobile(context);
    final firebaseService = context.read<FirebaseService>();

    return FadeInSlide(
      duration: const Duration(milliseconds: 600),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            Expanded(
              child: StreamBuilder<Map<String, dynamic>>(
                stream: firebaseService.getTripAnalyticsStream(),
                builder: (context, tripSnap) {
                  final tripData = tripSnap.data ?? {
                    'totalTrips': 0,
                    'completedTrips': 0,
                    'successRate': 0.0,
                    'peakHour': 8,
                    'hourlyBuckets': List<int>.filled(24, 0),
                  };

                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: firebaseService.getBusesStream(),
                    builder: (context, busSnap) {
                      final buses = busSnap.data ?? [];
                      final avgFuel = buses.isEmpty
                          ? 0.0
                          : buses.fold<double>(0.0, (sum, b) {
                              final f = double.tryParse(
                                      b['fuelAverage']?.toString() ?? '0') ??
                                  0.0;
                              return sum + f;
                            }) /
                              buses.length;

                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildSummaryGrid(context, tripData, avgFuel),
                            const SizedBox(height: 32),
                            _buildDetailedCharts(context, tripData),
                            const SizedBox(height: 32),
                            _buildExportSection(context, tripData),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Advanced Analytics',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    fontSize: AppResponsiveUtil.isMobile(context) ? 24 : null,
                  ),
            ),
            Text('Real-time insights from live Firebase data.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
        if (!AppResponsiveUtil.isMobile(context))
          ElevatedButton.icon(
            onPressed: () => _showExportDialog(context),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Export Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryGrid(
      BuildContext context, Map<String, dynamic> tripData, double avgFuel) {
    final viewModel = context.watch<DashboardViewModel>();
    final successRate = (tripData['successRate'] as double?) ?? 0.0;
    final peakHour = (tripData['peakHour'] as int?) ?? 8;
    final peakHourStr =
        DateFormat('hh:mm a').format(DateTime(2000, 1, 1, peakHour));

    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 1200
          ? 4
          : (constraints.maxWidth > 700 ? 2 : 1);
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: AppResponsiveUtil.isMobile(context) ? 2.2 : 2,
        children: [
          _buildAnalyticCard(
            'Total Revenue',
            'Rs. ${viewModel.totalRevenue.toStringAsFixed(0)}',
            Icons.payments_rounded,
            Colors.green,
            subtitle: 'From completed trips',
            isLive: true,
          ),
          _buildAnalyticCard(
            'Trip Success Rate',
            '${successRate.toStringAsFixed(1)}%',
            Icons.verified_rounded,
            Colors.blue,
            subtitle:
                '${tripData['completedTrips']} / ${tripData['totalTrips']} trips',
            isLive: true,
          ),
          _buildAnalyticCard(
            'Peak Hour Usage',
            peakHourStr,
            Icons.access_time_filled_rounded,
            Colors.orange,
            subtitle: 'Most active bus hour',
            isLive: true,
          ),
          _buildAnalyticCard(
            'Avg Fuel Efficiency',
            avgFuel > 0 ? '${avgFuel.toStringAsFixed(1)} km/l' : 'N/A',
            Icons.local_gas_station_rounded,
            Colors.purple,
            subtitle:
                avgFuel > 0 ? 'Fleet average' : 'No buses recorded yet',
            isLive: false,
          ),
        ],
      );
    });
  }

  Widget _buildAnalyticCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
    bool isLive = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(label,
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (isLive) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.w900),
                    overflow: TextOverflow.ellipsis),
                if (subtitle != null)
                  Text(subtitle,
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 11),
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedCharts(
      BuildContext context, Map<String, dynamic> tripData) {
    final viewModel = context.watch<DashboardViewModel>();
    final hourlyBuckets = (tripData['hourlyBuckets'] as List?)
            ?.map((e) => (e as int?) ?? 0)
            .toList() ??
        List<int>.filled(24, 0);

    // Build bar chart from real hourly data (showing 6-hour buckets: 0-5, 6-11, 12-17, 18-23)
    final List<double> sixHourBuckets = [
      hourlyBuckets.sublist(0, 6).fold(0, (a, b) => a + b).toDouble(),
      hourlyBuckets.sublist(6, 12).fold(0, (a, b) => a + b).toDouble(),
      hourlyBuckets.sublist(12, 18).fold(0, (a, b) => a + b).toDouble(),
      hourlyBuckets.sublist(18, 24).fold(0, (a, b) => a + b).toDouble(),
    ];
    final bucketLabels = ['12AM-6AM', '6AM-12PM', '12PM-6PM', '6PM-12AM'];
    final bucketColors = [Colors.indigo, Colors.blue, Colors.orange, Colors.purple];

    final totalStudents = viewModel.totalStudents;
    final totalDrivers = viewModel.totalDrivers;
    final totalUsers = totalStudents + totalDrivers;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Container(
            height: 420,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Trip Activity by Time Slot',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, color: Colors.green, size: 8),
                          SizedBox(width: 4),
                          Text('LIVE',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Real data from ${tripData['totalTrips']} total trips',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: AppColors.borderLight,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (val, meta) => Text(
                              val.toInt().toString(),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              final idx = val.toInt();
                              if (idx >= 0 && idx < bucketLabels.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    bucketLabels[idx],
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: AppColors.textSecondary),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(
                        4,
                        (i) => BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: sixHourBuckets[i],
                              color: bucketColors[i],
                              width: 32,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8)),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!AppResponsiveUtil.isMobile(context)) ...[
          const SizedBox(width: 24),
          Expanded(
            flex: 1,
            child: Container(
              height: 420,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('User Distribution',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('$totalUsers total users',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 24),
                  Expanded(
                    child: totalUsers == 0
                        ? Center(
                            child: Text('No users yet',
                                style: TextStyle(
                                    color: AppColors.textSecondary)))
                        : PieChart(
                            PieChartData(
                              sectionsSpace: 3,
                              centerSpaceRadius: 40,
                              sections: [
                                if (totalStudents > 0)
                                  PieChartSectionData(
                                    value: totalStudents.toDouble(),
                                    title:
                                        '${((totalStudents / totalUsers) * 100).toStringAsFixed(0)}%',
                                    titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                    color: Colors.blue,
                                    radius: 60,
                                  ),
                                if (totalDrivers > 0)
                                  PieChartSectionData(
                                    value: totalDrivers.toDouble(),
                                    title:
                                        '${((totalDrivers / totalUsers) * 100).toStringAsFixed(0)}%',
                                    titleStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                    color: Colors.orange,
                                    radius: 60,
                                  ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  _buildLegendRow(
                      'Students', totalStudents.toString(), Colors.blue),
                  const SizedBox(height: 8),
                  _buildLegendRow(
                      'Drivers', totalDrivers.toString(), Colors.orange),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLegendRow(String label, String count, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label,
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
        ),
        Text(count,
            style: TextStyle(
                color: AppColors.textDark,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildExportSection(
      BuildContext context, Map<String, dynamic> tripData) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: AppColors.primaryNavy.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.primaryNavy),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Export Analytics Report',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(
                    'Copy a summary of key metrics to clipboard in CSV format.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _exportToClipboard(context, tripData),
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy CSV'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _exportToClipboard(
      BuildContext context, Map<String, dynamic> tripData) {
    final viewModel = context.read<DashboardViewModel>();
    final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final successRate = (tripData['successRate'] as double?)?.toStringAsFixed(1) ?? '0.0';
    final peakHour = tripData['peakHour'] as int? ?? 8;
    final peakHourStr =
        DateFormat('hh:mm a').format(DateTime(2000, 1, 1, peakHour));

    final csv = '''UniTransit Analytics Report
Generated At,$now
---
Metric,Value
Total Students,${viewModel.totalStudents}
Total Drivers,${viewModel.totalDrivers}
Total Trips,${tripData['totalTrips']}
Completed Trips,${tripData['completedTrips']}
Trip Success Rate,$successRate%
Peak Hour Usage,$peakHourStr
Total Revenue,Rs. ${viewModel.totalRevenue.toStringAsFixed(0)}
Active Emergency Alerts,${viewModel.activeEmergencyAlerts}
''';

    Clipboard.setData(ClipboardData(text: csv));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text('CSV copied to clipboard!'),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.download_rounded, color: AppColors.primaryNavy),
            SizedBox(width: 12),
            Text('Export System Data'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select the type of report to copy:'),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('Analytics Summary (CSV)'),
              subtitle: const Text('Key metrics — copy to clipboard'),
              leading: const Icon(Icons.table_chart_rounded, color: Colors.green),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.green.withValues(alpha: 0.2))),
              onTap: () {
                Navigator.pop(context);
                final vm = context.read<DashboardViewModel>();
                final now =
                    DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
                final csv =
                    'UniTransit Report,$now\nStudents,${vm.totalStudents}\nDrivers,${vm.totalDrivers}\nRevenue,${vm.totalRevenue}\n';
                Clipboard.setData(ClipboardData(text: csv));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CSV copied to clipboard!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}