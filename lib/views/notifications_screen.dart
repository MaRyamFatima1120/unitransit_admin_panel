import 'package:flutter/material.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                    'Notifications',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      fontSize: AppResponsiveUtil.isMobile(context) ? 24 : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text('Manage system-wide alerts and announcements.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_alert_rounded, size: 18),
                label: const Text('Send New Alert'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: ListView.separated(
                itemCount: 10,
                separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.borderLight),
                itemBuilder: (context, index) {
                  final alerts = [
                    {'title': 'Heavy Traffic on Route A', 'time': '5 mins ago', 'type': 'Warning', 'color': Colors.orange},
                    {'title': 'System Maintenance Tonight', 'time': '1 hour ago', 'type': 'System', 'color': Colors.blue},
                    {'title': 'Bus #12 Speeding Alert', 'time': '2 hours ago', 'type': 'Urgent', 'color': Colors.red},
                    {'title': 'New Driver Registration Approved', 'time': '5 hours ago', 'type': 'Success', 'color': Colors.green},
                  ];
                  final alert = alerts[index % alerts.length];

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (alert['color'] as Color).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.notifications_active_rounded, color: alert['color'] as Color, size: 20),
                    ),
                    title: Text(alert['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(alert['time'] as String, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    trailing: !AppResponsiveUtil.isMobile(context) ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(alert['type'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ) : null,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
