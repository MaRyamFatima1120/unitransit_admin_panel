import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/view_models/support_view_model.dart';
import 'package:unitransit_admin/models/support_ticket_model.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppResponsiveUtil.isMobile(context);
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            SizedBox(height: isMobile ? 24 : 32),
            Expanded(
              child: Consumer<SupportViewModel>(
                builder: (context, viewModel, child) {
                  if (viewModel.isLoading && viewModel.tickets.isEmpty) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primaryNavy));
                  }
                  if (viewModel.tickets.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildTicketList(context, viewModel);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final bool isMobile = AppResponsiveUtil.isMobile(context);
    
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Support Management',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    letterSpacing: -0.5,
                    fontSize: isMobile ? 24 : 32,
                  ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.liveStatus, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Live monitoring active • Real-time tickets',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        _buildStatsSummary(context),
      ],
    );
  }

  Widget _buildStatsSummary(BuildContext context) {
    final viewModel = context.watch<SupportViewModel>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildQuickStat('New', viewModel.pendingTickets.length.toString(), Colors.orange),
        const SizedBox(width: 12),
        _buildQuickStat('Resolved', viewModel.resolvedTickets.length.toString(), AppColors.primaryTeal),
      ],
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: AppColors.backgroundLight, shape: BoxShape.circle),
            child: Icon(Icons.check_circle_outline_rounded, size: 60, color: AppColors.primaryTeal.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          const Text('All caught up!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
          const SizedBox(height: 8),
          const Text('There are no active support tickets at the moment.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTicketList(BuildContext context, SupportViewModel viewModel) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: viewModel.tickets.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final ticket = viewModel.tickets[index];
        return _buildTicketCard(context, ticket, viewModel);
      },
    );
  }

  Widget _buildTicketCard(BuildContext context, SupportTicketModel ticket, SupportViewModel viewModel) {
    final bool isMobile = AppResponsiveUtil.isMobile(context);
    final String status = ticket.status.toLowerCase();
    final bool isPending = status == 'pending';
    final bool isInProgress = status == 'in progress';
    final bool canReply = isPending || isInProgress;
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: _getStatusColor(ticket.status)),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppColors.backgroundLight,
                                  child: Icon(
                                    ticket.userRole.toLowerCase() == 'driver' ? Icons.drive_eta_rounded : Icons.school_rounded,
                                    color: AppColors.primaryNavy,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SelectableText(
                                        ticket.name.isNotEmpty ? ticket.name : 'Anonymous',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                                      ),
                                      SelectableText(
                                        '${ticket.userRole} • ID: ${ticket.userId.substring(0, 8)}...',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildStatusBadge(ticket.status),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLight.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('ISSUE DESCRIPTION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: ticket.issue));
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Issue copied to clipboard'), duration: Duration(seconds: 1)));
                                  },
                                  child: const Icon(Icons.copy_rounded, size: 14, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              ticket.issue,
                              style: const TextStyle(color: AppColors.textDark, fontSize: 14, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Contact Info Row/Column
                      isMobile 
                        ? Column(
                            children: [
                              _buildContactInfo(context, Icons.email_outlined, ticket.email),
                              const SizedBox(height: 8),
                              _buildContactInfo(context, Icons.phone_outlined, ticket.phone),
                            ],
                          )
                        : Row(
                            children: [
                              _buildContactInfo(context, Icons.email_outlined, ticket.email),
                              const SizedBox(width: 24),
                              _buildContactInfo(context, Icons.phone_outlined, ticket.phone),
                            ],
                          ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: AppColors.borderLight),
                      const SizedBox(height: 16),
                      // Actions Row/Column
                      if (isMobile)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('MMM dd • hh:mm a').format(ticket.timestamp),
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            ),
                            const SizedBox(height: 12),
                            if (canReply)
                              Row(
                                children: [
                                  Expanded(child: _buildReplyButton(context, ticket, viewModel)),
                                  if (isPending) ...[
                                    const SizedBox(width: 8),
                                    Expanded(child: _buildAcknowledgeButton(ticket, viewModel)),
                                  ],
                                ],
                              )
                            else if (ticket.adminReply != null)
                              _buildViewResolutionButton(context, ticket),
                          ],
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('MMM dd, yyyy • hh:mm a').format(ticket.timestamp),
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            if (canReply)
                              Row(
                                children: [
                                  _buildReplyButton(context, ticket, viewModel),
                                  if (isPending) ...[
                                    const SizedBox(width: 12),
                                    _buildAcknowledgeButton(ticket, viewModel),
                                  ],
                                ],
                              )
                            else if (ticket.adminReply != null)
                              _buildViewResolutionButton(context, ticket),
                          ],
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

  Widget _buildReplyButton(BuildContext context, SupportTicketModel ticket, SupportViewModel viewModel) {
    return ElevatedButton.icon(
      onPressed: () => _showProfessionalReplyDialog(context, ticket, viewModel),
      icon: const Icon(Icons.reply_rounded, size: 18),
      label: const Text('Reply & Resolve'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  Widget _buildAcknowledgeButton(SupportTicketModel ticket, SupportViewModel viewModel) {
    return OutlinedButton(
      onPressed: () => viewModel.updateStatus(ticket.id, 'In Progress'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryNavy,
        side: const BorderSide(color: AppColors.primaryNavy),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: const Text('Acknowledge', style: TextStyle(fontSize: 13)),
    );
  }

  Widget _buildViewResolutionButton(BuildContext context, SupportTicketModel ticket) {
    return TextButton.icon(
      onPressed: () => _showTicketDetails(context, ticket),
      icon: const Icon(Icons.visibility_outlined, size: 16),
      label: const Text('View Resolution'),
      style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
    );
  }

  Widget _buildContactInfo(BuildContext context, IconData icon, String value) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$value copied to clipboard'), duration: const Duration(seconds: 1)));
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Flexible(
            child: SelectableText(
              value, 
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.copy_rounded, size: 10, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'in progress': return AppColors.primaryNavy;
      case 'resolved': return AppColors.primaryTeal;
      default: return AppColors.primaryNavy;
    }
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 9)),
    );
  }

  void _showProfessionalReplyDialog(BuildContext context, SupportTicketModel ticket, SupportViewModel viewModel) {
    final replyController = TextEditingController();
    final bool isMobile = AppResponsiveUtil.isMobile(context);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: isMobile ? double.infinity : 600,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Support Resolution',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      Text(
                        'Provide a professional response to the user.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Ticket Summary
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.primaryNavy.withOpacity(0.1),
                          child: const Icon(Icons.person_rounded, size: 14, color: AppColors.primaryNavy),
                        ),
                        const SizedBox(width: 8),
                        Text(ticket.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const Spacer(),
                        _buildStatusBadge(ticket.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('USER MESSAGE:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(ticket.issue, style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.textDark)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text('YOUR OFFICIAL RESPONSE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1)),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: replyController,
                  maxLines: 10,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Describe the resolution or provide guidance...',
                    hintStyle: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primaryTeal, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (replyController.text.trim().isNotEmpty) {
                        viewModel.updateStatus(ticket.id, 'Resolved', reply: replyController.text.trim());
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ticket resolved and response sent!'), backgroundColor: AppColors.primaryTeal),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Send Resolution & Close', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTicketDetails(BuildContext context, SupportTicketModel ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ticket Resolution Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ADMIN RESPONSE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.backgroundLight, borderRadius: BorderRadius.circular(12)),
              child: SelectableText(ticket.adminReply ?? 'No reply found.', style: const TextStyle(color: AppColors.textDark, height: 1.5)),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.event_available_rounded, size: 16, color: AppColors.primaryTeal),
                const SizedBox(width: 8),
                const Text('Case resolved successfully', style: TextStyle(color: AppColors.primaryTeal, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}
