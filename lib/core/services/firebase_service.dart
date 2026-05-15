import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unitransit_admin/models/driver_model.dart';
import 'package:unitransit_admin/models/student_model.dart';
import 'package:unitransit_admin/models/bus_schedule_model.dart';
import 'package:unitransit_admin/models/hub_model.dart';
import 'package:unitransit_admin/models/support_ticket_model.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;

  // Create Driver Authentication without logging out the admin
  Future<void> createDriverAuth(String email, String password) async {
    try {
      // Use a secondary app instance to avoid logging out the current admin user
      FirebaseApp secondaryApp;
      try {
        secondaryApp = Firebase.app('SecondaryApp');
      } catch (e) {
        secondaryApp = await Firebase.initializeApp(
          name: 'SecondaryApp',
          options: Firebase.app().options,
        );
      }
      
      await FirebaseAuth.instanceFor(app: secondaryApp).createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Delete the secondary app instance to clean up
      await secondaryApp.delete();
    } catch (e) {
      throw 'Authentication creation failed: $e';
    }
  }

  // Generic Image Upload
  Future<String> uploadImage(Uint8List fileBytes, String path) async {
    try {
      print("Starting image upload to path: $path");
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putData(fileBytes);
      final snapshot = await uploadTask;
      String url = await snapshot.ref.getDownloadURL();
      print("Upload successful! URL obtained.");
      return url;
    } catch (e) {
      print("Image upload FAILED at $path: $e");
      rethrow;
    }
  }

  // Drivers
  Future<void> addDriver(DriverModel driver) async {
    await _db.collection('drivers').doc(driver.id).set(driver.toMap());
  }

  Stream<List<DriverModel>> getDrivers() {
    return _db.collection('drivers').orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => DriverModel.fromMap(doc.data())).toList();
    });
  }

  Future<void> updateDriver(DriverModel driver) async {
    await _db.collection('drivers').doc(driver.id).update(driver.toMap());
  }

  Future<void> deleteDriver(String id) async {
    // Note: In a real app, also delete images from storage
    await _db.collection('drivers').doc(id).delete();
  }

  // Students
  Future<void> addStudent(StudentModel student) async {
    await _db.collection('students').doc(student.id).set(student.toMap());
  }

  Stream<List<StudentModel>> getStudents() {
    return _db.collection('students').orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => StudentModel.fromMap(doc.data())).toList();
    });
  }

  Future<void> updateStudent(StudentModel student) async {
    await _db.collection('students').doc(student.id).update(student.toMap());
  }

  Future<void> deleteStudent(String id) async {
    await _db.collection('students').doc(id).delete();
  }

  // Routes & Schedules
  Future<void> addBusSchedule(BusSchedule schedule) async {
    // 1. Save to Firestore (Detailed Info)
    await _db.collection('schedules').doc(schedule.id).set(schedule.toMap());
    
    // 2. Save to Realtime Database (Dropdown Info for Student App)
    await _rtdb.ref('official_routes').child(schedule.route).set({
      'from': schedule.from,
      'to': schedule.to,
    });
  }

  Future<void> deleteBusSchedule(String id, String routeName) async {
    // 1. Delete from Firestore
    await _db.collection('schedules').doc(id).delete();
    
    // 2. Delete from Realtime Database
    await _rtdb.ref('official_routes').child(routeName).remove();
    // 3. Delete Polyline if exists
    await _rtdb.ref('custom_polylines').child(routeName).remove();
  }

  // Hub Management (RTDB)
  Future<void> addHub(HubModel hub) async {
    await _rtdb.ref('hubs').child(hub.name).set(hub.toMap());
  }

  Future<void> updateHub(HubModel hub, String oldName) async {
    if (hub.name != oldName) {
      await _rtdb.ref('hubs').child(oldName).remove();
      
      // Optional: Update all routes that use this hub name
      final routesData = await _rtdb.ref('official_routes').get();
      if (routesData.exists) {
        final Map<dynamic, dynamic> routes = routesData.value as Map<dynamic, dynamic>;
        routes.forEach((key, value) async {
          final Map<dynamic, dynamic> route = value as Map<dynamic, dynamic>;
          bool changed = false;
          if (route['from'] == oldName) {
            route['from'] = hub.name;
            changed = true;
          }
          if (route['to'] == oldName) {
            route['to'] = hub.name;
            changed = true;
          }
          if (changed) {
            await _rtdb.ref('official_routes').child(key).update(Map<String, dynamic>.from(route));
          }
        });
      }
    }
    await _rtdb.ref('hubs').child(hub.name).set(hub.toMap());
  }

  Stream<List<HubModel>> getHubs() {
    return _rtdb.ref('hubs').onValue.map((event) {
      final Map<dynamic, dynamic>? data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];
      return data.entries.map((e) => HubModel.fromMap(e.key.toString(), e.value as Map<dynamic, dynamic>)).toList();
    });
  }

  Future<void> deleteHub(String name) async {
    await _rtdb.ref('hubs').child(name).remove();
  }

  // Polyline Management (RTDB)
  Future<void> savePolyline(String routeName, List<dynamic> coordinates) async {
    await _rtdb.ref('custom_polylines').child(routeName).set(coordinates);
  }

  Future<void> updateBusSchedule(String id, BusSchedule schedule, String oldRouteName) async {
    // 1. Update Firestore
    await _db.collection('schedules').doc(id).update(schedule.toMap());

    // 2. Update RTDB (official_routes)
    if (schedule.route != oldRouteName) {
      await _rtdb.ref('official_routes').child(oldRouteName).remove();
      // Also move polyline if exists
      final polylineData = await _rtdb.ref('custom_polylines').child(oldRouteName).get();
      if (polylineData.exists) {
        await _rtdb.ref('custom_polylines').child(schedule.route).set(polylineData.value);
        await _rtdb.ref('custom_polylines').child(oldRouteName).remove();
      }
    }

    await _rtdb.ref('official_routes').child(schedule.route).set({
      'from': schedule.from,
      'to': schedule.to,
    });
  }

  Stream<Map<String, dynamic>> getPolylinesStatus() {
    return _rtdb.ref('custom_polylines').onValue.map((event) {
      final Map<dynamic, dynamic>? data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return {};
      return Map<String, dynamic>.from(data);
    });
  }

  // Dashboard Stats
  Future<Map<String, int>> getStats() async {
    final drivers = await _db.collection('drivers').get();
    final students = await _db.collection('students').get();
    return {
      'totalDrivers': drivers.docs.length,
      'totalStudents': students.docs.length,
    };
  }

  // Gender Configuration (RTDB)
  Future<void> updateGenderConfig(String name, String colorHex) async {
    await _rtdb.ref('gender_configs').child(name).set({
      'color': colorHex,
    });
  }

  Future<void> deleteGenderConfig(String name) async {
    await _rtdb.ref('gender_configs').child(name).remove();
  }

  Stream<Map<String, String>> getGenderConfigs() {
    return _rtdb.ref('gender_configs').onValue.map((event) {
      final Map<dynamic, dynamic>? data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return {};
      
      final Map<String, String> result = {};
      data.forEach((key, value) {
        if (value is Map && value.containsKey('color')) {
          result[key.toString()] = value['color'].toString();
        }
      });
      return result;
    });
  }

  // Support Tickets
  Stream<List<SupportTicketModel>> getTickets() {
    return _db
        .collection('support_tickets')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SupportTicketModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> updateTicketStatus(String ticketId, String status, {String? reply}) async {
    final Map<String, dynamic> updates = {
      'status': status,
    };
    if (reply != null) {
      updates['adminReply'] = reply;
    }
    if (status.toLowerCase() == 'resolved' || status.toLowerCase() == 'closed') {
      updates['resolvedAt'] = Timestamp.now();
    }
    await _db.collection('support_tickets').doc(ticketId).update(updates);
  }

  // App Settings / About Info
  Future<void> uploadInitialAppInfo() async {
    final doc = await _db.collection('app_settings').doc('about').get();
    if (!doc.exists) {
      await _db.collection('app_settings').doc('about').set({
        'vision': "UniTransit is a state-of-the-art solution designed for The Islamia University of Bahawalpur to digitize the bus tracking experience. It leverages real-time GPS data, Firebase synchronization, and smart routing algorithms to ensure students never miss their commute.",
        'version': "1.2.0 (Stable)",
        'university': "The Islamia University of Bahawalpur",
        'appLogoUrl': "", // Add image URL here later from Admin Panel
        'contributors': [
          {"role": "Lead Developer", "name": "Noor Mustafa", "subtitle": "Roll No: F22BDOCS1M01160"},
          {"role": "Supervisor", "name": "Dr. Umar Farooq Shafi", "subtitle": "Department of CS & IT, IUB"},
        ],
      });
    }
  }

  Future<void> updateAppInfo(Map<String, dynamic> data) async {
    await _db.collection('app_settings').doc('about').set(data);
  }
}

