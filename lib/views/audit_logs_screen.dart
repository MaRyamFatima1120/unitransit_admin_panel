import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/services/firebase_service.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';
import 'package:unitransit_admin/models/audit_log_model.dart';
import 'package:unitransit_admin/core/utils/animations.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final ScrollController _horizontalScrollController = ScrollController();
  String _searchQuery = '';

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = context.read<FirebaseService>();

    return FadeInSlide(
      duration: const Duration(milliseconds: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(AppResponsiveUtil.isMobile(context) ? 16 : 32),
            child: _buildHeader(context),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.5))),
              ),
              child: Column(
                children: [
                  _buildToolbar(context),
                  Expanded(
                    child: StreamBuilder<List<AuditLogModel>>(
                      stream: firebaseService.getAuditLogs(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        var logs = snapshot.data ?? [];
                        if (_searchQuery.isNotEmpty) {
                          logs = logs.where((log) =>
                            log.adminName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            log.action.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            log.target.toLowerCase().contains(_searchQuery.toLowerCase())
                          ).toList();
                        }

                        if (logs.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.assignment_rounded, size: 64, color: Colors.grey.shade200),
                                const SizedBox(height: 16),
                                Text('No audit logs found.', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          );
                        }

                        return _buildLogsTable(context, logs);
                      },
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

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'System Audit Logs',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
                letterSpacing: -0.5,
                fontSize: AppResponsiveUtil.isMobile(context) ? 24 : null,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Track all administrative actions across the system for security and auditing.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: AppResponsiveUtil.isMobile(context) ? 200 : 350,
            height: 45,
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by Admin, Action...',
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: AppColors.backgroundLight.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.borderLight),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const Spacer(),
          if (!AppResponsiveUtil.isMobile(context))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.security_rounded, color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Text('Super Admin View', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLogsTable(BuildContext context, List<AuditLogModel> logs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          controller: _horizontalScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: Container(
                width: constraints.maxWidth > 1000 ? constraints.maxWidth - 48 : 1000,
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  children: [
                    _buildTableHeader(),
                    const Divider(height: 1),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: logs.length,
                      separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (context, index) => _LogItem(log: logs[index]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy.withValues(alpha: 0.02),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text('TIMESTAMP', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
          Expanded(flex: 2, child: Text('ADMIN NAME', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
          Expanded(flex: 2, child: Text('ACTION', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
          Expanded(flex: 3, child: Text('TARGET', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
        ],
      ),
    );
  }
}

class _LogItem extends StatefulWidget {
  final AuditLogModel log;
  const _LogItem({required this.log});

  @override
  State<_LogItem> createState() => _LogItemState();
}

class _LogItemState extends State<_LogItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(widget.log.timestamp);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.primaryNavy.withValues(alpha: 0.02) : Colors.transparent,
        ),
        child: Row(
          children: [
            Expanded(flex: 2, child: Text(dateStr, style: TextStyle(fontSize: 12, color: AppColors.textSecondary))),
            Expanded(
              flex: 2, 
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: AppColors.primaryNavy.withValues(alpha: 0.1),
                    child: Text(widget.log.adminName[0].toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryNavy)),
                  ),
                  const SizedBox(width: 8),
                  Text(widget.log.adminName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                ],
              )
            ),
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getActionColor(widget.log.action).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.log.action,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getActionColor(widget.log.action)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(flex: 3, child: Text(widget.log.target, style: TextStyle(fontSize: 13, color: AppColors.textDark))),
          ],
        ),
      ),
    );
  }

  Color _getActionColor(String action) {
    final act = action.toLowerCase();
    if (act.contains('deleted') || act.contains('removed')) return Colors.red;
    if (act.contains('added') || act.contains('created')) return Colors.green;
    if (act.contains('updated') || act.contains('edited')) return Colors.blue;
    return AppColors.primaryNavy;
  }
}