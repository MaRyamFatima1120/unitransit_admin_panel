class HubModel {
  final String name;
  final double latitude;
  final double longitude;

  HubModel({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  // Convert to Map for Realtime Database
  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Create Object from Realtime Database Map
  factory HubModel.fromMap(String name, Map<dynamic, dynamic> map) {
    return HubModel(
      name: name,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
    );
  }
}
