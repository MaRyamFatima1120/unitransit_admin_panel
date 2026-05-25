import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:unitransit_admin/models/bus_schedule_model.dart';

class FleetOperationsViewModel extends ChangeNotifier {
  final DatabaseReference _busesRef = FirebaseDatabase.instance.ref('buses');
  final DatabaseReference _polylinesRef = FirebaseDatabase.instance.ref('custom_polylines');
  StreamSubscription? _busesSubscription;
  StreamSubscription? _schedulesSubscription;
  StreamSubscription? _polylinesSubscription;

  // --- State ---
  List<Map<String, dynamic>> _allBuses = [];
  List<Map<String, dynamic>> _filteredBuses = [];
  List<BusSchedule> _schedules = [];
  Map<String, List<LatLng>> _polylines = {};

  String? _selectedBusId;
  bool _isLoading = true;

  String _searchQuery = '';
  String _selectedGenderFilter = 'All';
  String _selectedRouteFilter = 'All';
  String _selectedBusNumberFilter = 'All';

  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

  final List<String> _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  // --- Getters ---
  List<Map<String, dynamic>> get allBuses => _allBuses;
  List<Map<String, dynamic>> get filteredBuses => _filteredBuses;
  List<BusSchedule> get schedules => _schedules;
  Map<String, List<LatLng>> get polylines => _polylines;
  String? get selectedBusId => _selectedBusId;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedGenderFilter => _selectedGenderFilter;
  String get selectedRouteFilter => _selectedRouteFilter;
  String get selectedBusNumberFilter => _selectedBusNumberFilter;
  DateTime get selectedDate => _selectedDate;
  DateTime get currentMonth => _currentMonth;
  int get activeCount => _allBuses.length;

  Map<String, dynamic>? get selectedBus {
    if (_selectedBusId == null) return null;
    final match = _allBuses.where((b) => b['id'] == _selectedBusId);
    if (match.isEmpty) return null;
    final bus = match.first;
    return bus.isNotEmpty ? bus : null;
  }

  bool get hasActiveFilters =>
      _selectedGenderFilter != 'All' ||
      _selectedRouteFilter != 'All' ||
      _selectedBusNumberFilter != 'All' ||
      _searchQuery.isNotEmpty;

  // --- Initialization ---
  FleetOperationsViewModel() {
    _listenToActiveBuses();
    _listenToSchedules();
    _listenToPolylines();
  }

