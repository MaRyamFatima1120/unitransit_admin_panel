class BusSchedule {
  final String id;
  final String? busNumber;
  final String route;
  final String from;
  final String to;
  final String? departureTime;
  final List<String> stops;
  final String type; // Boys Special, Girls Special, Combined
  final List<String>? operatingDays; // e.g., ["Monday", "Tuesday"]
  final String? date; // Specific date in YYYY-MM-DD format
  final String? assignedDriverId;
  final String? assignedDriverName;
  final String? assignedConductorName;

  BusSchedule({
    required this.id,
    this.busNumber,
    required this.route,
    required this.from,
    required this.to,
    this.departureTime,
    required this.stops,
    required this.type,
    this.operatingDays,
    this.date,
    this.assignedDriverId,
    this.assignedDriverName,
    this.assignedConductorName,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'busNumber': busNumber ?? 'TBA',
      'route': route,
      'from': from,
      'to': to,
      'departureTime': departureTime ?? 'Live',
      'stops': stops,
      'type': type,
      'operatingDays': operatingDays ?? [],
      'date': date,
      'assignedDriverId': assignedDriverId,
      'assignedDriverName': assignedDriverName,
      'assignedConductorName': assignedConductorName,
    };
  }

  // Create Object from Firestore Map
  factory BusSchedule.fromMap(String id, Map<String, dynamic> map) {
    return BusSchedule(
      id: id,
      busNumber: map['busNumber'],
      route: map['route'] ?? '',
      from: map['from'] ?? '',
      to: map['to'] ?? '',
      departureTime: map['departureTime'],
      stops: List<String>.from(map['stops'] ?? []),
      type: map['type'] ?? 'Combined',
      operatingDays: map['operatingDays'] != null ? List<String>.from(map['operatingDays']) : null,
      date: map['date'],
      assignedDriverId: map['assignedDriverId'],
      assignedDriverName: map['assignedDriverName'],
      assignedConductorName: map['assignedConductorName'],
    );
  }

  BusSchedule copyWith({
    String? id,
    String? busNumber,
    String? route,
    String? from,
    String? to,
    String? departureTime,
    List<String>? stops,
    String? type,
    List<String>? operatingDays,
    String? date,
    String? assignedDriverId,
    String? assignedDriverName,
    String? assignedConductorName,
  }) {
    return BusSchedule(
      id: id ?? this.id,
      busNumber: busNumber ?? this.busNumber,
      route: route ?? this.route,
      from: from ?? this.from,
      to: to ?? this.to,
      departureTime: departureTime ?? this.departureTime,
      stops: stops ?? this.stops,
      type: type ?? this.type,
      operatingDays: operatingDays ?? this.operatingDays,
      date: date ?? this.date,
      assignedDriverId: assignedDriverId ?? this.assignedDriverId,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
      assignedConductorName: assignedConductorName ?? this.assignedConductorName,
    );
  }
}
