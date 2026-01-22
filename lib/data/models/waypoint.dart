import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';

part 'waypoint.g.dart';

/// Type of waypoint icon
@HiveType(typeId: 4)
enum WaypointIconType {
  @HiveField(0)
  marker, // Default pin
  
  @HiveField(1)
  photo, // Photo waypoint
  
  @HiveField(2)
  danger, // Danger/incident
  
  @HiveField(3)
  anchor, // Anchoring point
  
  @HiveField(4)
  fuel, // Refueling point
}

/// Waypoint (point of interest on map)
@HiveType(typeId: 3)
class Waypoint {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double latitude;

  @HiveField(3)
  final double longitude;

  @HiveField(4)
  final String? notes;

  @HiveField(5)
  final WaypointIconType iconType;

  @HiveField(6)
  final String? photoPath;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final String? trackId; // Associated track (optional)

  @HiveField(9)
  final double? speed; // Speed when waypoint created (km/h)

  @HiveField(10)
  final double? heading; // Heading when waypoint created (0-360°)

  Waypoint({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.notes,
    this.iconType = WaypointIconType.marker,
    this.photoPath,
    DateTime? createdAt,
    this.trackId,
    this.speed,
    this.heading,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert to LatLng for map rendering
  LatLng toLatLng() => LatLng(latitude, longitude);

  /// Check if waypoint has photo
  bool get hasPhoto => photoPath != null && photoPath!.isNotEmpty;

  Waypoint copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    String? notes,
    WaypointIconType? iconType,
    String? photoPath,
    DateTime? createdAt,
    String? trackId,
    double? speed,
    double? heading,
  }) {
    return Waypoint(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      notes: notes ?? this.notes,
      iconType: iconType ?? this.iconType,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
      trackId: trackId ?? this.trackId,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
    );
  }

  @override
  String toString() {
    return 'Waypoint(name: $name, lat: $latitude, lng: $longitude, icon: $iconType)';
  }
}