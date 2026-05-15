import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';
import 'package:unitransit_admin/view_models/dashboard_view_model.dart';
import 'package:unitransit_admin/models/notification_model.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();
    final notifications = viewModel.notifications;

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
                  const Text('Manage system-wide alerts and support requests.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
              child: notifications.isEmpty 
                ? _buildEmptyState()
                : ListView.separated(
                    itemCount: notifications.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.borderLight),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _buildNotificationTile(context, notification);
                    },
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('No new notifications', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, SystemNotificationModel notification) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notification.color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          notification.type == NotificationType.support ? Icons.support_agent_rounded : Icons.notifications_active_rounded,
          color: notification.color,
          size: 22,
        ),
      ),
      title: Text(notification.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(notification.message, style: const TextStyle(color: AppColors.textDark, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            DateFormat('MMM dd • hh:mm a').format(notification.timestamp),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
      trailing: !AppResponsiveUtil.isMobile(context) ? Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          notification.type.name.toUpperCase(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ) : null,
      onTap: () {
        // Logically, clicking a support notification should take you to the Support Screen
        if (notification.type == NotificationType.support) {
          context.read<DashboardViewModel>().setSelectedIndex(8); // Index 8 is Support Center
        }
      },
    );
  }
}
