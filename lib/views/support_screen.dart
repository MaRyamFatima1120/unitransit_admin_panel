import 'package:flutter/material.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppResponsiveUtil.isMobile(context) ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Support Center',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              fontSize: AppResponsiveUtil.isMobile(context) ? 24 : null,
            ),
          ),
          const SizedBox(height: 4),
          const Text('Get help and manage support tickets.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: [
              _buildSupportCard(context, Icons.chat_bubble_outline_rounded, 'Live Chat', 'Chat with our tech support team.', Colors.blue),
              _buildSupportCard(context, Icons.email_outlined, 'Email Support', 'Send us an email at support@unitransit.com', Colors.purple),
              _buildSupportCard(context, Icons.menu_book_rounded, 'Documentation', 'Read the system manual and FAQs.', Colors.orange),
            ],
          ),
          const SizedBox(height: 40),
          const Text('Recent Support Tickets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: ListView.separated(
                itemCount: 4,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final tickets = [
                    {'id': '#T-5542', 'subject': 'Bus Tracking Delay', 'status': 'Open', 'color': Colors.red},
                    {'id': '#T-5541', 'subject': 'New Driver Login Issue', 'status': 'In Progress', 'color': Colors.orange},
                    {'id': '#T-5540', 'subject': 'Route Change Request', 'status': 'Closed', 'color': Colors.green},
                    {'id': '#T-5539', 'subject': 'App Crash on Android', 'status': 'Closed', 'color': Colors.green},
                  ];
                  final ticket = tickets[index];

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(ticket['subject'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('Ticket ID: ${ticket['id']}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (ticket['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(ticket['status'] as String, style: TextStyle(color: ticket['color'] as Color, fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard(BuildContext context, IconData icon, String title, String desc, Color color) {
    final width = AppResponsiveUtil.isMobile(context) ? double.infinity : (AppResponsiveUtil.isTablet(context) ? 300.0 : 350.0);
    return Container(
      width: width,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            desc, 
            style: TextStyle(
              color: AppResponsiveUtil.isMobile(context) ? Colors.transparent : AppColors.textSecondary, 
              fontSize: 14
            )
          ),
          if (AppResponsiveUtil.isMobile(context))
            const Text('Tap to open channel', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}
