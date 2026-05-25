import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';
import 'package:unitransit_admin/core/utils/animations.dart';
import 'package:unitransit_admin/view_models/dashboard_view_model.dart';

class SafetyAlertsScreen extends StatefulWidget {
  const SafetyAlertsScreen({super.key});

  @override
  State<SafetyAlertsScreen> createState() => _SafetyAlertsScreenState();
}

class _SafetyAlertsScreenState extends State<SafetyAlertsScreen> {
  double _speedLimit = 60.0;
  bool _geofencingEnabled = true;
  bool _overspeedingEnabled = true;

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
              child: ListView(
                children: [
                  _buildSafetySection('Geofencing Policies', [
                    const ListTile(
                      title: Text('Route Deviation Alert'),
                      subtitle: Text('Notify admin if a bus moves more than 200m away from the planned route.'),
                      trailing: Icon(Icons.location_on_rounded, color: Colors.blue),
                    ),
                    SwitchListTile(
                      title: const Text('Enable Geofencing Alerts'),
                      value: _geofencingEnabled,
                      onChanged: (v) => setState(() => _geofencingEnabled = v),
                      activeColor: AppColors.primaryNavy,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildSafetySection('Speed Monitoring', [
                    ListTile(
                      title: const Text('Maximum Speed Limit'),
                      subtitle: Text('Current Limit: ${_speedLimit.toInt()} km/h'),
                      trailing: const Icon(Icons.speed_rounded, color: Colors.orange),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Slider(
                        value: _speedLimit,
                        min: 40,
                        max: 100,
                        divisions: 12,
                        label: '${_speedLimit.toInt()} km/h',
                        onChanged: (v) => setState(() => _speedLimit = v),
                        activeColor: AppColors.primaryNavy,
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Overspeeding Alerts'),
                      subtitle: Text('Notify admin if a bus exceeds ${_speedLimit.toInt()} km/h.'),
                      value: _overspeedingEnabled,
                      onChanged: (v) => setState(() => _overspeedingEnabled = v),
                      activeColor: AppColors.primaryNavy,
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildRecentAlerts(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Safety & Speed Control',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
        ),
        const Text('Configure real-time safety triggers and geofencing boundaries.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }

  Widget _buildSafetySection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryNavy)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRecentAlerts(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history_rounded, color: Colors.red),
              SizedBox(width: 12),
              Text('Recent Safety Violations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: context.read<DashboardViewModel>().onNewTripAlert.map((e) => [e]), // Placeholder logic for real-time violations
            builder: (context, snapshot) {
              final alerts = context.watch<DashboardViewModel>().emergencyAlerts;
              if (alerts.isEmpty) return const Text('No violations recorded.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary));
              
              return Column(
                children: alerts.take(5).map((a) {
                  final time = a['timestamp'] != null 
                    ? DateFormat('hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(a['timestamp']))
                    : 'Just now';
                  return _buildViolationItem('${a['driverName'] ?? 'Driver'} - ${a['message']}', time);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildViolationItem(String title, String time) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Text(time, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
