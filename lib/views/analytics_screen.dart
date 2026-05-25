import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';
import 'package:unitransit_admin/view_models/dashboard_view_model.dart';
import 'package:unitransit_admin/core/utils/animations.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedReportType = 'Trips';

  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsiveUtil.isMobile(context);

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
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSummaryGrid(context),
                    const SizedBox(height: 32),
                    _buildDetailedCharts(context),
                    const SizedBox(height: 32),
                    _buildExportSection(context),
                  ],
                ),
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
                  ),
            ),
            const Text('Detailed insights and data export tools.',
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
      ],
    );
  }

  Widget _buildSummaryGrid(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 700 ? 2 : 1);
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 2,
        children: [
          _buildAnalyticCard('Total Revenue', 'Rs. ${viewModel.totalRevenue.toStringAsFixed(0)}', Icons.payments_rounded, Colors.green),
          _buildAnalyticCard('Trip Success Rate', '98.5%', Icons.verified_rounded, Colors.blue),
          _buildAnalyticCard('Peak Hour Usage', '08:00 AM', Icons.access_time_filled_rounded, Colors.orange),
          _buildAnalyticCard('Fuel Efficiency', '12.4 km/l', Icons.local_gas_station_rounded, Colors.purple),
        ],
      );
    });
  }

  Widget _buildAnalyticCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
              Text(value, style: const TextStyle(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.w900)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedCharts(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            height: 400,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Operational Efficiency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 24),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      barGroups: [
                        BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 8, color: Colors.blue, width: 20)]),
                        BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 15, color: Colors.orange, width: 20)]),
                        BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 10, color: Colors.green, width: 20)]),
                        BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 18, color: Colors.purple, width: 20)]),
                        BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 12, color: Colors.red, width: 20)]),
                      ],
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
              height: 400,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('User Distribution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 40),
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(value: 65, title: 'Students', color: Colors.blue, radius: 50),
                          PieChartSectionData(value: 20, title: 'Staff', color: Colors.green, radius: 50),
                          PieChartSectionData(value: 15, title: 'Drivers', color: Colors.orange, radius: 50),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildExportSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryNavy.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primaryNavy),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Automated Reports', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('You can schedule weekly PDF reports to be sent to university management.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primaryNavy),
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export System Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select the type of report you want to generate:'),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('Trips History (CSV)'),
              leading: const Icon(Icons.table_chart_rounded, color: Colors.green),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Student Database (Excel)'),
              leading: const Icon(Icons.people_rounded, color: Colors.blue),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('Financial Summary (PDF)'),
              leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
