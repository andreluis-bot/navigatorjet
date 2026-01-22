import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';

part 'route.g.dart';

/// Direction of route navigation
@HiveType(typeId: 2)
enum RouteDirection {
  @HiveField(0)
  forward, // Start → End (Ida)
  
  @HiveField(1)
  reverse, // End → Start (Volta)
}

/// Single point in a GPS route
@HiveType(typeId: 1)
class RoutePoint {
  @HiveField(0)
  final double latitude;

  @HiveField(1)
  final double longitude;

  @HiveField(2)
  final double? elevation;

  @HiveField(3)
  final int segmentIndex;

  RoutePoint({
    required this.latitude,
    required this.longitude,
    this.elevation,
    this.segmentIndex = 0,
  });

  /// Convert to LatLng for map rendering
  LatLng toLatLng() => LatLng(latitude, longitude);

  /// Calculate distance to another point (meters)
  double distanceTo(RoutePoint other) {
    const distance = Distance();
    return distance(toLatLng(), other.toLatLng());
  }

  /// Calculate bearing to another point (0-360°)
  double bearingTo(RoutePoint other) {
    const distance = Distance();
    return distance.bearing(toLatLng(), other.toLatLng());
  }

  RoutePoint copyWith({
    double? latitude,
    double? longitude,
    double? elevation,
    int? segmentIndex,
  }) {
    return RoutePoint(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      elevation: elevation ?? this.elevation,
      segmentIndex: segmentIndex ?? this.segmentIndex,
    );
  }

  @override
  String toString() {
    return 'RoutePoint(lat: $latitude, lng: $longitude, elev: $elevation)';
  }
}

/// Complete GPS route with metadata
@HiveType(typeId: 0)
class Route {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final List<RoutePoint> points;

  @HiveField(3)
  RouteDirection direction;

  @HiveField(4)
  final double totalDistance; // meters

  @HiveField(5)
  final int lineColorValue; // Store as int for Hive

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime? updatedAt;

  Route({
    required this.id,
    required this.name,
    required this.points,
    this.direction = RouteDirection.forward,
    required this.totalDistance,
    Color? lineColor,
    DateTime? createdAt,
    this.updatedAt,
  })  : lineColorValue = (lineColor ?? Colors.orange).value,
        createdAt = createdAt ?? DateTime.now();

  /// Get Color object from stored int value
  Color get lineColor => Color(lineColorValue);

  /// Get ordered points based on current direction
  List<RoutePoint> get orderedPoints {
    if (direction == RouteDirection.forward) {
      return points;
    } else {
      return points.reversed.toList();
    }
  }

  /// Reverse route direction (Ida ↔ Volta)
  void toggleDirection() {
    direction = direction == RouteDirection.forward
        ? RouteDirection.reverse
        : RouteDirection.forward;
  }

  /// Get total number of waypoints
  int get waypointCount => points.length;

  /// Get estimated duration (assuming average speed of 30 km/h)
  Duration get estimatedDuration {
    const avgSpeedKmH = 30.0;
    final hours = (totalDistance / 1000) / avgSpeedKmH;
    return Duration(minutes: (hours * 60).round());
  }

  /// Get bounding box for map fitting
  ({LatLng southwest, LatLng northeast}) getBounds() {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return (
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Route copyWith({
    String? id,
    String? name,
    List<RoutePoint>? points,
    RouteDirection? direction,
    double? totalDistance,
    Color? lineColor,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Route(
      id: id ?? this.id,
      name: name ?? this.name,
      points: points ?? this.points,
      direction: direction ?? this.direction,
      totalDistance: totalDistance ?? this.totalDistance,
      lineColor: lineColor ?? this.lineColor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Route(name: $name, points: ${points.length}, distance: ${(totalDistance / 1000).toStringAsFixed(2)} km, direction: $direction)';
  }
}