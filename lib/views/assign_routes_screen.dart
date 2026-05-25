import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/services/firebase_service.dart';
import 'package:unitransit_admin/models/driver_model.dart';
import 'package:unitransit_admin/models/bus_schedule_model.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';
import 'package:unitransit_admin/view_models/dashboard_view_model.dart';
import 'package:unitransit_admin/view_models/buses_view_model.dart';


class AssignRoutesScreen extends StatefulWidget {
  const AssignRoutesScreen({super.key});

  @override
  State<AssignRoutesScreen> createState() => _AssignRoutesScreenState();
}

class _AssignRoutesScreenState extends State<AssignRoutesScreen> {
  BusSchedule? _selectedSchedule;
  String? _selectedDriverId;
  String? _selectedDriverName;
  final TextEditingController _conductorController = TextEditingController();
  final TextEditingController _busController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  bool _isSaving = false;
  String _searchQuery = '';

  // Calendar Selection State
  late DateTime _selectedDate;
  late DateTime _currentMonth;
  late ScrollController _calendarScrollController;
  final List<String> _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _calendarScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDate());
  }

  @override
  void dispose() {
    _conductorController.dispose();
    _busController.dispose();
    _timeController.dispose();
    _calendarScrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedDate() {
    if (_calendarScrollController.hasClients) {
      final index = _selectedDate.day - 1;
      _calendarScrollController.animateTo(
        index * 58.0, // Approximate width of one calendar item (58 width + 10 margin)
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  List<DateTime> _generateDaysInMonth(DateTime month) {
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    return List.generate(
      lastDayOfMonth.day,
      (index) => DateTime(month.year, month.month, index + 1),
    );
  }

  String _getMonthName(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[date.month - 1];
  }

  String _getWeekdayName(DateTime date) {
    return _weekdays[date.weekday - 1];
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + offset);
      // Select first day of the new month
      if (_currentMonth.year == DateTime.now().year && _currentMonth.month == DateTime.now().month) {
        _selectedDate = DateTime.now();
      } else {
        _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, 1);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDate());
  }

  void _selectSchedule(BusSchedule schedule) {
    setState(() {
      _selectedSchedule = schedule;
      _selectedDriverId = schedule.assignedDriverId;
      _selectedDriverName = schedule.assignedDriverName;
      _conductorController.text = schedule.assignedConductorName ?? '';
      _busController.text = schedule.busNumber ?? '';
      _timeController.text = schedule.departureTime ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = AppResponsiveUtil.isMobile(context);
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            child: _buildHeader(context),
          ),
          _buildCalendarSection(),
          const SizedBox(height: 16),
          Expanded(
            child: isMobile
                ? (_selectedSchedule != null ? _buildAssignmentPanel(context) : _buildSchedulesList(context))
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildSchedulesList(context)),
                      Container(width: 1, color: AppColors.borderLight),
                      SizedBox(width: 420, child: _selectedSchedule == null ? _buildPlaceholder() : _buildAssignmentPanel(context)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    final days = _generateDaysInMonth(_currentMonth);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, color: AppColors.primaryNavy, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    '${_getMonthName(_currentMonth)} ${_currentMonth.year}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _changeMonth(-1),
                    icon: const Icon(Icons.chevron_left_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.backgroundLight,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _changeMonth(1),
                    icon: const Icon(Icons.chevron_right_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.backgroundLight,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: ListView.builder(
              controller: _calendarScrollController,
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              itemBuilder: (context, index) {
                final dayDate = days[index];
                final isSelected = dayDate.day == _selectedDate.day &&
                    dayDate.month == _selectedDate.month &&
                    dayDate.year == _selectedDate.year;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = dayDate;
                      _selectedSchedule = null; // Reset selection on date change
                    });
                  },
                  child: Container(
                    width: 58,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primaryNavy : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getWeekdayName(dayDate).substring(0, 3).toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dayDate.day.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (AppResponsiveUtil.isMobile(context))
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => context.read<DashboardViewModel>().setSelectedIndex(0),
                      icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                    ),
                  if (AppResponsiveUtil.isMobile(context)) const SizedBox(width: 12),
                  Flexible(
                    child: Text('Assign Routes & Crews',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold, color: AppColors.textDark, letterSpacing: -0.5,
                        fontSize: AppResponsiveUtil.isMobile(context) ? 24 : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Select a schedule to assign driver, conductor, bus, time, and route.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () => _showCreateAssignmentDialog(context),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Add Assignment', style: TextStyle(fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryNavy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    );
  }

  Widget _buildSchedulesList(BuildContext context) {
    final firebaseService = context.read<FirebaseService>();
    final isMobile = AppResponsiveUtil.isMobile(context);
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase().trim()),
              decoration: InputDecoration(
                hintText: 'Search by route, bus, driver...',
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.backgroundLight.withOpacity(0.5),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderLight)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderLight)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryNavy)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<BusSchedule>>(
              stream: firebaseService.getBusSchedules(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primaryNavy));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No schedules found. Create schedules first.', style: TextStyle(color: Colors.grey)));
                }
                
                final allSchedules = snapshot.data!;
                final selectedDateStr = _formatDate(_selectedDate);
                final selectedDayName = _getWeekdayName(_selectedDate);

                var schedules = allSchedules.where((schedule) {
                  // Filter by Date
                  if (schedule.date != null && schedule.date!.isNotEmpty) {
                    return schedule.date == selectedDateStr;
                  }
                  // Filter by explicit operating days (recurring schedules)
                  if (schedule.operatingDays != null && schedule.operatingDays!.isNotEmpty) {
                    return schedule.operatingDays!.contains(selectedDayName);
                  }
                  // Do not show Master Route templates (which have date == null and operatingDays == empty) in daily view
                  return false;
                }).toList();

                if (_searchQuery.isNotEmpty) {
                  schedules = schedules.where((s) =>
                    s.route.toLowerCase().contains(_searchQuery) ||
                    (s.busNumber ?? '').toLowerCase().contains(_searchQuery) ||
                    (s.assignedDriverName ?? '').toLowerCase().contains(_searchQuery) ||
                    (s.assignedConductorName ?? '').toLowerCase().contains(_searchQuery)
                  ).toList();
                }

                return Column(
                  children: [
                    // Dynamic count & legend info bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${schedules.length} Active Assignment${schedules.length == 1 ? '' : 's'}",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (!isMobile)
                            Row(
                              children: [
                                _legendDot(Colors.green, 'Staffed'),
                                const SizedBox(width: 12),
                                _legendDot(Colors.amber.shade800, 'Partial'),
                                const SizedBox(width: 12),
                                _legendDot(Colors.red, 'Unassigned'),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: schedules.isEmpty
                          ? const Center(child: Text('No schedules for this date.', style: TextStyle(color: Colors.grey)))
                          : ListView.builder(
                              padding: const EdgeInsets.only(top: 8, bottom: 24),
                              itemCount: schedules.length,
                              itemBuilder: (context, idx) => _buildScheduleRow(schedules[idx]),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildScheduleRow(BusSchedule schedule) {
    final isMobile = AppResponsiveUtil.isMobile(context);
    final isSelected = _selectedSchedule?.id == schedule.id;
    final hasDriver = schedule.assignedDriverId != null && schedule.assignedDriverId!.isNotEmpty;
    final hasConductor = schedule.assignedConductorName != null && schedule.assignedConductorName!.isNotEmpty;
    final isFullyAssigned = hasDriver && hasConductor;
    final isPartiallyAssigned = hasDriver || hasConductor;

    Color statusColor = Colors.red;
    String statusText = 'Unassigned';
    if (isFullyAssigned) {
      statusColor = Colors.green;
      statusText = 'Fully Staffed';
    } else if (isPartiallyAssigned) {
      statusColor = Colors.amber.shade800;
      statusText = 'Partial Crew';
    }

    Widget content;
    if (isMobile) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 32,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.route,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryNavy.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            schedule.type,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_bus_rounded, size: 13, color: AppColors.primaryNavy),
                  const SizedBox(width: 4),
                  Text(
                    schedule.busNumber ?? 'TBA',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time_filled_rounded, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    schedule.departureTime ?? 'Live',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.drive_eta_rounded, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        hasDriver ? schedule.assignedDriverName! : 'No Driver',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: hasDriver ? FontWeight.w600 : FontWeight.normal,
                          color: hasDriver ? AppColors.textDark : Colors.red.shade400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.person_pin_rounded, size: 13, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        hasConductor ? schedule.assignedConductorName! : 'No Conductor',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: hasConductor ? FontWeight.w600 : FontWeight.normal,
                          color: hasConductor ? AppColors.textDark : Colors.red.shade400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      content = Row(
        children: [
          // Left Accent Status bar
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          
          // Route Info
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.route,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        schedule.type,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bus / Time Details
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_bus_rounded, size: 14, color: AppColors.primaryNavy),
                    const SizedBox(width: 6),
                    Text(
                      schedule.busNumber ?? 'TBA',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time_filled_rounded, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      schedule.departureTime ?? 'Live',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Driver & Conductor Info
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.drive_eta_rounded, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        hasDriver ? schedule.assignedDriverName! : 'No Driver Assigned',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: hasDriver ? FontWeight.w600 : FontWeight.normal,
                          color: hasDriver ? AppColors.textDark : Colors.red.shade400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_pin_rounded, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        hasConductor ? schedule.assignedConductorName! : 'No Conductor Assigned',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: hasConductor ? FontWeight.w600 : FontWeight.normal,
                          color: hasConductor ? AppColors.textDark : Colors.red.shade400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      );
    }

    return Dismissible(
      key: Key('schedule_${schedule.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.white, size: 28),
            SizedBox(height: 4),
            Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
                SizedBox(width: 10),
                Text('Delete Assignment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              'Are you sure you want to delete the assignment for route "${schedule.route}"?\n\nThis cannot be undone.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (direction) async {
        final firebaseService = context.read<FirebaseService>();
        try {
          await firebaseService.deleteBusSchedule(schedule.id, schedule.route);
          if (_selectedSchedule?.id == schedule.id) {
            setState(() => _selectedSchedule = null);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Route "${schedule.route}" deleted.'),
              backgroundColor: Colors.green.shade700,
              behavior: SnackBarBehavior.floating,
            ));
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Failed to delete: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ));
          }
        }
      },
      child: GestureDetector(
        onLongPress: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 16), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(schedule.route, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                  const Divider(height: 24),
                  ListTile(
                    leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primaryNavy.withOpacity(0.08), shape: BoxShape.circle), child: const Icon(Icons.edit_rounded, color: AppColors.primaryNavy, size: 20)),
                    title: const Text('Edit Assignment', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: const Text('Modify driver, bus or time', style: TextStyle(fontSize: 11)),
                    onTap: () {
                      Navigator.pop(ctx);
                      _selectSchedule(schedule);
                    },
                  ),
                  ListTile(
                    leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), shape: BoxShape.circle), child: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 20)),
                    title: const Text('Delete Assignment', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.red)),
                    subtitle: const Text('Remove this route permanently', style: TextStyle(fontSize: 11)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (d) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Text('Delete Assignment'),
                          content: Text('Delete route "${schedule.route}"? This cannot be undone.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(d, true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && mounted) {
                        final firebaseService = context.read<FirebaseService>();
                        await firebaseService.deleteBusSchedule(schedule.id, schedule.route);
                        if (_selectedSchedule?.id == schedule.id) setState(() => _selectedSchedule = null);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Route "${schedule.route}" deleted.'),
                            backgroundColor: Colors.green.shade700,
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryNavy.withOpacity(0.04) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primaryNavy : AppColors.borderLight,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isSelected ? 0.04 : 0.01),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: InkWell(
              onTap: () => _selectSchedule(schedule),
              hoverColor: AppColors.primaryNavy.withOpacity(0.02),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.primaryNavy.withOpacity(0.05), shape: BoxShape.circle),
              child: const Icon(Icons.assignment_ind_rounded, size: 48, color: AppColors.primaryNavy),
            ),
            const SizedBox(height: 16),
            const Text('No Schedule Selected', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 8),
            const Text('Select a schedule from the left to assign driver, conductor, and crew details.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentPanel(BuildContext context) {
    final schedule = _selectedSchedule!;
    final firebaseService = context.read<FirebaseService>();
    final isMobile = AppResponsiveUtil.isMobile(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _selectedSchedule = null)),
          // Schedule Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primaryNavy, AppColors.primaryNavy.withOpacity(0.85)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('SCHEDULE DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white70, letterSpacing: 1.5)),
                    Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _confirmClearAssignment(context),
                          icon: const Icon(Icons.cleaning_services_rounded, color: Colors.white70, size: 18),
                          tooltip: 'Clear Assignment Info',
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _confirmDeleteSchedule(context),
                          icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 18),
                          tooltip: 'Delete Schedule Entirely',
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(schedule.route, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Row(children: [
                  _infoChip(Icons.directions_bus, 'Bus ${schedule.busNumber ?? "TBA"}'),
                  const SizedBox(width: 8),
                  _infoChip(Icons.access_time, schedule.departureTime ?? 'Live'),
                ]),
                const SizedBox(height: 8),
                _infoChip(Icons.category, schedule.type),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Assign Driver Section
          const Text('ASSIGN DRIVER', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          StreamBuilder<List<DriverModel>>(
            stream: firebaseService.getDrivers(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final drivers = snapshot.data!.where((d) => !d.isBlocked).toList();
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderLight),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Select a driver...'),
                    value: _selectedDriverId,
                    items: [
                      const DropdownMenuItem<String>(value: '', child: Text('— Unassign Driver —', style: TextStyle(color: Colors.red))),
                      ...drivers.map((d) => DropdownMenuItem<String>(
                        value: d.id,
                        child: Row(children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.primaryNavy.withOpacity(0.1),
                            backgroundImage: d.profileUrl != null ? NetworkImage(d.profileUrl!) : null,
                            child: d.profileUrl == null ? Text(d.name.isNotEmpty ? d.name[0] : 'D', style: const TextStyle(fontSize: 11, color: AppColors.primaryNavy)) : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(d.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              Text(d.phoneNumber, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            ],
                          )),
                        ]),
                      )),
                    ],
                    onChanged: (val) {
                      setState(() {
                        if (val == null || val.isEmpty) {
                          _selectedDriverId = null;
                          _selectedDriverName = null;
                        } else {
                          _selectedDriverId = val;
                          _selectedDriverName = drivers.firstWhere((d) => d.id == val).name;
                        }
                      });
                    },
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          // Conductor
          const Text('ASSIGN CONDUCTOR', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          TextField(
            controller: _conductorController,
            onChanged: (val) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Enter conductor name...',
              prefixIcon: const Icon(Icons.person_pin_outlined, color: AppColors.primaryNavy),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderLight)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryNavy)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),

          const SizedBox(height: 24),
          // Bus ID
          const Text('ASSIGN BUS ID / NUMBER', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final busesList = Provider.of<BusesViewModel>(context).buses;
              bool hasCurrentValue = false;
              if (_busController.text.isNotEmpty) {
                for (var bus in busesList) {
                  if (bus['busNumber'].toString() == _busController.text) {
                    hasCurrentValue = true;
                    break;
                  }
                }
              }
              
              return DropdownButtonFormField<String>(
                value: _busController.text.isNotEmpty ? _busController.text : null,
                decoration: InputDecoration(
                  hintText: 'Select Bus from Fleet',
                  prefixIcon: const Icon(Icons.directions_bus_outlined, color: AppColors.primaryNavy),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderLight)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryNavy)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: [
                  if (_busController.text.isNotEmpty && !hasCurrentValue)
                    DropdownMenuItem(value: _busController.text, child: Text("Current: ${_busController.text}")),
                  ...busesList.map((bus) {
                    final busNumber = bus['busNumber'].toString();
                    return DropdownMenuItem(value: busNumber, child: Text('Bus $busNumber'));
                  }),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _busController.text = val);
                },
              );
            }
          ),

          const SizedBox(height: 24),
          // Departure Time
          const Text('ASSIGN DEPARTURE TIME', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              // Parse existing time if already set
              TimeOfDay initialTime = TimeOfDay.now();
              final existing = _timeController.text.trim();
              if (existing.isNotEmpty && existing != 'TBA' && existing != 'Live') {
                try {
                  final parts = existing.replaceAll('AM', '').replaceAll('PM', '').trim().split(':');
                  int hour = int.parse(parts[0]);
                  int minute = int.parse(parts[1].trim());
                  if (existing.contains('PM') && hour != 12) hour += 12;
                  if (existing.contains('AM') && hour == 12) hour = 0;
                  initialTime = TimeOfDay(hour: hour, minute: minute);
                } catch (_) {}
              }

              final picked = await showTimePicker(
                context: context,
                initialTime: initialTime,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.primaryNavy,
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: AppColors.textDark,
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (picked != null) {
                final hour = picked.hour;
                final minute = picked.minute.toString().padLeft(2, '0');
                final period = hour >= 12 ? 'PM' : 'AM';
                final displayHour = hour % 12 == 0 ? 12 : hour % 12;
                setState(() {
                  _timeController.text = '$displayHour:$minute $period';
                });
              }
            },
            child: AbsorbPointer(
              child: TextField(
                controller: _timeController,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Tap to select departure time...',
                  prefixIcon: const Icon(Icons.access_time_rounded, color: AppColors.primaryNavy),
                  suffixIcon: const Icon(Icons.schedule_rounded, color: AppColors.textSecondary, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.borderLight)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryNavy)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
          // Summary card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ASSIGNMENT SUMMARY', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                _summaryRow(Icons.map_outlined, 'Route', schedule.route),
                _summaryRow(Icons.directions_bus, 'Bus', _busController.text.isNotEmpty ? _busController.text : 'TBA'),
                _summaryRow(Icons.access_time, 'Departure', _timeController.text.isNotEmpty ? _timeController.text : 'Live'),
                _summaryRow(Icons.drive_eta, 'Driver', _selectedDriverName ?? 'Not Assigned'),
                _summaryRow(Icons.person_pin, 'Conductor', _conductorController.text.isNotEmpty ? _conductorController.text : 'Not Assigned'),
              ],
            ),
          ),

          const SizedBox(height: 24),
          // Save buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _selectedSchedule == null ? null : () => _selectSchedule(schedule),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: AppColors.borderLight),
                  ),
                  child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAssignment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Assignment', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 16, color: AppColors.primaryNavy),
        const SizedBox(width: 10),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Future<void> _saveAssignment() async {
    if (_selectedSchedule == null) return;
    setState(() => _isSaving = true);

    try {
      final db = FirebaseFirestore.instance;
      final schedule = _selectedSchedule!;

      // 1. Update schedule document with driver + conductor + bus + departure time
      await db.collection('schedules').doc(schedule.id).update({
        'assignedDriverId': _selectedDriverId ?? '',
        'assignedDriverName': _selectedDriverName ?? '',
        'assignedConductorName': _conductorController.text.trim(),
        'busNumber': _busController.text.trim(),
        'departureTime': _timeController.text.trim(),
      });

      // 2. Update driver's assignedRoutes list (add this schedule id)
      if (_selectedDriverId != null && _selectedDriverId!.isNotEmpty) {
        final driverDoc = await db.collection('drivers').doc(_selectedDriverId).get();
        if (driverDoc.exists) {
          final currentRoutes = List<String>.from(driverDoc.data()?['assignedRoutes'] ?? []);
          if (!currentRoutes.contains(schedule.id)) {
            currentRoutes.add(schedule.id);
          }
          // Also compile bus numbers from all assigned schedules
          final allScheduleIds = currentRoutes;
          final busNumbers = <String>{};
          for (final sid in allScheduleIds) {
            final sDoc = await db.collection('schedules').doc(sid).get();
            if (sDoc.exists) {
              final bn = sDoc.data()?['busNumber'] ?? '';
              if (bn.toString().isNotEmpty && bn != 'TBA') busNumbers.add(bn);
            }
          }
          await db.collection('drivers').doc(_selectedDriverId).update({
            'assignedRoutes': currentRoutes,
            'assignedBus': busNumbers.join(', '),
          });
        }
      }

      // 3. If previous driver was different, remove this schedule from old driver
      if (schedule.assignedDriverId != null &&
          schedule.assignedDriverId!.isNotEmpty &&
          schedule.assignedDriverId != _selectedDriverId) {
        final oldDriverDoc = await db.collection('drivers').doc(schedule.assignedDriverId).get();
        if (oldDriverDoc.exists) {
          final oldRoutes = List<String>.from(oldDriverDoc.data()?['assignedRoutes'] ?? []);
          oldRoutes.remove(schedule.id);
          // Also compile bus numbers for the old driver
          final busNumbers = <String>{};
          for (final sid in oldRoutes) {
            final sDoc = await db.collection('schedules').doc(sid).get();
            if (sDoc.exists) {
              final bn = sDoc.data()?['busNumber'] ?? '';
              if (bn.toString().isNotEmpty && bn != 'TBA') busNumbers.add(bn);
            }
          }
          await db.collection('drivers').doc(schedule.assignedDriverId).update({
            'assignedRoutes': oldRoutes,
            'assignedBus': busNumbers.join(', '),
          });
        }
      }

      // Send notifications to drivers
      final firebaseService = context.read<FirebaseService>();
      final prevDriverId = schedule.assignedDriverId;
      final newDriverId = _selectedDriverId;
      final newBus = _busController.text.trim();
      final newTime = _timeController.text.trim();
      final routeName = schedule.route;

      final isDriverChanged = prevDriverId != newDriverId;
      final isBusOrTimeChanged = newBus != schedule.busNumber || newTime != schedule.departureTime;

      if (isDriverChanged) {
        // Notify old driver
        if (prevDriverId != null && prevDriverId.isNotEmpty) {
          await firebaseService.sendUserNotification(
            userId: prevDriverId,
            title: 'Route Assignment Removed',
            message: 'Your assignment for route \'$routeName\' has been removed or transferred.',
            type: 'alert',
          );
        }
        // Notify new driver
        if (newDriverId != null && newDriverId.isNotEmpty) {
          await firebaseService.sendUserNotification(
            userId: newDriverId,
            title: 'New Route Assigned',
            message: 'You have been assigned to Bus \'$newBus\' at \'$newTime\' for route \'$routeName\'.',
            type: 'info',
          );
        }
      } else if (isBusOrTimeChanged && newDriverId != null && newDriverId.isNotEmpty) {
        // Notify current driver about updates
        await firebaseService.sendUserNotification(
          userId: newDriverId,
          title: 'Assignment Details Updated',
          message: 'Your assignment details for route \'$routeName\' have been updated to Bus \'$newBus\' departing at \'$newTime\'.',
          type: 'info',
        );
      }

      // Update local state
      setState(() {
        _selectedSchedule = schedule.copyWith(
          assignedDriverId: _selectedDriverId ?? '',
          assignedDriverName: _selectedDriverName ?? '',
          assignedConductorName: _conductorController.text.trim(),
          busNumber: _busController.text.trim(),
          departureTime: _timeController.text.trim(),
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text('Assignment saved for ${schedule.route}!'),
          ]),
          backgroundColor: Colors.green.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showCreateAssignmentDialog(BuildContext context) {
    final firebaseService = context.read<FirebaseService>();
    final db = FirebaseFirestore.instance;
    final fromController = TextEditingController();
    final toController = TextEditingController();
    final busController = TextEditingController();
    final timeController = TextEditingController(text: '08:30 AM');
    final conductorController = TextEditingController();
    
    String selectedType = 'Combined';
    String? selectedRouteName;
    List<String> selectedRouteStops = [];
    String? dialogSelectedDriverId;
    String? dialogSelectedDriverName;
    bool isSavingNew = false;
    
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Add New Route Assignment',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        
                        // Select Configured Route Dropdown
                        StreamBuilder<List<BusSchedule>>(
                          stream: firebaseService.getBusSchedules(),
                          builder: (context, snapshot) {
                            final allSchedules = snapshot.data ?? [];
                            // Master/Defined routes are those without a specific date
                            final masterRoutes = allSchedules
                                .where((s) => s.date == null || s.date!.isEmpty)
                                .toList();
                            
                            // If no master routes found, get unique routes by name to avoid empty dropdown
                            final List<BusSchedule> availableRoutes = [];
                            final Set<String> seenRouteNames = {};
                            for (final s in masterRoutes) {
                              if (!seenRouteNames.contains(s.route)) {
                                seenRouteNames.add(s.route);
                                availableRoutes.add(s);
                              }
                            }
                            if (availableRoutes.isEmpty) {
                              for (final s in allSchedules) {
                                if (!seenRouteNames.contains(s.route)) {
                                  seenRouteNames.add(s.route);
                                  availableRoutes.add(s);
                                }
                              }
                            }

                            if (availableRoutes.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  'No defined routes found. Define routes in Route Planning first.',
                                  style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              );
                            }

                            // Set default selected route if not set or invalid
                            BusSchedule? currentSelectedRoute;
                            try {
                              currentSelectedRoute = availableRoutes.firstWhere(
                                (r) => r.route == selectedRouteName,
                              );
                            } catch (_) {
                              currentSelectedRoute = availableRoutes.first;
                              selectedRouteName = currentSelectedRoute.route;
                              fromController.text = currentSelectedRoute.from;
                              toController.text = currentSelectedRoute.to;
                              selectedRouteStops = currentSelectedRoute.stops;
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Select Configured Route',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryNavy),
                                ),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  value: selectedRouteName,
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.map_rounded, color: AppColors.primaryNavy, size: 18),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderLight)),
                                  ),
                                  items: availableRoutes.map((r) => DropdownMenuItem(
                                    value: r.route,
                                    child: Text(
                                      r.route,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      final matched = availableRoutes.firstWhere((r) => r.route == val);
                                      setDialogState(() {
                                        selectedRouteName = val;
                                        fromController.text = matched.from;
                                        toController.text = matched.to;
                                        selectedRouteStops = matched.stops;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 10),
                                // Show selected route details (From -> To info card)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundLight,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.borderLight),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_outline, size: 16, color: AppColors.primaryNavy),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Start: ${fromController.text}  ➔  End: ${toController.text}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        Builder(
                          builder: (context) {
                            final isMobile = MediaQuery.of(context).size.width < 650;
                            
                            final busField = Builder(
                              builder: (context) {
                                final busesList = Provider.of<BusesViewModel>(context).buses;
                                bool hasCurrentValue = false;
                                if (busController.text.isNotEmpty) {
                                  for (var bus in busesList) {
                                    if (bus['busNumber'].toString() == busController.text) {
                                      hasCurrentValue = true;
                                      break;
                                    }
                                  }
                                }
                                
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Bus ID / Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryNavy)),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<String>(
                                      value: busController.text.isNotEmpty ? busController.text : null,
                                      decoration: InputDecoration(
                                        hintText: 'Select Bus',
                                        prefixIcon: const Icon(Icons.directions_bus_outlined, color: AppColors.textSecondary, size: 18),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.borderLight)),
                                      ),
                                      items: [
                                        if (busController.text.isNotEmpty && !hasCurrentValue)
                                          DropdownMenuItem(value: busController.text, child: Text("Current: ${busController.text}")),
                                        ...busesList.map((bus) {
                                          final busNumber = bus['busNumber'].toString();
                                          return DropdownMenuItem(value: busNumber, child: Text('Bus $busNumber'));
                                        }),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) setDialogState(() => busController.text = val);
                                      },
                                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                                    ),
                                  ],
                                );
                              }
                            );
                            
                            final timeField = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Departure Time',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryNavy),
                                ),
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () async {
                                    TimeOfDay initialTime = TimeOfDay.now();
                                    final existing = timeController.text.trim();
                                    if (existing.isNotEmpty && existing != 'TBA' && existing != 'Live') {
                                      try {
                                        final parts = existing.replaceAll('AM', '').replaceAll('PM', '').trim().split(':');
                                        int hour = int.parse(parts[0]);
                                        int minute = int.parse(parts[1].trim());
                                        if (existing.contains('PM') && hour != 12) hour += 12;
                                        if (existing.contains('AM') && hour == 12) hour = 0;
                                        initialTime = TimeOfDay(hour: hour, minute: minute);
                                      } catch (_) {}
                                    }
                                    final picked = await showTimePicker(
                                      context: context,
                                      initialTime: initialTime,
                                      builder: (context, child) => Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: const ColorScheme.light(
                                            primary: AppColors.primaryNavy,
                                            onPrimary: Colors.white,
                                            surface: Colors.white,
                                            onSurface: AppColors.textDark,
                                          ),
                                        ),
                                        child: child!,
                                      ),
                                    );
                                    if (picked != null) {
                                      final hour = picked.hour;
                                      final minute = picked.minute.toString().padLeft(2, '0');
                                      final period = hour >= 12 ? 'PM' : 'AM';
                                      final displayHour = hour % 12 == 0 ? 12 : hour % 12;
                                      setDialogState(() {
                                        timeController.text = '$displayHour:$minute $period';
                                      });
                                    }
                                  },
                                  child: AbsorbPointer(
                                    child: TextFormField(
                                      controller: timeController,
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        hintText: 'Tap to select time...',
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        prefixIcon: const Icon(Icons.access_time_rounded, color: AppColors.primaryNavy, size: 18),
                                        suffixIcon: const Icon(Icons.schedule_rounded, color: AppColors.textSecondary, size: 16),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderLight)),
                                      ),
                                      validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                                    ),
                                  ),
                                ),
                              ],
                            );
                            
                            final categoryField = StreamBuilder<Map<String, String>>(
                              stream: firebaseService.getGenderConfigs(),
                              builder: (context, snapshot) {
                                final categories = snapshot.data?.keys.toList() ?? ['Combined', 'Boys Special', 'Girls Special'];
                                if (!categories.contains(selectedType)) {
                                  selectedType = categories.first;
                                }
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Service Category',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryNavy),
                                    ),
                                    const SizedBox(height: 6),
                                    DropdownButtonFormField<String>(
                                      value: selectedType,
                                      isExpanded: true,
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.borderLight)),
                                      ),
                                      items: categories.map((val) => DropdownMenuItem(
                                        value: val,
                                        child: Text(
                                          val,
                                          style: const TextStyle(fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setDialogState(() {
                                            selectedType = val;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                );
                              },
                            );

                            if (isMobile) {
                              return Column(
                                children: [
                                  busField,
                                  const SizedBox(height: 16),
                                  timeField,
                                  const SizedBox(height: 16),
                                  categoryField,
                                ],
                              );
                            } else {
                              return Row(
                                children: [
                                  Expanded(child: busField),
                                  const SizedBox(width: 16),
                                  Expanded(child: timeField),
                                  const SizedBox(width: 16),
                                  Expanded(child: categoryField),
                                ],
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        const Text(
                          'Assign Driver',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryNavy),
                        ),
                        const SizedBox(height: 6),
                        StreamBuilder<List<DriverModel>>(
                          stream: firebaseService.getDrivers(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final drivers = snapshot.data!.where((d) => !d.isBlocked).toList();
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.borderLight),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  hint: const Text('Select a driver...', style: TextStyle(fontSize: 13)),
                                  value: dialogSelectedDriverId,
                                  items: [
                                    const DropdownMenuItem<String>(value: '', child: Text('— Unassign Driver —', style: TextStyle(color: Colors.red, fontSize: 13))),
                                    ...drivers.map((d) => DropdownMenuItem<String>(
                                      value: d.id,
                                      child: Row(children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: AppColors.primaryNavy.withOpacity(0.1),
                                          backgroundImage: d.profileUrl != null ? NetworkImage(d.profileUrl!) : null,
                                          child: d.profileUrl == null ? Text(d.name.isNotEmpty ? d.name[0] : 'D', style: const TextStyle(fontSize: 10, color: AppColors.primaryNavy)) : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            d.name,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ]),
                                    )),
                                  ],
                                  onChanged: (val) {
                                    setDialogState(() {
                                      if (val == null || val.isEmpty) {
                                        dialogSelectedDriverId = null;
                                        dialogSelectedDriverName = null;
                                      } else {
                                        dialogSelectedDriverId = val;
                                        dialogSelectedDriverName = drivers.firstWhere((d) => d.id == val).name;
                                      }
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildDialogTextField(
                          label: 'Assign Conductor',
                          controller: conductorController,
                          icon: Icons.person_pin_outlined,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: isSavingNew ? null : () async {
                                if (formKey.currentState!.validate() && selectedRouteName != null) {
                                  setDialogState(() {
                                    isSavingNew = true;
                                  });
                                  try {
                                    final newId = db.collection('schedules').doc().id;
                                    final routeName = selectedRouteName!;
                                    
                                    final schedule = BusSchedule(
                                      id: newId,
                                      from: fromController.text.trim(),
                                      to: toController.text.trim(),
                                      route: routeName,
                                      departureTime: timeController.text.trim(),
                                      busNumber: busController.text.trim(),
                                      stops: selectedRouteStops,
                                      type: selectedType,
                                      date: _formatDate(_selectedDate),
                                      assignedDriverId: dialogSelectedDriverId ?? '',
                                      assignedDriverName: dialogSelectedDriverName ?? '',
                                      assignedConductorName: conductorController.text.trim(),
                                    );
                                    
                                    await firebaseService.addBusSchedule(schedule);

                                    // Send Notification to Driver
                                    if (dialogSelectedDriverId != null && dialogSelectedDriverId!.isNotEmpty) {
                                      await firebaseService.sendUserNotification(
                                        userId: dialogSelectedDriverId!,
                                        title: 'New Route Assigned',
                                        message: 'You have been assigned to Bus \'${busController.text.trim()}\' at \'${timeController.text.trim()}\' for route \'$routeName\'.',
                                        type: 'info',
                                      );
                                    }
                                    
                                    if (dialogSelectedDriverId != null && dialogSelectedDriverId!.isNotEmpty) {
                                      final driverDoc = await db.collection('drivers').doc(dialogSelectedDriverId).get();
                                      if (driverDoc.exists) {
                                        final currentRoutes = List<String>.from(driverDoc.data()?['assignedRoutes'] ?? []);
                                        if (!currentRoutes.contains(newId)) {
                                          currentRoutes.add(newId);
                                        }
                                        final busNumbers = <String>{};
                                        for (final sid in currentRoutes) {
                                          final sDoc = await db.collection('schedules').doc(sid).get();
                                          if (sDoc.exists) {
                                            final bn = sDoc.data()?['busNumber'] ?? '';
                                            if (bn.toString().isNotEmpty && bn != 'TBA') busNumbers.add(bn);
                                          }
                                        }
                                        await db.collection('drivers').doc(dialogSelectedDriverId).update({
                                          'assignedRoutes': currentRoutes,
                                          'assignedBus': busNumbers.join(', '),
                                        });
                                      }
                                    }
                                    
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text('Assignment created for $routeName successfully!'),
                                        backgroundColor: Colors.green.shade800,
                                      ));
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: Colors.red,
                                      ));
                                    }
                                  } finally {
                                    setDialogState(() {
                                      isSavingNew = false;
                                    });
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryNavy,
                                foregroundColor: Colors.white,
                              ),
                              child: isSavingNew
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Save Assignment'),
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
        );
      },
    );
  }

  Widget _buildDialogTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryNavy),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 16, color: AppColors.primaryNavy),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  void _confirmDeleteSchedule(BuildContext context) {
    if (_selectedSchedule == null) return;
    final schedule = _selectedSchedule!;
    final firebaseService = context.read<FirebaseService>();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Schedule'),
          content: Text('Are you sure you want to delete this schedule for route "${schedule.route}"? This will also unassign any crew and cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isSaving = true);
                try {
                  await firebaseService.deleteBusSchedule(schedule.id, schedule.route);
                  setState(() {
                    _selectedSchedule = null;
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Schedule deleted successfully!'),
                      backgroundColor: Colors.green,
                    ));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Failed to delete: $e'),
                      backgroundColor: Colors.red,
                    ));
                  }
                } finally {
                  setState(() => _isSaving = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _confirmClearAssignment(BuildContext context) {
    if (_selectedSchedule == null) return;
    final schedule = _selectedSchedule!;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear Crew & Details'),
          content: const Text('Are you sure you want to clear the driver, conductor, bus number, and reset the departure time for this schedule?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                setState(() => _isSaving = true);
                try {
                  final db = FirebaseFirestore.instance;
                  final firebaseService = context.read<FirebaseService>();
                  
                  // 1. Update schedule document - clear all assigned info
                  await db.collection('schedules').doc(schedule.id).update({
                    'assignedDriverId': '',
                    'assignedDriverName': '',
                    'assignedConductorName': '',
                    'busNumber': 'TBA',
                    'departureTime': 'TBA',
                  });

                  // 2. Remove this schedule from driver's assigned list
                  if (schedule.assignedDriverId != null && schedule.assignedDriverId!.isNotEmpty) {
                    final oldDriverDoc = await db.collection('drivers').doc(schedule.assignedDriverId).get();
                    if (oldDriverDoc.exists) {
                      final oldRoutes = List<String>.from(oldDriverDoc.data()?['assignedRoutes'] ?? []);
                      oldRoutes.remove(schedule.id);
                      
                      // Recalculate old driver's assignedBus field
                      final busNumbers = <String>{};
                      for (final sid in oldRoutes) {
                        final sDoc = await db.collection('schedules').doc(sid).get();
                        if (sDoc.exists) {
                          final bn = sDoc.data()?['busNumber'] ?? '';
                          if (bn.toString().isNotEmpty && bn != 'TBA') busNumbers.add(bn);
                        }
                      }
                      await db.collection('drivers').doc(schedule.assignedDriverId!).update({
                        'assignedRoutes': oldRoutes,
                        'assignedBus': busNumbers.join(', '),
                      });
                      
                      // Notify driver
                      await firebaseService.sendUserNotification(
                        userId: schedule.assignedDriverId!,
                        title: 'Route Assignment Removed',
                        message: 'Your assignment for route \'${schedule.route}\' has been removed.',
                        type: 'alert',
                      );
                    }
                  }

                  // Update local state
                  setState(() {
                    _selectedDriverId = null;
                    _selectedDriverName = null;
                    _conductorController.clear();
                    _busController.text = 'TBA';
                    _timeController.text = 'TBA';
                    _selectedSchedule = schedule.copyWith(
                      assignedDriverId: '',
                      assignedDriverName: '',
                      assignedConductorName: '',
                      busNumber: 'TBA',
                      departureTime: 'TBA',
                    );
                  });

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Crew details and assignments cleared!'),
                      backgroundColor: Colors.green,
                    ));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Failed to clear: $e'),
                      backgroundColor: Colors.red,
                    ));
                  }
                } finally {
                  setState(() => _isSaving = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800, foregroundColor: Colors.white),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }
}
