import 'package:flutter/material.dart';
import 'package:unitransit_admin/core/services/firebase_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;
  int _selectedIndex = 0;
  String _searchQuery = '';
  String _selectedGender = 'All';

  bool get isLoading => _isLoading;
  int get selectedIndex => _selectedIndex;
  String get searchQuery => _searchQuery;
  String get selectedGender => _selectedGender;

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
  int activeTrips = 42;
  int pendingAlerts = 12;
  double totalRevenue = 12450.0; // Placeholder for now

  DashboardViewModel() {
    refreshData();
  }

  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final stats = await _firebaseService.getStats();
      totalDrivers = stats['totalDrivers'] ?? 0;
      totalStudents = stats['totalStudents'] ?? 0;
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
