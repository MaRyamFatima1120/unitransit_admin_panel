import 'package:flutter/material.dart';

class DashboardViewModel extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Mock data for dashboard
  int totalUsers = 1284;
  int activeTrips = 42;
  double totalRevenue = 12450.0;
  int pendingAlerts = 12;

  void refreshData() async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Update with random values for demonstration
    totalUsers += 5;
    activeTrips = 40 + (DateTime.now().second % 10);
    
    _isLoading = false;
    notifyListeners();
  }
}
