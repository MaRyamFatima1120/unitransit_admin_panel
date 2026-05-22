import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart' hide Query;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unitransit_admin/models/driver_model.dart';
import 'package:unitransit_admin/models/student_model.dart';
import 'package:unitransit_admin/models/bus_schedule_model.dart';
import 'package:unitransit_admin/models/hub_model.dart';
import 'package:unitransit_admin/models/stop_model.dart';
import 'package:unitransit_admin/models/support_ticket_model.dart';
import 'package:unitransit_admin/models/faq_model.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;

  // Create User Authentication without logging out the current admin
  Future<String> createUserAuth(String email, String password) async {
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
      
      final credential = await FirebaseAuth.instanceFor(app: secondaryApp).createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final uid = credential.user!.uid;
      
      // Delete the secondary app instance to clean up
      await secondaryApp.delete();
      return uid;
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
    await _db.collection('users').doc(driver.id).set({
      'uid': driver.id,
      'name': driver.name,
      'email': driver.email,
      'role': 'Driver',
      'isVerified': driver.isVerified,
      'isBlocked': driver.isBlocked,
      'status': driver.status,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<DriverModel>> getDrivers() {
    return _db.collection('drivers').orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => DriverModel.fromMap(doc.data())).toList();
    });
  }

  Future<void> updateDriver(DriverModel driver) async {
    await _db.collection('drivers').doc(driver.id).update(driver.toMap());
    try {
      await _db.collection('users').doc(driver.id).update({
        'isVerified': driver.isVerified,
        'isBlocked': driver.isBlocked,
        'status': driver.status,
        'name': driver.name,
      });
    } catch (_) {
      await _db.collection('users').doc(driver.id).set({
        'uid': driver.id,
        'name': driver.name,
        'email': driver.email,
        'role': 'Driver',
        'isVerified': driver.isVerified,
        'isBlocked': driver.isBlocked,
        'status': driver.status,
      }, SetOptions(merge: true));
    }
  }

  Future<void> deleteDriver(String id) async {
    // Note: In a real app, also delete images from storage
    await _db.collection('drivers').doc(id).delete();
    await _db.collection('users').doc(id).delete();
  }

  Future<void> resetDriverPassword(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  Future<void> resetStudentPassword(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  // Students
  Future<void> addStudent(StudentModel student) async {
    await _db.collection('users').doc(student.id).set(student.toMap());
    await _db.collection('students').doc(student.id).set(student.toMap(), SetOptions(merge: true));
  }

  Stream<List<StudentModel>> getStudents() {
    return _db.collection('users').where('role', isEqualTo: 'Student').snapshots().map((snapshot) {
      final students = snapshot.docs.map((doc) => StudentModel.fromMap(doc.data(), docId: doc.id)).toList();
      students.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return students;
    });
  }

  Future<void> updateStudent(StudentModel student) async {
    await _db.collection('users').doc(student.id).update(student.toMap());
    try {
      await _db.collection('students').doc(student.id).update(student.toMap());
    } catch (_) {
      await _db.collection('students').doc(student.id).set(student.toMap(), SetOptions(merge: true));
    }
  }

  Future<void> deleteStudent(String id) async {
    await _db.collection('users').doc(id).delete();
  }

  // Routes & Schedules
  Stream<List<BusSchedule>> getBusSchedules() {
    return _db.collection('schedules').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => BusSchedule.fromMap(doc.id, doc.data())).toList();
    });
  }

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
    // 0. Clean up driver assignment
    try {
      final scheduleDoc = await _db.collection('schedules').doc(id).get();
      if (scheduleDoc.exists) {
        final driverId = scheduleDoc.data()?['assignedDriverId'];
        if (driverId != null && driverId.toString().isNotEmpty) {
          final driverDoc = await _db.collection('drivers').doc(driverId).get();
          if (driverDoc.exists) {
            final assignedRoutes = List<String>.from(driverDoc.data()?['assignedRoutes'] ?? []);
            assignedRoutes.remove(id);
            
            // Recompute bus numbers for this driver
            final busNumbers = <String>{};
            for (final sid in assignedRoutes) {
              final sDoc = await _db.collection('schedules').doc(sid).get();
              if (sDoc.exists) {
                final bn = sDoc.data()?['busNumber'] ?? '';
                if (bn.toString().isNotEmpty && bn != 'TBA') busNumbers.add(bn);
              }
            }
            
            await _db.collection('drivers').doc(driverId).update({
              'assignedRoutes': assignedRoutes,
              'assignedBus': busNumbers.join(', '),
            });
          }
        }
      }
    } catch (e) {
      print("Error cleaning up driver assignment on schedule delete: $e");
    }

    // 1. Delete from Firestore
    await _db.collection('schedules').doc(id).delete();
    
    // Check if there are any other schedules with the same route
    final query = await _db.collection('schedules').where('route', isEqualTo: routeName).limit(1).get();
    if (query.docs.isEmpty) {
      // 2. Delete from Realtime Database only if no other schedule uses it
      await _rtdb.ref('official_routes').child(routeName).remove();
      // 3. Delete Polyline if exists
      await _rtdb.ref('custom_polylines').child(routeName).remove();
    }
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
      final data = event.snapshot.value;
      if (data is! Map) return [];
      return data.entries.map((e) {
        final val = e.value;
        return HubModel.fromMap(e.key.toString(), val is Map ? Map<dynamic, dynamic>.from(val) : {});
      }).toList();
    });
  }

  Future<void> deleteHub(String name) async {
    await _rtdb.ref('hubs').child(name).remove();
  }

  // Polyline Management (RTDB)
  Future<void> savePolyline(String routeName, List<dynamic> coordinates) async {
    await _rtdb.ref('custom_polylines').child(routeName).set(coordinates);
  }

  // Stop Management (RTDB)
  Future<void> addStop(StopModel stop) async {
    await _rtdb.ref('stops').child(stop.id).set(stop.toMap());
  }

  Future<void> updateStop(StopModel stop) async {
    await _rtdb.ref('stops').child(stop.id).update(stop.toMap());
  }

  Future<void> deleteStop(String id) async {
    await _rtdb.ref('stops').child(id).remove();
  }

  Stream<List<StopModel>> getStops() {
    return _rtdb.ref('stops').onValue.map((event) {
      final data = event.snapshot.value;
      if (data is! Map) return [];
      return data.entries.map((e) {
        final val = e.value;
        return StopModel.fromMap(e.key.toString(), val is Map ? Map<dynamic, dynamic>.from(val) : {});
      }).toList();
    });
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
      final data = event.snapshot.value;
      if (data is! Map) return {};
      return Map<String, dynamic>.from(data);
    });
  }

  // Real-time Stats Stream
  Stream<Map<String, dynamic>> getStatsStream() {
    return getRealTimeStats();
  }
  
  // Better version: combine two streams
  Stream<Map<String, dynamic>> getRealTimeStats() {
    final driversStream = _db.collection('drivers').snapshots();
    
    return driversStream.asyncMap((driversSnapshot) async {
      // 1. Students count
      final studentsSnapshot = await _db.collection('users').where('role', isEqualTo: 'Student').get();
      
      // 2. Active Trips & Total Revenue
      final completedTripsSnapshot = await _db.collection('completed_trips').get();
      double revenue = 0.0;
      int activeCount = 0;
      
      for (var doc in completedTripsSnapshot.docs) {
        final data = doc.data();
        final amount = data['revenue'] ?? data['fare'] ?? data['amount'] ?? data['totalPrice'] ?? data['price'] ?? 0;
        revenue += (amount is num ? amount.toDouble() : 0.0);
        
        final status = data['status']?.toString().toLowerCase();
        if (status == 'active' || status == 'in_progress' || status == 'ongoing' || data['isActive'] == true) {
          activeCount++;
        }
      }
      
      if (activeCount == 0) {
        try {
          final activeTripsSnapshot = await _db.collection('active_trips').get();
          activeCount += activeTripsSnapshot.docs.length;
        } catch (_) {}
        if (activeCount == 0) {
          try {
            final tripsSnapshot = await _db.collection('trips').where('status', isEqualTo: 'active').get();
            activeCount += tripsSnapshot.docs.length;
          } catch (_) {}
        }
      }
      
      return {
        'totalDrivers': driversSnapshot.docs.length,
        'totalStudents': studentsSnapshot.docs.length,
        'activeTrips': activeCount,
        'totalRevenue': revenue,
      };
    });
  }

  Future<int> getAdminsCount() async {
    final snapshot = await _db.collection('users').where('role', isEqualTo: 'Admin').get();
    return snapshot.docs.length;
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
      final data = event.snapshot.value;
      if (data is! Map) return {};
      
      final Map<String, String> result = {};
      data.forEach((key, value) {
        if (value is Map) {
          final color = value['color'];
          if (color != null) {
            result[key.toString()] = color.toString();
          }
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
      'adminRead': true,
    };
    if (reply != null) {
      updates['adminReply'] = reply;
      updates['userRead'] = false;
    }
    if (status.toLowerCase() == 'resolved' || status.toLowerCase() == 'closed') {
      updates['resolvedAt'] = Timestamp.now();
    }
    
    // Update the ticket
    await _db.collection('support_tickets').doc(ticketId).update(updates);

    // If a reply is provided, write a real-time notification to the user's notifications collection
    if (reply != null && reply.trim().isNotEmpty) {
      try {
        final docSnapshot = await _db.collection('support_tickets').doc(ticketId).get();
        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          final String? userId = data?['userId'];
          final String? userRole = data?['userRole'];
          
          if (userId != null && userId.isNotEmpty) {
            final notificationData = {
              'title': 'Support Ticket Update',
              'message': 'Your support query has been resolved: "$reply"',
              'timestamp': FieldValue.serverTimestamp(),
              'type': 'support',
              'isRead': false,
              'targetRole': userRole ?? 'Student',
            };
            
            // Write to user private notifications subcollection
            await _db.collection('users').doc(userId).collection('notifications').add(notificationData);
            
            // Write to global notifications trigger collection for FCM / functions triggers
            await _db.collection('notifications').add({
              ...notificationData,
              'userId': userId,
              'ticketId': ticketId,
            });
          }
        }
      } catch (e) {
        print('Error generating reply notification: $e');
      }
    }
  }

  Future<void> markTicketAsRead(String ticketId) async {
    try {
      await _db.collection('support_tickets').doc(ticketId).update({
        'adminRead': true,
      });
    } catch (e) {
      print('Error marking ticket as read: $e');
    }
  }

  Future<void> markEmergencyAlertAsRead(String alertId) async {
    try {
      await _rtdb.ref('emergency_alerts').child(alertId).update({
        'adminRead': true,
      });
    } catch (e) {
      print('Error marking emergency alert as read: $e');
    }
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

  // FAQs
  Stream<List<FaqModel>> getFaqs() {
    return _db.collection('faqs').orderBy('order').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => FaqModel.fromMap(doc.id, doc.data())).toList();
    });
  }

  Future<void> addFaq(FaqModel faq) async {
    await _db.collection('faqs').add(faq.toMap());
  }

  Future<void> updateFaq(FaqModel faq) async {
    await _db.collection('faqs').doc(faq.id).update(faq.toMap());
  }

  Future<void> deleteFaq(String id) async {
    await _db.collection('faqs').doc(id).delete();
  }

  Future<void> updateAppInfo(Map<String, dynamic> data) async {
    await _db.collection('app_settings').doc('about').set(data);
  }

  // Send notification to a specific user (student/driver)
  Future<void> sendUserNotification({
    required String userId,
    required String title,
    required String message,
    required String type, // 'info', 'alert', 'system', 'sos_resolved'
    String? imageUrl,
    Map<String, dynamic>? extraData,
  }) async {
    final timestamp = Timestamp.now();
    
    // 1. Save to user private notifications subcollection
    final payload = {
      'title': title,
      'message': message,
      'timestamp': timestamp,
      'type': type,
      'isRead': false,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (extraData != null) ...extraData,
    };
    
    await _db.collection('users').doc(userId).collection('notifications').add(payload);
    
    // 2. Log in global admin_notifications for tracking
    await _db.collection('admin_notifications').add({
      'title': title,
      'message': message,
      'targetAudience': 'Specific User ($userId)',
      'type': type,
      'timestamp': timestamp,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (extraData != null) ...extraData,
    });
  }

  // Send Custom Broadcast Notifications to Students, Drivers, or All
  Future<void> sendCustomNotification({
    required String title,
    required String message,
    required String targetAudience, // 'Students', 'Drivers', 'All'
    required String type, // 'info', 'alert', 'system'
    String? imageUrl,
  }) async {
    final timestamp = Timestamp.now();
    
    // 1. Save to global admin_notifications collection
    final newAlert = {
      'title': title,
      'message': message,
      'targetAudience': targetAudience,
      'type': type,
      'timestamp': timestamp,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
    await _db.collection('admin_notifications').add(newAlert);
    
    // 2. Fetch users based on targetAudience
    Query query = _db.collection('users');
    if (targetAudience == 'Students') {
      query = query.where('role', isEqualTo: 'Student');
    } else if (targetAudience == 'Drivers') {
      query = query.where('role', isEqualTo: 'Driver');
    }
    
    final usersSnapshot = await query.get();
    if (usersSnapshot.docs.isNotEmpty) {
      WriteBatch batch = _db.batch();
      int operationCount = 0;
      
      for (var doc in usersSnapshot.docs) {
        final notificationRef = _db
            .collection('users')
            .doc(doc.id)
            .collection('notifications')
            .doc();
            
        batch.set(notificationRef, {
          'title': title,
          'message': message,
          'timestamp': timestamp,
          'type': type,
          'isRead': false,
          if (imageUrl != null) 'imageUrl': imageUrl,
        });
        
        operationCount++;
        // Firestore batch limit is 500
        if (operationCount >= 450) {
          await batch.commit();
          batch = _db.batch();
          operationCount = 0;
        }
      }
      
      if (operationCount > 0) {
        await batch.commit();
      }
    }
  }

  // Get sent admin notifications stream
  Stream<List<Map<String, dynamic>>> getSentNotifications() {
    return _db
        .collection('admin_notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'message': data['message'] ?? '',
          'targetAudience': data['targetAudience'] ?? 'All',
          'type': data['type'] ?? 'info',
          'imageUrl': data['imageUrl'],
          'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    });
  }

  // Fetch all users eligible for receiving notifications (Students and Drivers)
  Future<List<Map<String, dynamic>>> getAllNotificationUsers() async {
    final snapshot = await _db.collection('users').get();
    return snapshot.docs.where((doc) {
      final role = (doc.data()['role'] ?? '').toString().toLowerCase();
      return role == 'student' || role == 'driver';
    }).map((doc) => {
      'uid': doc.id,
      'name': doc.data()['name'] ?? 'Unnamed',
      'email': doc.data()['email'] ?? '',
      'role': doc.data()['role'] ?? 'Student',
    }).toList();
  }

  // Emergency Alerts (RTDB)
  Stream<List<Map<String, dynamic>>> getEmergencyAlerts() {
    return _rtdb.ref('emergency_alerts').onValue.map((event) {
      final data = event.snapshot.value;
      if (data is! Map) return [];
      
      final List<Map<String, dynamic>> alerts = [];
      data.forEach((key, value) {
        if (value is Map) {
          final alert = Map<String, dynamic>.from(value);
          alert['id'] = key.toString();
          alerts.add(alert);
        }
      });
      
      // Sort by timestamp descending
      alerts.sort((a, b) {
        final aTime = a['timestamp'] ?? 0;
        final bTime = b['timestamp'] ?? 0;
        return bTime.compareTo(aTime);
      });
      
      return alerts;
    });
  }

  Future<void> resolveEmergencyAlert(String id, {String? notes, String? resolvedBy}) async {
    try {
      final alertSnapshot = await _rtdb.ref('emergency_alerts').child(id).get();
      if (alertSnapshot.exists) {
        final alertData = alertSnapshot.value as Map?;
        final String? userId = alertData?['userId']?.toString();
        if (userId != null && userId.isNotEmpty) {
          await sendUserNotification(
            userId: userId,
            title: 'SOS Alert Resolved 🟢',
            message: 'Admin resolved your SOS: "${notes ?? 'Incident Handled'}". Please rate our assistance.',
            type: 'sos_resolved',
            extraData: {
              'alertId': id,
              'alertMessage': alertData?['message'] ?? 'Emergency SOS Alert',
            },
          );
        }
      }
    } catch (e) {
      print("Error triggering SOS resolution notification: $e");
    }

    await _rtdb.ref('emergency_alerts').child(id).update({
      'status': 'resolved',
      'resolutionNotes': notes ?? 'Resolved by Admin',
      'resolvedBy': resolvedBy ?? 'Admin',
      'resolvedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Trip History (RTDB)
  Stream<List<Map<String, dynamic>>> getTripHistoryStream() {
    return _rtdb.ref('driver_trips').onValue.map((event) {
      final List<Map<String, dynamic>> trips = [];
      final data = event.snapshot.value;
      if (data is Map) {
        data.forEach((driverId, driverTrips) {
          if (driverTrips is Map) {
            driverTrips.forEach((tripId, tripData) {
              if (tripData is Map) {
                final trip = Map<String, dynamic>.from(tripData);
                trip['driverId'] = driverId.toString();
                trip['tripId'] = tripId.toString();
                trips.add(trip);
              }
            });
          }
        });
      }
      // Sort by startTime descending (newest first)
      trips.sort((a, b) {
        final aTime = a['startTime'] ?? 0;
        final bTime = b['startTime'] ?? 0;
        return bTime.compareTo(aTime);
      });
      return trips;
    });
  }

  // Trip Alerts (RTDB)
  Stream<Map<String, dynamic>> getTripAlertsStream() {
    return _rtdb.ref('trip_alerts').onChildAdded.map((event) {
      final value = event.snapshot.value;
      if (value is Map) {
        final alert = Map<String, dynamic>.from(value);
        alert['id'] = event.snapshot.key;
        return alert;
      }
      return {};
    });
  }
}

