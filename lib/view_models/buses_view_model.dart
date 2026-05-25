import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BusesViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<Map<String, dynamic>> _buses = [];
  List<Map<String, dynamic>> get buses => _buses;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  BusesViewModel() {
    fetchBuses();
  }

  Future<void> fetchBuses() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection('buses').get();
      _buses = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      debugPrint("Error fetching buses: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addBus(Map<String, dynamic> busData) async {
    try {
      await _firestore.collection('buses').add(busData);
      await fetchBuses();
    } catch (e) {
      debugPrint("Error adding bus: $e");
    }
  }

  Future<void> updateBus(String id, Map<String, dynamic> busData) async {
    try {
      await _firestore.collection('buses').doc(id).update(busData);
      await fetchBuses();
    } catch (e) {
      debugPrint("Error updating bus: $e");
    }
  }

  Future<void> deleteBus(String id) async {
    try {
      await _firestore.collection('buses').doc(id).delete();
      await fetchBuses();
    } catch (e) {
      debugPrint("Error deleting bus: $e");
    }
  }
}
