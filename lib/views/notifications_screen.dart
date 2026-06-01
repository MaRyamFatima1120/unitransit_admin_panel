import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';
import 'package:unitransit_admin/view_models/dashboard_view_model.dart';
import 'package:unitransit_admin/view_models/notifications_view_model.dart';
import 'package:unitransit_admin/models/notification_model.dart';
import 'package:unitransit_admin/core/utils/animations.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _showSendAlertModal(BuildContext context) {
    final viewModel = context.read<NotificationsViewModel>();
    viewModel.resetForm();
    _titleController.clear();
    _messageController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return ChangeNotifierProvider.value(
          value: viewModel,
          child: Consumer<NotificationsViewModel>(
            builder: (context, model, child) {
              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Container(
                  width: 500,
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Send Broadcast Alert',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              if (!model.isSending)
                                IconButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This message will appear instantly on the target users\' mobile dashboards and trigger push notifications.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Title Field
                          Text(
                            'Alert Title',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _titleController,
                            enabled: !model.isSending,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'e.g. Schedule Delay Alert',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.borderLight),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.primaryNavy, width: 1.5),
                              ),
                            ),
                            onChanged: model.setTitle,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                          ),
                          const SizedBox(height: 16),

                          // Message Field
                          Text(
                            'Message Body',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _messageController,
                            enabled: !model.isSending,
                            maxLines: 3,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Type your announcement here...',
                              contentPadding: const EdgeInsets.all(16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.borderLight),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.primaryNavy, width: 1.5),
                              ),
                            ),
                            onChanged: model.setMessage,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Message is required' : null,
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              // Target Audience
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Target Audience',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.borderLight),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: model.targetAudience,
                                          isExpanded: true,
                                          style: TextStyle(fontSize: 13, color: AppColors.textDark),
                                          items: const [
                                            DropdownMenuItem(value: 'All', child: Text('All Users')),
                                            DropdownMenuItem(value: 'Students', child: Text('Students Only')),
                                            DropdownMenuItem(value: 'Drivers', child: Text('Drivers Only')),
                                            DropdownMenuItem(value: 'Specific', child: Text('Specific User')),
                                          ],
                                          onChanged: model.isSending
                                              ? null
                                              : (v) {
                                                  if (v != null) {
                                                    model.setTargetAudience(v);
                                                  }
                                                },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Alert Type
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Alert Severity',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: AppColors.borderLight),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: model.alertType,
                                          isExpanded: true,
                                          style: TextStyle(fontSize: 13, color: AppColors.textDark),
                                          items: const [
                                            DropdownMenuItem(value: 'info', child: Text('Info / Update')),
                                            DropdownMenuItem(value: 'alert', child: Text('Alert / Delay')),
                                            DropdownMenuItem(value: 'system', child: Text('System / Alert')),
                                          ],
                                          onChanged: model.isSending
                                              ? null
                                              : (v) {
                                                  if (v != null) {
                                                    model.setAlertType(v);
                                                  }
                                                },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          // Specific User Picker
                          if (model.targetAudience == 'Specific') ...[
                            const SizedBox(height: 16),
                            Text(
                              'Select Recipient User',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (model.isLoadingUsers)
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: LinearProgressIndicator(color: AppColors.primaryNavy),
                                ),
                              )
                            else if (model.eligibleUsers.isEmpty)
                              const Text('No eligible users found.', style: TextStyle(color: Colors.red, fontSize: 13))
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.borderLight),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: model.selectedUserId,
                                    isExpanded: true,
                                    style: TextStyle(fontSize: 13, color: AppColors.textDark),
                                    items: model.eligibleUsers.map((u) {
                                      return DropdownMenuItem<String>(
                                        value: u['uid'],
                                        child: Text('${u['name']} (${u['role']}) - ${u['email']}'),
                                      );
                                    }).toList(),
                                    onChanged: model.isSending ? null : model.setSelectedUserId,
                                  ),
                                ),
                              ),
                          ],
                          const SizedBox(height: 24),
                          
                          // Image Attachment Section
                          Text(
                            'Attach Image (Optional)',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (model.selectedImage != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.primaryNavy),
                                borderRadius: BorderRadius.circular(12),
                                color: AppColors.primaryNavy.withOpacity(0.05),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.image_rounded, size: 20, color: AppColors.primaryNavy),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      model.selectedImage!.name,
                                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: model.isSending ? null : model.removeImage,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            )
                          else
                            OutlinedButton.icon(
                              onPressed: model.isSending ? null : model.pickImage,
                              icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                              label: const Text('Browse Image'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryNavy,
                                side: BorderSide(color: AppColors.borderLight),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            
                          const SizedBox(height: 32),
                          
                          // Submit Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!model.isSending)
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                                ),
                              const SizedBox(width: 12),
                              SizedBox(
                                height: 46,
                                child: ElevatedButton.icon(
                                  onPressed: model.isSending ? null : () async {
                                    if (_formKey.currentState!.validate()) {
                                      final navigator = Navigator.of(dialogContext);
                                      final messenger = ScaffoldMessenger.of(context);
                                      try {
                                        await model.sendNotification();
                                        navigator.pop();
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text('Notification sent successfully to ${model.targetAudience}!'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } catch (e) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text('Error: $e'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  icon: model.isSending 
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Icon(Icons.send_rounded, size: 18),
                                  label: Text(model.isSending ? 'Sending...' : 'Send Alert'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryNavy,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardViewModel = context.watch<DashboardViewModel>();
    final systemNotifications = dashboardViewModel.notifications;
    final notificationsViewModel = context.watch<NotificationsViewModel>();
    final isMobile = AppResponsiveUtil.isMobile(context);
    final isTablet = AppResponsiveUtil.isTablet(context);

    return DefaultTabController(
      length: 2,
      child: FadeInSlide(
        duration: const Duration(milliseconds: 600),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Responsive Top Bar Section
              isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeInSlide(
                          direction: FadeInDirection.leftToRight,
                          child: Text(
                            'Notifications Hub',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                              fontSize: 24,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        FadeInSlide(
                          direction: FadeInDirection.leftToRight,
                          delay: const Duration(milliseconds: 100),
                          child: Text(
                            'Monitor automated system events and send broadcast announcements.',
                            style: GoogleFonts.inter(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeInSlide(
                          direction: FadeInDirection.bottomToTop,
                          delay: const Duration(milliseconds: 200),
                          child: SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: () => _showSendAlertModal(context),
                              icon: const Icon(Icons.add_alert_rounded, size: 18),
                              label: const Text('Send New Alert', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryNavy,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: FadeInSlide(
                            direction: FadeInDirection.leftToRight,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notifications Hub',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                    fontSize: isTablet ? 28 : 32,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Monitor automated system events and send broadcast announcements.',
                                  style: GoogleFonts.inter(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        FadeInSlide(
                          direction: FadeInDirection.rightToLeft,
                          child: ElevatedButton.icon(
                            onPressed: () => _showSendAlertModal(context),
                            icon: const Icon(Icons.add_alert_rounded, size: 18),
                            label: const Text('Send New Alert', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryNavy,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 28),

              // Tab Bar
              FadeInSlide(
                direction: FadeInDirection.leftToRight,
                delay: const Duration(milliseconds: 300),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 1.5)),
                  ),
                  child: TabBar(
                    isScrollable: AppResponsiveUtil.isMobile(context),
                    tabAlignment: AppResponsiveUtil.isMobile(context) ? TabAlignment.start : null,
                    labelColor: AppColors.primaryNavy,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primaryNavy,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 14),
                    unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: isMobile ? 12 : 14),
                    tabs: const [
                      Tab(text: 'System Activity Logs'),
                      Tab(text: 'Broadcast Alerts Center'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Tab Views
              Expanded(
                child: FadeInSlide(
                  direction: FadeInDirection.bottomToTop,
                  delay: const Duration(milliseconds: 400),
                  child: TabBarView(
                    children: [
                      // Tab 1: System Activity Logs
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: systemNotifications.isEmpty
                            ? _buildEmptyState('No system logs recorded.')
                            : Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${systemNotifications.length} Pending Notifications',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textDark,
                                            fontSize: 14,
                                          ),
                                        ),
                                        TextButton.icon(
                                          onPressed: () {
                                            context.read<DashboardViewModel>().clearAllNotifications();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: const Text('All notifications marked as read.'),
                                                backgroundColor: Colors.green.shade600,
                                                duration: const Duration(seconds: 1),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.done_all_rounded, size: 18, color: Colors.green),
                                          label: Text(
                                            'Mark All Read',
                                            style: GoogleFonts.poppins(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Divider(height: 1, color: AppColors.borderLight),
                                  Expanded(
                                    child: ListView.separated(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      itemCount: systemNotifications.length,
                                      separatorBuilder: (context, index) => Divider(height: 1, color: AppColors.borderLight),
                                      itemBuilder: (context, index) {
                                        final notification = systemNotifications[index];
                                        return _NotificationRow(notification: notification, isMobile: isMobile);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                      ),

                      // Tab 2: Broadcast Alerts Center
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: notificationsViewModel.getSentNotifications(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator(color: AppColors.primaryNavy));
                          }
                          
                          final alerts = snapshot.data ?? [];
                          
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.cardWhite,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: alerts.isEmpty
                                ? _buildEmptyState('No broadcast alerts sent yet.')
                                : ListView.separated(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    itemCount: alerts.length,
                                    separatorBuilder: (context, index) => Divider(height: 1, color: AppColors.borderLight),
                                    itemBuilder: (context, index) {
                                      final alert = alerts[index];
                                      return _BroadcastRow(alert: alert, isMobile: isMobile);
                                    },
                                  ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}


class _NotificationRow extends StatefulWidget {
  final SystemNotificationModel notification;
  final bool isMobile;
  const _NotificationRow({required this.notification, required this.isMobile});

  @override
  State<_NotificationRow> createState() => _NotificationRowState();
}

class _NotificationRowState extends State<_NotificationRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: _isHovered ? AppColors.primaryNavy.withValues(alpha: 0.02) : Colors.transparent,
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 16 : 24, vertical: 12),
          leading: AnimatedScale(
            scale: _isHovered ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: notification.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                notification.type == NotificationType.support ? Icons.support_agent_rounded : Icons.notifications_active_rounded,
                color: notification.color,
                size: 20,
              ),
            ),
          ),
          title: Text(
            notification.title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: _isHovered ? AppColors.primaryNavy : AppColors.textDark),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification.message,
                style: GoogleFonts.inter(color: AppColors.textDark, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 6),
              Text(
                DateFormat('MMM dd • hh:mm a').format(notification.timestamp),
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 10),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.isMobile)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    notification.type.name.toUpperCase(),
                    style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
              const SizedBox(width: 8),
              _DismissButton(onPressed: () {
                context.read<DashboardViewModel>().dismissNotification(notification.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Notification marked as read & dismissed.'),
                    backgroundColor: Colors.green.shade600,
                    duration: const Duration(seconds: 1),
                  ),
                );
              }),
            ],
          ),
          onTap: () {
            if (notification.type == NotificationType.support) {
              context.read<DashboardViewModel>().setSelectedIndex(9); // Index 9 is Support Center
            } else if (notification.type == NotificationType.warning) {
              context.read<DashboardViewModel>().setSelectedIndex(12); // Index 12 is Emergency SOS
            }
          },
        ),
      ),
    );
  }
}

class _BroadcastRow extends StatefulWidget {
  final Map<String, dynamic> alert;
  final bool isMobile;
  const _BroadcastRow({required this.alert, required this.isMobile});

  @override
  State<_BroadcastRow> createState() => _BroadcastRowState();
}

class _BroadcastRowState extends State<_BroadcastRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final type = alert['type'] ?? 'info';
    final target = alert['targetAudience'] ?? 'All';
    final timestamp = alert['timestamp'] as DateTime;

    Color badgeColor = Colors.blue;
    IconData icon = Icons.info_outline;

    if (type == 'alert') {
      badgeColor = Colors.orange;
      icon = Icons.warning_amber_rounded;
    } else if (type == 'system') {
      badgeColor = Colors.red;
      icon = Icons.crisis_alert_rounded;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: _isHovered ? AppColors.primaryNavy.withValues(alpha: 0.02) : Colors.transparent,
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: widget.isMobile ? 16 : 24, vertical: 12),
          leading: AnimatedScale(
            scale: _isHovered ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: badgeColor,
                size: 20,
              ),
            ),
          ),
          title: Text(
            alert['title'] ?? '',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: _isHovered ? AppColors.primaryNavy : AppColors.textDark),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                alert['message'] ?? '',
                style: GoogleFonts.inter(color: AppColors.textDark, fontSize: 12, height: 1.4),
              ),
              if (alert['imageUrl'] != null && alert['imageUrl'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        contentPadding: EdgeInsets.zero,
                        content: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: alert['imageUrl'],
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
                            errorWidget: (context, url, error) => const SizedBox(height: 100, child: Center(child: Icon(Icons.error))),
                          ),
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: alert['imageUrl'],
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: AppColors.borderLight, height: 60, width: 60, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                      errorWidget: (context, url, error) => Container(color: AppColors.borderLight, height: 60, width: 60, child: const Icon(Icons.error, size: 20)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    DateFormat('MMM dd • hh:mm a').format(timestamp),
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 10),
                  ),
                  Icon(Icons.circle, size: 4, color: AppColors.textSecondary),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryNavy.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Sent to: $target',
                      style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.primaryNavy),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: !widget.isMobile
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    type.toUpperCase(),
                    style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: badgeColor, letterSpacing: 0.5),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _DismissButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _DismissButton({required this.onPressed});

  @override
  State<_DismissButton> createState() => _DismissButtonState();
}

class _DismissButtonState extends State<_DismissButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Tooltip(
        message: 'Dismiss',
        child: IconButton(
          icon: Icon(
            Icons.check_circle_outline_rounded,
            color: _isHovered ? Colors.green : Colors.green.withValues(alpha: 0.5),
            size: 22,
          ),
          onPressed: widget.onPressed,
        ),
      ),
    );
  }
}

