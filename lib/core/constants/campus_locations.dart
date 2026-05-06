import 'package:latlong2/latlong.dart';

class CampusLocations {
  // Official Hub Names
  static final Map<String, LatLng> locations = {
    'Main Campus': const LatLng(30.3957, 71.4883),
    'Engineering College': const LatLng(30.3980, 71.4910),
    'Medical College': const LatLng(30.3920, 71.4850),
    'Student Hostel': const LatLng(30.4000, 71.5000),
  };

  static LatLng get mainCampus => locations['Main Campus']!;
}