  void _listenToActiveBuses() {
    _busesSubscription = _busesRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      final List<Map<String, dynamic>> loadedBuses = [];

      if (data != null) {
        data.forEach((key, value) {
          if (value is Map) {
            loadedBuses.add({
              'id': key.toString(),
              ...Map<String, dynamic>.from(value),
            });
          }
        });
      }

      _allBuses = loadedBuses;
      _isLoading = false;
      applyFilters();
    }, onError: (error) {
      debugPrint("Error loading active buses: $error");
      _isLoading = false;
      notifyListeners();
    });
  }

  void _listenToSchedules() {
    _schedulesSubscription = FirebaseFirestore.instance
        .collection('schedules')
        .snapshots()
        .listen((snapshot) {
      _schedules = snapshot.docs
          .map((doc) => BusSchedule.fromMap(doc.id, doc.data()))
          .toList();
      notifyListeners();
    });
  }

  void _listenToPolylines() {
    _polylinesSubscription = _polylinesRef.onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) {
        _polylines = {};
      } else {
        final Map<String, List<LatLng>> loaded = {};
        data.forEach((routeName, coords) {
          if (coords is List) {
            final List<LatLng> path = [];
            for (var c in coords) {
              if (c is Map) {
                final lat = (c['lat'] ?? c['latitude'] ?? 0.0) as num;
                final lng = (c['lng'] ?? c['longitude'] ?? 0.0) as num;
                path.add(LatLng(lat.toDouble(), lng.toDouble()));
              }
            }
            if (path.isNotEmpty) {
              loaded[routeName.toString()] = path;
            }
          }
        });
        _polylines = loaded;
      }
      notifyListeners();
    });
  }

  // --- Filter Actions ---
  void updateSearchQuery(String query) {
    _searchQuery = query;
    applyFilters();
  }

  void setGenderFilter(String gender) {
    _selectedGenderFilter = gender;
    applyFilters();
  }

  void setRouteFilter(String route) {
    _selectedRouteFilter = route;
    applyFilters();
  }

  void setBusNumberFilter(String busNum) {
    _selectedBusNumberFilter = busNum;
    applyFilters();
  }

  void clearAllFilters() {
    _searchQuery = '';
    _selectedGenderFilter = 'All';
    _selectedRouteFilter = 'All';
    _selectedBusNumberFilter = 'All';
    applyFilters();
  }

  void selectBus(String? busId) {
    _selectedBusId = busId;
    notifyListeners();
  }

  void applyFilters() {
    List<Map<String, dynamic>> temp = _allBuses;

    // Search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      temp = temp.where((bus) {
        final busNum = (bus['busNumber'] ?? '').toString().toLowerCase();
        final driver = (bus['driverName'] ?? '').toString().toLowerCase();
        final from = (bus['from'] ?? '').toString().toLowerCase();
        final to = (bus['to'] ?? '').toString().toLowerCase();
        final plate = (bus['plateNumber'] ?? '').toString().toLowerCase();
        return busNum.contains(query) ||
            driver.contains(query) ||
            from.contains(query) ||
            to.contains(query) ||
            plate.contains(query);
      }).toList();
    }

    // Gender filter
    if (_selectedGenderFilter != 'All') {
      temp = temp.where((bus) {
        final gender = (bus['gender'] ?? '').toString().toLowerCase();
        return gender == _selectedGenderFilter.toLowerCase();
      }).toList();
    }

    // Route filter
    if (_selectedRouteFilter != 'All') {
      temp = temp.where((bus) {
        final from = (bus['from'] ?? '').toString();
        final to = (bus['to'] ?? '').toString();
        final routeLabel = '$from ➔ $to';
        return routeLabel == _selectedRouteFilter;
      }).toList();
    }

    // Bus number filter
    if (_selectedBusNumberFilter != 'All') {
      temp = temp.where((bus) {
        final busNum = (bus['busNumber'] ?? '').toString();
        return busNum == _selectedBusNumberFilter;
      }).toList();
    }

    _filteredBuses = temp;
    notifyListeners();
  }

  // --- Derived Data ---
  List<String> get uniqueRoutes {
    final routes = <String>{};
    // Use defined schedules (official routes) instead of only active buses
    for (final schedule in _schedules) {
      if (schedule.from.isNotEmpty && schedule.to.isNotEmpty) {
        routes.add('${schedule.from} ➔ ${schedule.to}');
      }
    }
    return ['All', ...routes.toList()];
  }

  List<String> get uniqueBusNumbers {
    final numbers = <String>{};
    for (final bus in _allBuses) {
      final busNum = (bus['busNumber'] ?? '').toString();
      if (busNum.isNotEmpty && busNum != 'N/A') {
        numbers.add(busNum);
      }
    }
    final sorted = numbers.toList()..sort((a, b) {
      final aNum = int.tryParse(a) ?? 0;
      final bNum = int.tryParse(b) ?? 0;
      return aNum.compareTo(bNum);
    });
    return ['All', ...sorted];
  }

  // --- Schedule Matching ---
  BusSchedule? getMatchingSchedule(Map<String, dynamic> bus) {
    if (_schedules.isEmpty) return null;
    final busNum = (bus['busNumber'] ?? '').toString().toLowerCase().trim();
    if (busNum.isEmpty) return null;

    final matchedByBus = _schedules.where((s) {
      final sBus = (s.busNumber ?? '').toLowerCase().trim();
      return sBus == busNum || sBus.contains(busNum) || busNum.contains(sBus);
    }).toList();

    if (matchedByBus.isNotEmpty) {
      final selectedWeekday = DateFormat('EEEE').format(_selectedDate);
      final selectedDateStr = _formatDate(_selectedDate);
      for (var schedule in matchedByBus) {
        if (schedule.date == selectedDateStr) return schedule;
      }
      for (var schedule in matchedByBus) {
        if (schedule.operatingDays != null && schedule.operatingDays!.contains(selectedWeekday)) {
          return schedule;
        }
      }
      return matchedByBus.first;
    }

    final matchedByRoute = _schedules.where((s) {
      final sFrom = s.from.toLowerCase().trim();
      final sTo = s.to.toLowerCase().trim();
      final busFrom = (bus['from'] ?? '').toString().toLowerCase().trim();
      final busTo = (bus['to'] ?? '').toString().toLowerCase().trim();
      return sFrom == busFrom && sTo == busTo;
    }).toList();

    if (matchedByRoute.isNotEmpty) {
      final selectedDateStr = _formatDate(_selectedDate);
      for (var schedule in matchedByRoute) {
        if (schedule.date == selectedDateStr) return schedule;
      }
      return matchedByRoute.first;
    }

    return null;
  }

  int get totalSchedulesToday {
    final selectedWeekday = DateFormat('EEEE').format(_selectedDate);
    final selectedDateStr = _formatDate(_selectedDate);
    return _schedules.where((s) {
      final isDay = s.operatingDays != null && s.operatingDays!.contains(selectedWeekday);
      final isDate = s.date != null && s.date == selectedDateStr;
      return isDay || isDate;
    }).length;
  }

  int get activeSchedulesToday {
    final selectedWeekday = DateFormat('EEEE').format(_selectedDate);
    final selectedDateStr = _formatDate(_selectedDate);
    final todaySchedules = _schedules.where((s) {
      final isDay = s.operatingDays != null && s.operatingDays!.contains(selectedWeekday);
      final isDate = s.date != null && s.date == selectedDateStr;
      return isDay || isDate;
    }).toList();

    int count = 0;
    for (var schedule in todaySchedules) {
      final isAnyBusCovering = _allBuses.any((bus) {
        final busNum = (bus['busNumber'] ?? '').toString().toLowerCase().trim();
        final sBus = (schedule.busNumber ?? '').toLowerCase().trim();
        if (sBus == busNum && busNum.isNotEmpty) return true;

        final sFrom = schedule.from.toLowerCase().trim();
        final sTo = schedule.to.toLowerCase().trim();
        final busFrom = (bus['from'] ?? '').toString().toLowerCase().trim();
        final busTo = (bus['to'] ?? '').toString().toLowerCase().trim();
        return sFrom == busFrom && sTo == busTo;
      });
      if (isAnyBusCovering) count++;
    }
    return count;
  }

  // --- Calendar ---
  List<DateTime> get daysInMonth {
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    return List.generate(
      lastDayOfMonth.day,
      (index) => DateTime(_currentMonth.year, _currentMonth.month, index + 1),
    );
  }

  String get monthName {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[_currentMonth.month - 1];
  }

  String getWeekdayName(DateTime date) {
    return _weekdays[date.weekday - 1];
  }

  void changeMonth(int offset) {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + offset);
    if (_currentMonth.year == DateTime.now().year && _currentMonth.month == DateTime.now().month) {
      _selectedDate = DateTime.now();
    } else {
      _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, 1);
    }
    notifyListeners();
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _busesSubscription?.cancel();
    _schedulesSubscription?.cancel();
    _polylinesSubscription?.cancel();
    super.dispose();
  }
}
