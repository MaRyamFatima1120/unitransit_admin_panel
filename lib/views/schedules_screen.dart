import 'dart:async'; // Required for StreamSubscription
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/services/firebase_service.dart';
import 'package:unitransit_admin/models/bus_schedule_model.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';
import 'package:google_fonts/google_fonts.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  late DateTime _selectedDate;
  late DateTime _currentMonth;
  late ScrollController _calendarScrollController;
  String _selectedTypeFilter = 'All';

  // Gender Config — loaded dynamically from RTDB
  Map<String, String> _genderConfigs = {}; // { 'Boys Special': '#2196F3', ... }
  StreamSubscription? _genderSub;

  final List<String> _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _calendarScrollController = ScrollController();

    // Listen to gender_configs in Realtime Database
    _genderSub = FirebaseDatabase.instance
        .ref('gender_configs')
        .onValue
        .listen((event) {
      final raw = event.snapshot.value;
      if (raw is Map) {
        final Map<String, String> parsed = {};
        raw.forEach((key, value) {
          if (value is Map) {
            final color = value['color'];
            if (color != null) {
              parsed[key.toString()] = color.toString();
            }
          }
        });
        setState(() {
          _genderConfigs = parsed;
        });
      }
    }, onError: (err) {
      debugPrint("Error listening to gender configs in schedules screen: $err");
    });
    
    // Scroll to the selected date after build
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDate());
  }

  void _scrollToSelectedDate() {
    if (_calendarScrollController.hasClients) {
      final index = _selectedDate.day - 1;
      _calendarScrollController.animateTo(
        index * 72.0, // Approximate width of one calendar item
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  List<DateTime> _generateDaysInMonth(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
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

  String _getShift(String timeStr) {
    timeStr = timeStr.toUpperCase().trim();
    if (timeStr.contains('PM')) {
      final hourPart = timeStr.split(':')[0];
      final hour = int.tryParse(hourPart) ?? 12;
      if (hour == 12 || hour < 4) {
        return 'Afternoon';
      } else {
        return 'Evening';
      }
    } else {
      return 'Morning';
    }
  }

  @override
  void dispose() {
    _calendarScrollController.dispose();
    _genderSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context, listen: false);
    final days = _generateDaysInMonth(_currentMonth);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Action Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bus Schedules',
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage and assign schedules grouped by time and routes',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showAddEditScheduleDialog(context, firebaseService),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: Text('Create Schedule', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryNavy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Calendar Row Section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.015),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Month Selector Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, color: AppColors.primaryNavy.withOpacity(0.8), size: 22),
                              const SizedBox(width: 12),
                              Text(
                                '${_getMonthName(_currentMonth)} ${_currentMonth.year}',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
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
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => _changeMonth(1),
                                icon: const Icon(Icons.chevron_right_rounded),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.backgroundLight,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Horizontal Calendar Dates Scroll
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          controller: _calendarScrollController,
                          scrollDirection: Axis.horizontal,
                          itemCount: days.length,
                          itemBuilder: (context, index) {
                            final date = days[index];
                            final isSelected = date.year == _selectedDate.year &&
                                date.month == _selectedDate.month &&
                                date.day == _selectedDate.day;
                            final isToday = date.year == DateTime.now().year &&
                                date.month == DateTime.now().month &&
                                date.day == DateTime.now().day;
                            final dayOfWeek = _getWeekdayName(date).substring(0, 3);

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDate = date;
                                });
                              },
                              child: Container(
                                width: 62,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? const LinearGradient(
                                          colors: [AppColors.primaryNavy, Color(0xFF303F9F)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: isSelected ? null : (isToday ? AppColors.primaryNavy.withOpacity(0.06) : Colors.transparent),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? Colors.transparent
                                        : (isToday ? AppColors.primaryNavy.withOpacity(0.3) : AppColors.borderLight),
                                    width: isToday ? 1.5 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: AppColors.primaryNavy.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      dayOfWeek.toUpperCase(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? Colors.white.withOpacity(0.8) : AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      date.day.toString(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.white : AppColors.textDark,
                                      ),
                                    ),
                                    if (isToday && !isSelected)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primaryNavy,
                                          shape: BoxShape.circle,
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
                ),

                const SizedBox(height: 24),

                // Filters Row & Active Info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Selected Date Info Banner
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryNavy.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_getWeekdayName(_selectedDate)}, ${_getMonthName(_selectedDate)} ${_selectedDate.day}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryNavy,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Filter Badges - dynamically loaded from Gender Config
                      Row(
                        children: ['All', ..._genderConfigs.keys].map((filter) {
                          final isSelected = _selectedTypeFilter == filter;
                          // Parse color from gender config hex, default to navy
                          Color chipColor = AppColors.primaryNavy;
                          if (filter != 'All' && _genderConfigs.containsKey(filter)) {
                            try {
                              chipColor = Color(int.parse(
                                _genderConfigs[filter]!.replaceFirst('#', '0xFF')
                              ));
                            } catch (_) {}
                          }
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedTypeFilter = filter;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (filter == 'All' ? AppColors.accentAmber : chipColor.withOpacity(0.15))
                                    : AppColors.cardWhite,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? (filter == 'All' ? Colors.transparent : chipColor.withOpacity(0.5))
                                      : AppColors.borderLight,
                                ),
                              ),
                              child: Text(
                                filter,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isSelected
                                      ? (filter == 'All' ? AppColors.textDark : chipColor)
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Main Schedules List Grouped by Shift
                Expanded(
                  child: StreamBuilder<List<BusSchedule>>(
                    stream: firebaseService.getBusSchedules(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.primaryNavy));
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error loading schedules: ${snapshot.error}', style: GoogleFonts.poppins()));
                      }

                      final allSchedules = snapshot.data ?? [];
                      
                      // Perform client-side filtering based on selected calendar date
                      final selectedDateStr = _formatDate(_selectedDate);
                      final selectedDayName = _getWeekdayName(_selectedDate);

                      final filteredSchedules = allSchedules.where((schedule) {
                        // 1. Filter by Type
                        if (_selectedTypeFilter != 'All' && schedule.type != _selectedTypeFilter) {
                          return false;
                        }

                        // 2. Filter by Date & Weekdays
                        if (schedule.date != null && schedule.date!.isNotEmpty) {
                          return schedule.date == selectedDateStr;
                        }
                        if (schedule.operatingDays != null && schedule.operatingDays!.isNotEmpty) {
                          return schedule.operatingDays!.contains(selectedDayName);
                        }
                        // Default Daily schedules do not run on weekends (Saturday & Sunday)
                        return selectedDayName != 'Saturday' && selectedDayName != 'Sunday';
                      }).toList();

                      if (filteredSchedules.isEmpty) {
                        return _buildEmptyState();
                      }

                      // Group by Shift (Morning, Afternoon, Evening)
                      final Map<String, List<BusSchedule>> shiftGroups = {
                        'Morning': [],
                        'Afternoon': [],
                        'Evening': [],
                      };

                      for (var schedule in filteredSchedules) {
                        final shift = _getShift(schedule.departureTime ?? '');
                        shiftGroups[shift]!.add(schedule);
                      }

                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        children: [
                          if (shiftGroups['Morning']!.isNotEmpty)
                            _buildShiftSection(context, 'MORNING SESSION', shiftGroups['Morning']!, firebaseService),
                          if (shiftGroups['Afternoon']!.isNotEmpty)
                            _buildShiftSection(context, 'AFTERNOON SESSION', shiftGroups['Afternoon']!, firebaseService),
                          if (shiftGroups['Evening']!.isNotEmpty)
                            _buildShiftSection(context, 'EVENING SESSION', shiftGroups['Evening']!, firebaseService),
                          const SizedBox(height: 40),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftSection(BuildContext context, String title, List<BusSchedule> schedules, FirebaseService service) {
    // Sort schedules by time
    schedules.sort((a, b) => (a.departureTime ?? '').compareTo(b.departureTime ?? ''));

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shift Title Header Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primaryNavy.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              border: const Border(
                bottom: BorderSide(color: AppColors.borderLight),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  title.contains('MORNING')
                      ? Icons.light_mode_rounded
                      : (title.contains('AFTERNOON') ? Icons.wb_sunny_rounded : Icons.nights_stay_rounded),
                  color: AppColors.primaryNavy,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.primaryNavy,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${schedules.length} Routes',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Table Layout
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 350),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.backgroundLight.withOpacity(0.4)),
                horizontalMargin: 20,
                columnSpacing: 24,
                columns: [
                  DataColumn(
                    label: Text('Departure Time', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark)),
                  ),
                  DataColumn(
                    label: Text('Route / Direction', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark)),
                  ),
                  DataColumn(
                    label: Text('Assigned Bus IDs', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark)),
                  ),
                  DataColumn(
                    label: Text('Type', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark)),
                  ),
                  DataColumn(
                    label: Text('Key Stops', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark)),
                  ),
                  DataColumn(
                    label: Text('Actions', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark)),
                  ),
                ],
                rows: schedules.map((schedule) {
                  Color typeColor = AppColors.primaryNavy;
                  if (schedule.type.contains('Girls')) {
                    typeColor = AppColors.girlsSpecial;
                  } else if (schedule.type.contains('Boys')) {
                    typeColor = AppColors.boysSpecial;
                  } else if (schedule.type.contains('Combined')) {
                    typeColor = AppColors.combined;
                  }

                  return DataRow(
                    cells: [
                      // Time cell
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              schedule.departureTime ?? 'TBA',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark),
                            ),
                          ],
                        ),
                      ),
                      // Route cell
                      DataCell(
                        Text(
                          schedule.route,
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark),
                        ),
                      ),
                      // Bus ID cell
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryNavy.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            schedule.busNumber ?? 'TBA',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryNavy),
                          ),
                        ),
                      ),
                      // Type Cell
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            schedule.type.toUpperCase(),
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 10, color: typeColor),
                          ),
                        ),
                      ),
                      // Stops cell
                      DataCell(
                        SizedBox(
                          width: 250,
                          child: Text(
                            schedule.stops.isNotEmpty ? schedule.stops.join(" ➔ ") : 'Direct Route',
                            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                      // Actions cell
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _showAddEditScheduleDialog(context, service, schedule: schedule),
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              tooltip: 'Edit Schedule',
                              style: IconButton.styleFrom(
                                foregroundColor: AppColors.primaryNavy,
                                backgroundColor: AppColors.primaryNavy.withOpacity(0.05),
                                padding: const EdgeInsets.all(6),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _showDeleteConfirmation(context, service, schedule),
                              icon: const Icon(Icons.delete_outline_rounded, size: 16),
                              tooltip: 'Delete Schedule',
                              style: IconButton.styleFrom(
                                foregroundColor: AppColors.error,
                                backgroundColor: AppColors.error.withOpacity(0.05),
                                padding: const EdgeInsets.all(6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryNavy.withOpacity(0.04),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.calendar_today_outlined, size: 64, color: AppColors.primaryNavy.withOpacity(0.4)),
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Schedules Today',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a schedule for this day or weekly repetition to show it here.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, FirebaseService service, BusSchedule schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Schedule', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this schedule: "${schedule.route}"?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await service.deleteBusSchedule(schedule.id, schedule.route);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Schedule deleted successfully!'), backgroundColor: AppColors.primaryNavy),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Delete', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddEditScheduleDialog(BuildContext context, FirebaseService service, {BusSchedule? schedule}) {
    final isEdit = schedule != null;
    final formKey = GlobalKey<FormState>();

    // Input fields controllers
    final fromController = TextEditingController(text: schedule?.from ?? '');
    final toController = TextEditingController(text: schedule?.to ?? '');
    final departureTimeController = TextEditingController(text: schedule?.departureTime ?? '08:30 AM');
    final busIdController = TextEditingController(text: schedule?.busNumber ?? '');
    
    // Type Dropdown State
    String selectedType = schedule?.type ?? 'Combined';
    
    // Schedule Type Selection
    String schedulePattern = 'Date';
    if (isEdit) {
      if (schedule.date != null && schedule.date!.isNotEmpty) {
        schedulePattern = 'Date';
      } else if (schedule.operatingDays != null && schedule.operatingDays!.isNotEmpty) {
        schedulePattern = 'Weekly';
      } else {
        schedulePattern = 'Daily';
      }
    }

    // Specific Date State
    DateTime selectedCustomDate = isEdit && schedulePattern == 'Date'
        ? DateTime.parse(schedule.date!)
        : _selectedDate;

    // Specific Weekdays Map State
    final Map<String, bool> selectedWeekdays = {};
    for (var day in _weekdays) {
      selectedWeekdays[day] = isEdit && schedulePattern == 'Weekly' && schedule.operatingDays != null
          ? schedule.operatingDays!.contains(day)
          : false;
    }

    // Stops list input fields state
    final List<TextEditingController> stopControllers = [];
    if (isEdit && schedule.stops.isNotEmpty) {
      for (var stop in schedule.stops) {
        stopControllers.add(TextEditingController(text: stop));
      }
    } else {
      stopControllers.add(TextEditingController());
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Container(
                width: 650,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dialog Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isEdit ? 'Edit Bus Schedule' : 'Create New Schedule',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded),
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.backgroundLight,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),

                        // Form Section: From ➔ To
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: 'Start Campus / Hub',
                                controller: fromController,
                                icon: Icons.radio_button_checked,
                                iconColor: Colors.green,
                                validator: (val) => val == null || val.trim().isEmpty ? 'Start hub required' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                label: 'Destination Campus / Hub',
                                controller: toController,
                                icon: Icons.location_on,
                                iconColor: AppColors.error,
                                validator: (val) => val == null || val.trim().isEmpty ? 'Destination required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Form Section: Time, Bus ID, Type
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                label: 'Departure Time',
                                controller: departureTimeController,
                                icon: Icons.access_time_rounded,
                                hint: 'e.g., 08:30 AM',
                                validator: (val) => val == null || val.trim().isEmpty ? 'Time required' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                label: 'Bus ID / Number',
                                controller: busIdController,
                                icon: Icons.directions_bus_outlined,
                                hint: 'e.g., 1-30, C1-C6',
                                validator: (val) => val == null || val.trim().isEmpty ? 'Bus ID required' : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Service Category',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    value: selectedType,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                      filled: true,
                                      fillColor: AppColors.backgroundLight.withOpacity(0.5),
                                    ),
                                    // Dropdown items loaded dynamically from Gender Config
                                    items: _genderConfigs.isEmpty
                                        ? [DropdownMenuItem(value: selectedType, child: Text(selectedType, style: GoogleFonts.poppins(fontSize: 13)))]
                                        : _genderConfigs.keys.map((String val) {
                                            return DropdownMenuItem<String>(
                                              value: val,
                                              child: Text(val, style: GoogleFonts.poppins(fontSize: 13)),
                                            );
                                          }).toList(),
                                    onChanged: (val) {
                                      setDialogState(() {
                                        selectedType = val!;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Form Section: Schedule Pattern Selection (Daily / Specific Days / Specific Date)
                        Text(
                          'Schedule Run Frequency',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildChoiceChip(
                              label: 'Daily',
                              icon: Icons.calendar_today_rounded,
                              isSelected: schedulePattern == 'Daily',
                              onSelected: () {
                                setDialogState(() {
                                  schedulePattern = 'Daily';
                                });
                              },
                            ),
                            const SizedBox(width: 10),
                            _buildChoiceChip(
                              label: 'Weekly Repeating',
                              icon: Icons.loop_rounded,
                              isSelected: schedulePattern == 'Weekly',
                              onSelected: () {
                                setDialogState(() {
                                  schedulePattern = 'Weekly';
                                });
                              },
                            ),
                            const SizedBox(width: 10),
                            _buildChoiceChip(
                              label: 'Specific Calendar Date',
                              icon: Icons.event_rounded,
                              isSelected: schedulePattern == 'Date',
                              onSelected: () {
                                setDialogState(() {
                                  schedulePattern = 'Date';
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Render Schedule Pattern Form based on selection
                        if (schedulePattern == 'Weekly') ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select active days for this schedule:',
                                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _weekdays.map((day) {
                                    final isChecked = selectedWeekdays[day] ?? false;
                                    return FilterChip(
                                      label: Text(day, style: GoogleFonts.poppins(fontSize: 12, color: isChecked ? Colors.white : AppColors.textSecondary)),
                                      selected: isChecked,
                                      selectedColor: AppColors.primaryNavy,
                                      checkmarkColor: Colors.white,
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: BorderSide(color: isChecked ? Colors.transparent : AppColors.borderLight),
                                      ),
                                      onSelected: (selected) {
                                        setDialogState(() {
                                          selectedWeekdays[day] = selected;
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ] else if (schedulePattern == 'Date') ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Target Schedule Date',
                                      style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_getMonthName(selectedCustomDate)} ${selectedCustomDate.day}, ${selectedCustomDate.year}',
                                      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textDark, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: selectedCustomDate,
                                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                      lastDate: DateTime.now().add(const Duration(days: 365)),
                                    );
                                    if (picked != null) {
                                      setDialogState(() {
                                        selectedCustomDate = picked;
                                      });
                                    }
                                  },
                                  icon: const Icon(Icons.date_range_rounded, size: 16),
                                  label: const Text('Pick Date'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryNavy,
                                    side: const BorderSide(color: AppColors.primaryNavy),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Form Section: Route Stops (Dynamic)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Stops along the route',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textDark,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setDialogState(() {
                                  stopControllers.add(TextEditingController());
                                });
                              },
                              icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                              label: Text('Add Stop', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold)),
                              style: TextButton.styleFrom(foregroundColor: AppColors.primaryNavy),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: stopControllers.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppColors.borderLight,
                                    child: Text(
                                      (index + 1).toString(),
                                      style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: stopControllers[index],
                                      decoration: InputDecoration(
                                        hintText: 'Enter stop location name',
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      style: GoogleFonts.poppins(fontSize: 13),
                                    ),
                                  ),
                                  if (stopControllers.length > 1) ...[
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () {
                                        setDialogState(() {
                                          stopControllers[index].dispose();
                                          stopControllers.removeAt(index);
                                        });
                                      },
                                      icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.error),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),

                        const Divider(height: 32),

                        // Action Buttons: Save / Create
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.borderLight),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              ),
                              child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () async {
                                if (formKey.currentState!.validate()) {
                                  // Parse Stops
                                  final List<String> stops = stopControllers
                                      .map((c) => c.text.trim())
                                      .where((text) => text.isNotEmpty)
                                      .toList();

                                  // Format Weekdays
                                  final List<String> operatingDays = [];
                                  if (schedulePattern == 'Weekly') {
                                    selectedWeekdays.forEach((day, checked) {
                                      if (checked) operatingDays.add(day);
                                    });
                                  }

                                  // Format Date
                                  String? dateStr;
                                  if (schedulePattern == 'Date') {
                                    dateStr = _formatDate(selectedCustomDate);
                                  }

                                  final routeName = "${fromController.text.trim()} ➔ ${toController.text.trim()}";
                                  final newId = isEdit ? schedule.id : FirebaseFirestore.instance.collection('schedules').doc().id;

                                  final newSchedule = BusSchedule(
                                    id: newId,
                                    from: fromController.text.trim(),
                                    to: toController.text.trim(),
                                    route: routeName,
                                    departureTime: departureTimeController.text.trim(),
                                    busNumber: busIdController.text.trim(),
                                    stops: stops,
                                    type: selectedType,
                                    operatingDays: operatingDays.isNotEmpty ? operatingDays : null,
                                    date: dateStr,
                                  );

                                  try {
                                    if (isEdit) {
                                      await service.updateBusSchedule(schedule.id, newSchedule, schedule.route);
                                    } else {
                                      await service.addBusSchedule(newSchedule);
                                    }
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Schedule ${isEdit ? "updated" : "created"} successfully!'),
                                          backgroundColor: AppColors.primaryNavy,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                                      );
                                    }
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryNavy,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              ),
                              child: Text(
                                isEdit ? 'Save Changes' : 'Publish Schedule',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
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
        );
      },
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      avatar: Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.textSecondary),
      label: Text(label),
      labelStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
      selected: isSelected,
      selectedColor: AppColors.primaryNavy,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isSelected ? Colors.transparent : AppColors.borderLight),
      ),
      onSelected: (_) => onSelected(),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    Color? iconColor,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18, color: iconColor ?? AppColors.textSecondary),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: AppColors.backgroundLight.withOpacity(0.5),
          ),
          style: GoogleFonts.poppins(fontSize: 13),
        ),
      ],
    );
  }
}
