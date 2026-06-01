import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/view_models/support_view_model.dart';
import 'package:unitransit_admin/models/support_ticket_model.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';
import 'package:unitransit_admin/core/utils/animations.dart';

const Color _resolvedBlue = Color(0xFF1E88E5);

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedTab = 'All'; // 'All', 'Pending', 'In Progress', 'Resolved'
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = AppResponsiveUtil.isMobile(context);
    final viewModel = context.watch<SupportViewModel>();

    // Apply Filter & Search logic
    final List<SupportTicketModel> filteredTickets = viewModel.tickets.where((ticket) {
      // 1. Tab Filter
      if (_selectedTab == 'Pending' && ticket.status.toLowerCase() != 'pending') return false;
      if (_selectedTab == 'In Progress' && ticket.status.toLowerCase() != 'in progress') return false;
      if (_selectedTab == 'Resolved' &&
          (ticket.status.toLowerCase() != 'resolved' && ticket.status.toLowerCase() != 'closed')) return false;

      // 2. Search Query Filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = ticket.name.toLowerCase().contains(query);
        final roleMatch = ticket.userRole.toLowerCase().contains(query);
        final emailMatch = ticket.email.toLowerCase().contains(query);
        final issueMatch = ticket.issue.toLowerCase().contains(query);
        return nameMatch || roleMatch || emailMatch || issueMatch;
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FadeInSlide(
        duration: const Duration(milliseconds: 600),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              _buildFilterAndSearchSection(isMobile),
              const SizedBox(height: 20),
              viewModel.isLoading && viewModel.tickets.isEmpty
                  ? Center(child: CircularProgressIndicator(color: AppColors.primaryNavy))
                  : filteredTickets.isEmpty
                      ? FadeInSlide(
                          direction: FadeInDirection.bottomToTop,
                          child: _buildEmptyState()
                        )
                      : _buildTicketList(context, filteredTickets, viewModel),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final bool isMobile = AppResponsiveUtil.isMobile(context);
    
    return FadeInSlide(
      direction: FadeInDirection.leftToRight,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 24,
        runSpacing: 24,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Support Tickets',
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
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Live monitoring active • Real-time tickets',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          _buildStatsSummary(context),
        ],
      ),
    );
  }

  Widget _buildStatsSummary(BuildContext context) {
    final viewModel = context.watch<SupportViewModel>();
    final newCount = viewModel.pendingTickets.length.toString();
    final progressCount = viewModel.tickets.where((t) => t.status.toLowerCase() == 'in progress').length.toString();
    final resolvedCount = viewModel.resolvedTickets.length.toString();

    final stats = [
      {'label': 'New', 'value': newCount, 'icon': Icons.assignment_late_rounded, 'color': AppColors.accentAmber},
      {'label': 'In Progress', 'value': progressCount, 'icon': Icons.assignment_ind_rounded, 'color': AppColors.primaryNavy},
      {'label': 'Resolved', 'value': resolvedCount, 'icon': Icons.assignment_turned_in_rounded, 'color': _resolvedBlue},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(stats.length, (i) => FadeInSlide(
        direction: FadeInDirection.rightToLeft,
        delay: Duration(milliseconds: 100 * (i + 1)),
        child: _buildQuickStat(
          stats[i]['label'] as String, 
          stats[i]['value'] as String, 
          stats[i]['icon'] as IconData, 
          stats[i]['color'] as Color
        ),
      )),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon, Color color) {
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNavy : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryNavy : AppColors.borderLight,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryNavy.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterAndSearchSection(bool isMobile) {
    return FadeInSlide(
      direction: FadeInDirection.bottomToTop,
      delay: const Duration(milliseconds: 400),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 16,
        children: [
          // Tabs
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['All', 'Pending', 'In Progress', 'Resolved'].map((tab) {
              final isSelected = _selectedTab == tab;
              return _buildCustomTabChip(tab, isSelected, () {
                setState(() => _selectedTab = tab);
              });
            }).toList(),
          ),
          
          // Search Bar
          Container(
            width: isMobile ? double.infinity : 320,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.015),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
              style: TextStyle(fontSize: 14, color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'Search by name, role, email, issue...',
                hintStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderLight, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _resolvedBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                size: 60,
                color: _resolvedBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No tickets found!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Either there are no active support tickets or your search match failed.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketList(BuildContext context, List<SupportTicketModel> tickets, SupportViewModel viewModel) {
    return FadeInSlide(
      direction: FadeInDirection.bottomToTop,
      delay: const Duration(milliseconds: 500),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tickets.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          return _TicketCard(ticket: ticket, viewModel: viewModel);
        },
      ),
    );
  }
}

class _TicketCard extends StatefulWidget {
  final SupportTicketModel ticket;
  final SupportViewModel viewModel;
  const _TicketCard({required this.ticket, required this.viewModel});

  @override
  State<_TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<_TicketCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    final viewModel = widget.viewModel;
    final bool isMobile = AppResponsiveUtil.isMobile(context);
    final String status = ticket.status.toLowerCase();
    final bool isPending = status == 'pending';
    final bool isInProgress = status == 'in progress';
    final bool canReply = isPending || isInProgress;
    final Color statusColor = _getStatusColor(ticket.status);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _isHovered ? statusColor.withValues(alpha: 0.5) : AppColors.borderLight, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? statusColor.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.015),
              blurRadius: _isHovered ? 20 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 6, color: statusColor),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  AnimatedScale(
                                    scale: _isHovered ? 1.1 : 1.0,
                                    duration: const Duration(milliseconds: 200),
                                    child: CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.08),
                                      child: Icon(
                                        ticket.userRole.toLowerCase() == 'driver'
                                            ? Icons.drive_eta_rounded
                                            : Icons.school_rounded,
                                        color: AppColors.primaryNavy,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: SelectableText(
                                                ticket.name.isNotEmpty ? ticket.name : 'Anonymous',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: AppColors.textDark,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            _buildRoleBadge(ticket.userRole),
                                            if (!ticket.adminRead) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.error,
                                                  borderRadius: BorderRadius.circular(6),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: AppColors.error.withValues(alpha: 0.3),
                                                      blurRadius: 4,
                                                      offset: const Offset(0, 2),
                                                    )
                                                  ],
                                                ),
                                                child: const Text(
                                                  'NEW',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        SelectableText(
                                          'ID: ${ticket.userId.length > 12 ? ticket.userId.substring(0, 12) : ticket.userId}...',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
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
                        
                        // Issue Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundLight.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderLight, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.forum_outlined,
                                        size: 14,
                                        color: AppColors.primaryNavy.withValues(alpha: 0.7),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'ISSUE DESCRIPTION',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textSecondary,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        Clipboard.setData(ClipboardData(text: ticket.issue));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Issue copied to clipboard'),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(4),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: Icon(
                                          Icons.copy_rounded,
                                          size: 14,
                                          color: AppColors.primaryNavy.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SelectableText(
                                ticket.issue,
                                style: TextStyle(
                                  color: AppColors.textDark,
                                  fontSize: 14,
                                  height: 1.4,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Contact details
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _buildContactBadge(context, Icons.email_outlined, ticket.email),
                            _buildContactBadge(context, Icons.phone_outlined, ticket.phone),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(height: 1, color: AppColors.borderLight),
                        const SizedBox(height: 16),
                        
                        // Footer/Actions Row
                        isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      DateFormat('MMM dd • hh:mm a').format(ticket.timestamp),
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (canReply)
                                  Row(
                                    children: [
                                      if (isPending) ...[
                                        Expanded(child: _buildAcknowledgeButton(ticket, viewModel)),
                                        const SizedBox(width: 8),
                                      ],
                                      Expanded(child: _buildReplyButton(context, ticket, viewModel)),
                                      if (!ticket.adminRead) ...[
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.mark_chat_read_rounded, color: _resolvedBlue, size: 22),
                                          tooltip: 'Mark as Read',
                                          onPressed: () => viewModel.updateStatus(ticket.id, ticket.status),
                                        ),
                                      ],
                                    ],
                                  )
                                else if (ticket.adminReply != null)
                                  SizedBox(
                                    width: double.infinity,
                                    child: _buildViewResolutionButton(context, ticket),
                                  ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Text(
                                      DateFormat('MMM dd, yyyy • hh:mm a').format(ticket.timestamp),
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                    ),
                                  ],
                                ),
                                if (canReply)
                                  Row(
                                    children: [
                                      if (isPending) ...[
                                        _buildAcknowledgeButton(ticket, viewModel),
                                        const SizedBox(width: 12),
                                      ],
                                      _buildReplyButton(context, ticket, viewModel),
                                      if (!ticket.adminRead) ...[
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.mark_chat_read_rounded, color: _resolvedBlue, size: 22),
                                          tooltip: 'Mark as Read',
                                          onPressed: () => viewModel.updateStatus(ticket.id, ticket.status),
                                        ),
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
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    final bool isDriver = role.toLowerCase() == 'driver';
    final Color badgeColor = isDriver ? AppColors.primaryNavy : AppColors.accentAmber;
    final Color textColor = isDriver ? AppColors.primaryNavy : const Color(0xFFB7791F); // Darker amber for readability
    final Color bgColor = isDriver ? AppColors.primaryNavy.withValues(alpha: 0.08) : AppColors.accentAmber.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildContactBadge(BuildContext context, IconData icon, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$value copied to clipboard'),
              duration: const Duration(seconds: 1),
              backgroundColor: AppColors.primaryNavy,
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.backgroundLight.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderLight, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.copy_rounded, size: 10, color: AppColors.textSecondary.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyButton(BuildContext context, SupportTicketModel ticket, SupportViewModel viewModel) {
    return ElevatedButton.icon(
      onPressed: () => _showProfessionalReplyDialog(context, ticket, viewModel),
      icon: const Icon(Icons.reply_rounded, size: 16),
      label: const Text(
        'Reply & Resolve',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: _resolvedBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  Widget _buildAcknowledgeButton(SupportTicketModel ticket, SupportViewModel viewModel) {
    return OutlinedButton.icon(
      onPressed: () => viewModel.updateStatus(ticket.id, 'In Progress'),
      icon: const Icon(Icons.assignment_ind_outlined, size: 16),
      label: const Text(
        'Acknowledge',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryNavy,
        side: BorderSide(color: AppColors.primaryNavy, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  Widget _buildViewResolutionButton(BuildContext context, SupportTicketModel ticket) {
    return OutlinedButton.icon(
      onPressed: () => _showTicketDetails(context, ticket),
      icon: const Icon(Icons.done_all_rounded, size: 16),
      label: const Text(
        'View Resolution',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: _resolvedBlue,
        side: BorderSide(color: _resolvedBlue, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.accentAmber;
      case 'in progress':
        return AppColors.primaryNavy;
      case 'resolved':
      case 'closed':
        return _resolvedBlue;
      default:
        return AppColors.primaryNavy;
    }
  }

  Widget _buildStatusBadge(String status) {
    final Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
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
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _resolvedBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.rate_review_rounded, color: _resolvedBlue, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Support Resolution',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          ),
                          Text(
                            'Send response and mark ticket as resolved',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Ticket details summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
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
                          backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.1),
                          child: Icon(Icons.person_rounded, size: 14, color: AppColors.primaryNavy),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ticket.name.isNotEmpty ? ticket.name : 'Anonymous',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                        ),
                        const Spacer(),
                        _buildStatusBadge(ticket.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'ISSUE MESSAGE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket.issue,
                      style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textDark),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'YOUR OFFICIAL RESPONSE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TextField(
                  controller: replyController,
                  maxLines: 8,
                  autofocus: true,
                  style: TextStyle(fontSize: 14, color: AppColors.textDark),
                  decoration: InputDecoration(
                    hintText: 'Provide resolution details, explanation, or instructions...',
                    hintStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.borderLight, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _resolvedBlue, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (replyController.text.trim().isNotEmpty) {
                        viewModel.updateStatus(ticket.id, 'Resolved', reply: replyController.text.trim());
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ticket resolved and response sent!'),
                            backgroundColor: _resolvedBlue,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text(
                      'Send & Close Ticket',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _resolvedBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _resolvedBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.done_all_rounded, color: _resolvedBlue, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Ticket Resolution Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ADMIN RESPONSE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: SelectableText(
                ticket.adminReply ?? 'No reply found.',
                style: TextStyle(color: AppColors.textDark, height: 1.5, fontSize: 14),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.check_circle_outline_rounded, size: 16, color: _resolvedBlue),
                const SizedBox(width: 8),
                const Text(
                  'Case resolved successfully',
                  style: TextStyle(
                    color: _resolvedBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}