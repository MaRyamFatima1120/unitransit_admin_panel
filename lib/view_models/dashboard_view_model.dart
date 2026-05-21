import 'dart:async';
import 'package:flutter/material.dart';
import 'package:unitransit_admin/core/services/firebase_service.dart';
import 'package:unitransit_admin/models/notification_model.dart';
import 'package:unitransit_admin/models/support_ticket_model.dart';

class DashboardViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;
  int _selectedIndex = 0;
  String _searchQuery = '';
  String _selectedGender = 'All';
  
  List<SystemNotificationModel> _notifications = [];
  final Set<String> _dismissedNotificationIds = {};
  StreamSubscription<List<SupportTicketModel>>? _ticketSubscription;

  bool get isLoading => _isLoading;
  int get selectedIndex => _selectedIndex;
  String get searchQuery => _searchQuery;
  String get selectedGender => _selectedGender;
  List<SystemNotificationModel> get notifications => _notifications;

  void setSelectedIndex(int index) {
    _selectedIndex = index;
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedGender(String gender) {
    _selectedGender = gender;
    notifyListeners();
  }

  // Real data stats
  int totalStudents = 0;
  int totalDrivers = 0;
  int totalAdmins = 0; // Added for Super Admin dashboard
  int activeTrips = 42;
  int pendingAlerts = 0;
  double totalRevenue = 12450.0;

  int activeEmergencyAlerts = 0;
  List<Map<String, dynamic>> _emergencyAlerts = [];
  List<Map<String, dynamic>> get emergencyAlerts => _emergencyAlerts;
  StreamSubscription? _emergencySubscription;

  StreamSubscription? _statsSubscription;

  // Live Trip Alerts
  StreamSubscription? _tripAlertsSubscription;
  final StreamController<Map<String, dynamic>> _newTripAlertController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onNewTripAlert => _newTripAlertController.stream;

  List<Map<String, dynamic>> _allTrips = [];
  List<SupportTicketModel> _allTickets = [];
  List<Map<String, dynamic>> _recentActivities = [];
  StreamSubscription? _tripHistorySubscription;

  List<Map<String, dynamic>> get recentActivities => _recentActivities;
  List<double> get weeklyTripStats => _getWeeklyTripStats();

  DashboardViewModel() {
    _listenToStats();
    _listenToNewTickets();
    _listenToEmergencyAlerts();
    _listenToTripAlerts();
    _listenToTripHistory();
  }

  void _listenToTripHistory() {
    _tripHistorySubscription?.cancel();
    _tripHistorySubscription = _firebaseService.getTripHistoryStream().listen((trips) {
      _allTrips = trips;
      _updateRecentActivities();
    });
  }

  void _listenToTripAlerts() {
    _tripAlertsSubscription?.cancel();
    final appStartTime = DateTime.now().millisecondsSinceEpoch;
    _tripAlertsSubscription = _firebaseService.getTripAlertsStream().listen((alert) {
      final timestamp = alert['timestamp'] ?? 0;
      // Only notify for alerts generated after the app starts
      if (timestamp >= appStartTime) {
        _newTripAlertController.add(alert);
      }
    });
  }

  void _listenToEmergencyAlerts() {
    _emergencySubscription?.cancel();
    _emergencySubscription = _firebaseService.getEmergencyAlerts().listen((alerts) {
      _emergencyAlerts = alerts;
      activeEmergencyAlerts = alerts.where((a) => a['status'] == 'active').length;
      _updateRecentActivities();
      _updateSystemNotifications();
    });
  }

  Future<void> resolveEmergencyAlert(String id, {String? notes, String? resolvedBy}) async {
    try {
      await _firebaseService.resolveEmergencyAlert(id, notes: notes, resolvedBy: resolvedBy);
    } catch (e) {
      debugPrint("Error resolving emergency alert: $e");
    }
  }

  void _listenToNewTickets() {
    _ticketSubscription?.cancel();
    _ticketSubscription = _firebaseService.getTickets().listen((tickets) {
      _allTickets = tickets;
      final pendingTickets = tickets.where((t) => t.status.toLowerCase() == 'pending').toList();
      pendingAlerts = pendingTickets.length;
      
      _updateRecentActivities();
      _updateSystemNotifications();
    });
  }

  void _listenToStats() {
    _statsSubscription?.cancel();
    _statsSubscription = _firebaseService.getRealTimeStats().listen((stats) {
      totalDrivers = stats['totalDrivers'] ?? 0;
      totalStudents = stats['totalStudents'] ?? 0;
      activeTrips = stats['activeTrips'] ?? 0;
      totalRevenue = (stats['totalRevenue'] ?? 0.0).toDouble();
      notifyListeners();
    });
    
    // Also fetch admins count once or make it a stream if needed
    _firebaseService.getAdminsCount().then((count) {
      totalAdmins = count;
      notifyListeners();
    });
  }

  void _updateRecentActivities() {
    final List<Map<String, dynamic>> activities = [];
    
    // 1. Add Trips
    for (var trip in _allTrips) {
      final status = trip['status'] ?? 'active';
      final busNumber = trip['busNumber'] ?? 'N/A';
      final from = trip['from'] ?? 'Unknown';
      final to = trip['to'] ?? 'Unknown';
      final startTimeVal = trip['startTime'];
      
      if (startTimeVal != null) {
        final timestamp = DateTime.fromMillisecondsSinceEpoch(startTimeVal);
        if (status == 'active') {
          activities.add({
            'title': 'Bus #$busNumber started route',
            'subtitle': '$from ➔ $to',
            'timestamp': timestamp,
            'icon': Icons.directions_bus_rounded,
            'color': Colors.blue,
          });
        } else {
          final endTimeVal = trip['endTime'];
          final endTimestamp = endTimeVal != null ? DateTime.fromMillisecondsSinceEpoch(endTimeVal) : timestamp;
          activities.add({
            'title': 'Bus #$busNumber arrived',
            'subtitle': 'Completed route: $from ➔ $to',
            'timestamp': endTimestamp,
            'icon': Icons.check_circle_rounded,
            'color': Colors.green,
          });
        }
      }
    }
    
    // 2. Add Support Tickets
    for (var ticket in _allTickets) {
      activities.add({
        'title': 'Support Ticket: ${ticket.name}',
        'subtitle': ticket.issue,
        'timestamp': ticket.timestamp,
        'icon': Icons.support_agent_rounded,
        'color': ticket.status.toLowerCase() == 'pending' ? Colors.orange : Colors.purple,
      });
    }
    
    // 3. Add Emergency Alerts
    for (var alert in _emergencyAlerts) {
      final status = alert['status'] ?? 'active';
      final message = alert['message'] ?? 'Emergency SOS Alert';
      final timeVal = alert['timestamp'];
      
      if (timeVal != null) {
        final timestamp = DateTime.fromMillisecondsSinceEpoch(timeVal);
        if (status == 'active') {
          activities.add({
            'title': '🚨 SOS Alert Active!',
            'subtitle': message,
            'timestamp': timestamp,
            'icon': Icons.warning_rounded,
            'color': Colors.red,
          });
        } else {
          final resolvedAtVal = alert['resolvedAt'];
          final resolvedTimestamp = resolvedAtVal != null ? DateTime.fromMillisecondsSinceEpoch(resolvedAtVal) : timestamp;
          activities.add({
            'title': '🟢 SOS Alert Resolved',
            'subtitle': 'Notes: ${alert['resolutionNotes'] ?? ''}',
            'timestamp': resolvedTimestamp,
            'icon': Icons.crisis_alert_rounded,
            'color': Colors.green,
          });
        }
      }
    }
    
    // Sort all activities by timestamp descending
    activities.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    
    // Take only the top 10 activities
    _recentActivities = activities.take(10).toList();
    notifyListeners();
  }

  void _updateSystemNotifications() {
    final List<SystemNotificationModel> logs = [];

    // 1. Pending Support Tickets
    final pendingTickets = _allTickets.where((t) => t.status.toLowerCase() == 'pending');
    for (var t in pendingTickets) {
      if (!_dismissedNotificationIds.contains(t.id)) {
        logs.add(SystemNotificationModel(
          id: t.id,
          title: 'New Support Request',
          message: '${t.name}: ${t.issue}',
          timestamp: t.timestamp,
          type: NotificationType.support,
          color: Colors.orange,
        ));
      }
    }

    // 2. Active SOS / Emergency Alerts
    final activeSOS = _emergencyAlerts.where((a) => a['status'] == 'active');
    for (var a in activeSOS) {
      final String alertId = a['id'] ?? '';
      if (!_dismissedNotificationIds.contains(alertId)) {
        final timeVal = a['timestamp'];
        final timestamp = timeVal != null ? DateTime.fromMillisecondsSinceEpoch(timeVal) : DateTime.now();
        logs.add(SystemNotificationModel(
          id: alertId,
          title: 'Active SOS Alert!',
          message: 'Driver: ${a['driverName'] ?? 'Unknown'} (Bus #${a['busNumber'] ?? 'N/A'}) - ${a['message'] ?? 'Emergency SOS'}',
          timestamp: timestamp,
          type: NotificationType.warning,
          color: Colors.red,
        ));
      }
    }

    // Sort by timestamp descending
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    _notifications = logs;
    notifyListeners();
  }

  void dismissNotification(String id) {
    _dismissedNotificationIds.add(id);
    _updateSystemNotifications();
  }

  void clearAllNotifications() {
    for (var notif in _notifications) {
      _dismissedNotificationIds.add(notif.id);
    }
    _updateSystemNotifications();
  }

  List<double> _getWeeklyTripStats() {
    final List<double> counts = List.filled(7, 0.0);
    final now = DateTime.now();
    // Start of the week: Monday
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(monday.year, monday.month, monday.day);
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    for (var trip in _allTrips) {
      final startTimeVal = trip['startTime'];
      if (startTimeVal == null) continue;
      final tripDate = DateTime.fromMillisecondsSinceEpoch(startTimeVal);
      
      if ((tripDate.isAfter(startOfWeek) || tripDate.isAtSameMomentAs(startOfWeek)) &&
          tripDate.isBefore(endOfWeek)) {
        final dayIndex = tripDate.weekday - 1; // weekday is 1-indexed, so 0 to 6
        if (dayIndex >= 0 && dayIndex < 7) {
          counts[dayIndex] += 1.0;
        }
      }
    }
    return counts;
  }

  Future<void> refreshData() async {
    _listenToStats();
    _listenToNewTickets();
    _listenToEmergencyAlerts();
    _listenToTripHistory();
  }

  @override
  void dispose() {
    _statsSubscription?.cancel();
    _ticketSubscription?.cancel();
    _emergencySubscription?.cancel();
    _tripAlertsSubscription?.cancel();
    _tripHistorySubscription?.cancel();
    _newTripAlertController.close();
    super.dispose();
  }
}
