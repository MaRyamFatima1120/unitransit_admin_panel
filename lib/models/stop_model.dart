class StopModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String route;

  StopModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.route,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'route': route,
    };
  }

  factory StopModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return StopModel(
      id: id,
      name: map['name'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      route: map['route'] ?? '',
    );
  }
}
