import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:unitransit_admin/core/services/firebase_service.dart';
import 'package:unitransit_admin/models/bus_schedule_model.dart';
import 'package:unitransit_admin/models/hub_model.dart';

class RoutePlanningViewModel extends ChangeNotifier {
  final FirebaseService _firebaseService;

  RoutePlanningViewModel(this._firebaseService);

  // --- Hubs Manager State ---
  final nameController = TextEditingController();
  final latController = TextEditingController();
  final lngController = TextEditingController();
  bool _isHubSaving = false;
  String? _editingHubName;

  bool get isHubSaving => _isHubSaving;
  String? get editingHubName => _editingHubName;

  void setEditingHub(HubModel? hub) {
    if (hub != null) {
      _editingHubName = hub.name;
      nameController.text = hub.name;
      latController.text = hub.latitude.toString();
      lngController.text = hub.longitude.toString();
    } else {
      _editingHubName = null;
      nameController.clear();
      latController.clear();
      lngController.clear();
    }
    notifyListeners();
  }

  Future<void> saveHub() async {
    if (nameController.text.isNotEmpty &&
        latController.text.isNotEmpty &&
        lngController.text.isNotEmpty) {
      _isHubSaving = true;
      notifyListeners();

      try {
        final hub = HubModel(
          name: nameController.text.trim(),
          latitude: double.parse(latController.text),
          longitude: double.parse(lngController.text),
        );

        if (_editingHubName != null) {
          await _firebaseService.updateHub(hub, _editingHubName!);
        } else {
          await _firebaseService.addHub(hub);
        }
        setEditingHub(null); // Reset
      } finally {
        _isHubSaving = false;
        notifyListeners();
      }
    }
  }

  Future<void> deleteHub(String name) async {
    await _firebaseService.deleteHub(name);
    notifyListeners();
  }

  // --- Route Definition State ---
  final routeNameController = TextEditingController();
  String? _fromHub;
  String? _toHub;
  bool _isRouteSaving = false;
  String? _editingRouteId;
  String? _originalRouteName;

  String? get fromHub => _fromHub;
  String? get toHub => _toHub;
  bool get isRouteSaving => _isRouteSaving;
  String? get editingRouteId => _editingRouteId;

  void setFromHub(String? hub) {
    _fromHub = hub;
    notifyListeners();
  }

  void setToHub(String? hub) {
    _toHub = hub;
    notifyListeners();
  }

  void setEditingRoute(BusSchedule? route) {
    if (route != null) {
      _editingRouteId = route.id;
      _originalRouteName = route.route;
      routeNameController.text = route.route;
      _fromHub = route.from;
      _toHub = route.to;
    } else {
      _editingRouteId = null;
      _originalRouteName = null;
      routeNameController.clear();
      _fromHub = null;
      _toHub = null;
    }
    notifyListeners();
  }

  Future<void> saveRoute() async {
    if (routeNameController.text.isNotEmpty && _fromHub != null && _toHub != null) {
      _isRouteSaving = true;
      notifyListeners();

      try {
        final schedule = BusSchedule(
          id: _editingRouteId ?? DateTime.now().millisecondsSinceEpoch.toString(),
          route: routeNameController.text,
          from: _fromHub!,
          to: _toHub!,
          stops: [_fromHub!, _toHub!],
          type: 'Combined',
        );

        if (_editingRouteId != null) {
          await _firebaseService.updateBusSchedule(_editingRouteId!, schedule, _originalRouteName!);
        } else {
          await _firebaseService.addBusSchedule(schedule);
        }
        setEditingRoute(null);
      } finally {
        _isRouteSaving = false;
        notifyListeners();
      }
    }
  }

  Future<void> deleteRoute(String id, String routeName) async {
    await _firebaseService.deleteBusSchedule(id, routeName);
    notifyListeners();
  }

  // --- Polyline Uploader State ---
  final jsonController = TextEditingController();
  String? _selectedRouteForPolyline;
  bool _isPolylineSaving = false;

  String? get selectedRouteForPolyline => _selectedRouteForPolyline;
  bool get isPolylineSaving => _isPolylineSaving;

  void setSelectedRouteForPolyline(String? route) {
    _selectedRouteForPolyline = route;
    notifyListeners();
  }

  Future<void> uploadPolyline() async {
    if (_selectedRouteForPolyline != null && jsonController.text.isNotEmpty) {
      _isPolylineSaving = true;
      notifyListeners();

      try {
        final List<dynamic> coordinates = jsonDecode(jsonController.text);
        await _firebaseService.savePolyline(_selectedRouteForPolyline!, coordinates);
        jsonController.clear();
      } finally {
        _isPolylineSaving = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    latController.dispose();
    lngController.dispose();
    routeNameController.dispose();
    jsonController.dispose();
    super.dispose();
  }
}
