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

  StreamSubscription? _statsSubscription;

  DashboardViewModel() {
    _listenToStats();
    _listenToNewTickets();
  }

  void _listenToNewTickets() {
    _ticketSubscription?.cancel();
    _ticketSubscription = _firebaseService.getTickets().listen((tickets) {
      final pendingTickets = tickets.where((t) => t.status.toLowerCase() == 'pending').toList();
      pendingAlerts = pendingTickets.length;
      
      // Update notifications list with latest pending tickets
      _notifications = pendingTickets.map((t) => SystemNotificationModel(
        id: t.id,
        title: 'New Support Request',
        message: '${t.name}: ${t.issue}',
        timestamp: t.timestamp,
        type: NotificationType.support,
        color: Colors.orange,
      )).toList();
      
      notifyListeners();
    });
  }

  void _listenToStats() {
    _statsSubscription?.cancel();
    _statsSubscription = _firebaseService.getRealTimeStats().listen((stats) {
      totalDrivers = stats['totalDrivers'] ?? 0;
      totalStudents = stats['totalStudents'] ?? 0;
      notifyListeners();
    });
    
    // Also fetch admins count once or make it a stream if needed
    _firebaseService.getAdminsCount().then((count) {
      totalAdmins = count;
      notifyListeners();
    });
  }

  Future<void> refreshData() async {
    _listenToStats();
    _listenToNewTickets();
  }

  @override
  void dispose() {
    _statsSubscription?.cancel();
    _ticketSubscription?.cancel();
    super.dispose();
  }
}
