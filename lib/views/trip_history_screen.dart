import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unitransit_admin/core/constants/app_colors.dart';
import 'package:unitransit_admin/core/services/firebase_service.dart';
import 'package:unitransit_admin/core/utils/responsive_util.dart';
import 'package:unitransit_admin/core/utils/animations.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  final ScrollController _horizontalScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _calendarScrollController = ScrollController();
  String _selectedTab = 'All';
  String _searchQuery = '';
  DateTime? _selectedDate;
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelectedDate());
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _searchController.dispose();
    _calendarScrollController.dispose();
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
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: firebaseService.getTripHistoryStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allTrips = snapshot.data ?? [];
                final activeTripsCount = allTrips.where((t) => t['status'] == 'active').length;
                final completedTripsCount = allTrips.where((t) => t['status'] == 'completed').length;

                // Filter logic
                var filteredTrips = allTrips;
                if (_selectedTab == 'Active') {
                  filteredTrips = filteredTrips.where((t) => t['status'] == 'active').toList();
                } else if (_selectedTab == 'Completed') {
                  filteredTrips = filteredTrips.where((t) => t['status'] == 'completed').toList();
                }

                // Date Filter
                if (_selectedDate != null) {
                  filteredTrips = filteredTrips.where((t) {
                    final startTimeVal = t['startTime'];
                    if (startTimeVal == null) return false;
                    final date = DateTime.fromMillisecondsSinceEpoch(startTimeVal);
                    return date.year == _selectedDate!.year &&
                        date.month == _selectedDate!.month &&
                        date.day == _selectedDate!.day;
                  }).toList();
                }

                if (_searchQuery.isNotEmpty) {
                  filteredTrips = filteredTrips.where((t) {
                    final bus = (t['busNumber'] ?? '').toString().toLowerCase();
                    final plate = (t['plateNumber'] ?? '').toString().toLowerCase();
                    final from = (t['from'] ?? '').toString().toLowerCase();
                    final to = (t['to'] ?? '').toString().toLowerCase();
                    return bus.contains(_searchQuery.toLowerCase()) ||
                        plate.contains(_searchQuery.toLowerCase()) ||
                        from.contains(_searchQuery.toLowerCase()) ||
                        to.contains(_searchQuery.toLowerCase());
                  }).toList();
                }

                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.5))),
                  ),
                  child: Column(
                    children: [
                      _buildSummaryCards(context, allTrips.length, activeTripsCount, completedTripsCount),
                      _buildHorizontalCalendar(),
                      _buildToolbar(context),
                      Expanded(
                        child: filteredTrips.isEmpty
                            ? FadeInSlide(
                                direction: FadeInDirection.bottomToTop,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade300),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No trips found',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade600),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Trips started by drivers will appear here in real-time.',
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : _buildTripsTable(context, filteredTrips),
                      ),
                    ],
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
    return FadeInSlide(
      direction: FadeInDirection.leftToRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip History Log',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  letterSpacing: -0.5,
                  fontSize: AppResponsiveUtil.isMobile(context) ? 24 : null,
                ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Monitor active journeys and audit completed trip logs dynamically.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, int total, int active, int completed) {
    final isMobile = AppResponsiveUtil.isMobile(context);
    final cards = [
      _buildSummaryCard(
        'Total Journeys',
        total.toString(),
        Icons.history_rounded,
        AppColors.primaryNavy,
      ),
      _buildSummaryCard(
        'Active Trips',
        active.toString(),
        Icons.local_shipping_rounded,
        AppColors.accentAmber,
        isLive: active > 0,
      ),
      _buildSummaryCard(
        'Completed Trips',
        completed.toString(),
        Icons.check_circle_rounded,
        Colors.green,
      ),
    ];

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: FadeInSlide(
          direction: FadeInDirection.bottomToTop,
          delay: const Duration(milliseconds: 100),
          child: Column(
            children: cards.map((card) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: card,
            )).toList(),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(cards.length, (i) => Expanded(
          child: FadeInSlide(
            direction: FadeInDirection.bottomToTop,
            delay: Duration(milliseconds: 100 * (i + 1)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: cards[i],
            ),
          ),
        )),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, {bool isLive = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    if (isLive) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'LIVE',
                        style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCalendar() {
    final days = _generateDaysInMonth(_currentMonth);
    return FadeInSlide(
      direction: FadeInDirection.bottomToTop,
      delay: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
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
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_rounded, color: AppColors.primaryNavy.withValues(alpha: 0.8), size: 22),
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
                      if (_selectedDate != null)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedDate = null;
                            });
                          },
                          icon: const Icon(Icons.clear_all_rounded, size: 16, color: Colors.redAccent),
                          label: Text('Clear Filter', style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        )
                    ],
                  ),
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
                  final isSelected = _selectedDate != null &&
                      date.year == _selectedDate!.year &&
                      date.month == _selectedDate!.month &&
                      date.day == _selectedDate!.day;
                  final isToday = date.year == DateTime.now().year &&
                      date.month == DateTime.now().month &&
                      date.day == DateTime.now().day;
                  final dayOfWeek = _getWeekdayName(date).substring(0, 3);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedDate = null;
                        } else {
                          _selectedDate = date;
                        }
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
                        color: isSelected ? null : (isToday ? AppColors.primaryNavy.withValues(alpha: 0.06) : Colors.transparent),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : (isToday ? AppColors.primaryNavy.withValues(alpha: 0.3) : AppColors.borderLight),
                          width: isToday ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primaryNavy.withValues(alpha: 0.3),
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
                              color: isSelected ? Colors.white.withValues(alpha: 0.8) : AppColors.textSecondary,
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
    );
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
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return weekdays[date.weekday - 1];
  }

  void _changeMonth(int offset) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + offset);
    });
  }

  void _scrollToSelectedDate() {
    if (_calendarScrollController.hasClients) {
      final index = (_selectedDate ?? DateTime.now()).day - 1;
      _calendarScrollController.animateTo(
        index * 72.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildToolbar(BuildContext context) {
    final isMobile = AppResponsiveUtil.isMobile(context);

    return FadeInSlide(
      direction: FadeInDirection.bottomToTop,
      delay: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: ['All', 'Active', 'Completed'].map((tab) {
                      final isSelected = _selectedTab == tab;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(tab),
                          selected: isSelected,
                          selectedColor: AppColors.primaryNavy,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                          backgroundColor: Colors.transparent,
                          side: BorderSide(color: isSelected ? AppColors.primaryNavy : AppColors.borderLight),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _selectedTab = tab;
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  _buildSearchField(),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Filter Tabs
                  Row(
                    children: ['All', 'Active', 'Completed'].map((tab) {
                      final isSelected = _selectedTab == tab;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(tab),
                          selected: isSelected,
                          selectedColor: AppColors.primaryNavy,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          backgroundColor: Colors.transparent,
                          side: BorderSide(color: isSelected ? AppColors.primaryNavy : AppColors.borderLight),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _selectedTab = tab;
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  // Search Row
                  Row(
                    children: [
                      _buildSearchField(),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      width: 250,
      height: 40,
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        decoration: InputDecoration(
          hintText: 'Search by Bus / Route...',
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.borderLight),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
        ),
      ),
    );
  }

  Widget _buildTripsTable(BuildContext context, List<Map<String, dynamic>> trips) {
    // Transform to TripListItems grouped by date
    final List<TripListItem> listItems = [];
    String? lastHeader;
    for (var trip in trips) {
      final startTimeVal = trip['startTime'];
      final header = startTimeVal != null ? _getGroupDateHeader(startTimeVal) : 'Unknown Date';
      if (header != lastHeader) {
        listItems.add(TripListItem.header(header));
        lastHeader = header;
      }
      listItems.add(TripListItem.row(trip));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          controller: _horizontalScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: FadeInSlide(
              direction: FadeInDirection.bottomToTop,
              delay: const Duration(milliseconds: 600),
              child: Container(
                width: constraints.maxWidth > 1200 + 48 ? constraints.maxWidth - 48 : 1200,
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
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: listItems.length,
                      itemBuilder: (context, index) {
                        final item = listItems[index];
                        if (item.isHeader) {
                          return _buildGroupHeaderRow(item.dateHeader!);
                        } else {
                          return _TripRow(trip: item.trip!);
                        }
                      },
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

  Widget _buildGroupHeaderRow(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: AppColors.primaryNavy.withValues(alpha: 0.04),
      width: double.infinity,
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primaryNavy),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: AppColors.primaryNavy,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  String _getGroupDateHeader(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final tripDay = DateTime(date.year, date.month, date.day);

    if (tripDay == today) {
      return 'Today';
    } else if (tripDay == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, d MMMM yyyy').format(date);
    }
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy.withValues(alpha: 0.02),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 2, child: Text('BUS & VEHICLE', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
          Expanded(flex: 3, child: Text('ROUTE ORIGIN & DESTINATION', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
          Expanded(flex: 1, child: Text('GENDER', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
          Expanded(flex: 2, child: Text('START TIME', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
          Expanded(flex: 2, child: Text('END TIME', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
          Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.primaryNavy, letterSpacing: 1.2))),
        ],
      ),
    );
  }
}

class _TripRow extends StatefulWidget {
  final Map<String, dynamic> trip;
  const _TripRow({required this.trip});

  @override
  State<_TripRow> createState() => _TripRowState();
}

class _TripRowState extends State<_TripRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final status = trip['status'] ?? 'active';
    final startTimeVal = trip['startTime'];
    final endTimeVal = trip['endTime'];

    final String startTimeText = startTimeVal != null
        ? DateFormat('dd MMM, hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(startTimeVal))
        : 'N/A';

    final String endTimeText = status == 'completed' && endTimeVal != null
        ? DateFormat('dd MMM, hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(endTimeVal))
        : (status == 'active' ? 'Active Now' : 'N/A');

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
            // Bus & Vehicle
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  AnimatedScale(
                    scale: _isHovered ? 1.1 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.directions_bus_rounded, color: AppColors.primaryNavy, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bus ${trip['busNumber'] ?? 'N/A'}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _isHovered ? AppColors.primaryNavy : AppColors.textDark),
                        ),
                        Text(
                          trip['plateNumber'] ?? 'No Plate',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Route
            Expanded(
              flex: 3,
              child: Text(
                '${trip['from'] ?? 'Origin'} ➔ ${trip['to'] ?? 'Destination'}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
              ),
            ),
            // Gender
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (trip['gender'] ?? 'All').toString().toLowerCase() == 'female'
                      ? Colors.pink.withValues(alpha: 0.1)
                      : Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trip['gender'] ?? 'All',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: (trip['gender'] ?? 'All').toString().toLowerCase() == 'female'
                        ? Colors.pink
                        : Colors.blue,
                  ),
                ),
              ),
            ),
            // Start Time
            Expanded(
              flex: 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      startTimeText,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.textDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // End Time
            Expanded(
              flex: 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    status == 'active' ? Icons.timelapse_rounded : Icons.access_time_filled_rounded,
                    size: 14,
                    color: status == 'active' ? Colors.green : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      endTimeText,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: status == 'active' ? Colors.green : AppColors.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Status Badge
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: status == 'active' ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: status == 'active' ? Colors.orange.withValues(alpha: 0.3) : Colors.green.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          status == 'active' ? Icons.play_arrow_rounded : Icons.check_circle_rounded,
                          size: 12,
                          color: status == 'active' ? Colors.orange : Colors.green,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          status == 'active' ? 'Active' : 'Completed',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: status == 'active' ? Colors.orange.shade800 : Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TripListItem {
  final String? dateHeader;
  final Map<String, dynamic>? trip;

  TripListItem.header(this.dateHeader) : trip = null;
  TripListItem.row(this.trip) : dateHeader = null;

  bool get isHeader => dateHeader != null;
}
