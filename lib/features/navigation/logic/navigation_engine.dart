import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';

import '../../../core/config/app_config.dart';
import '../../../data/models/route.dart';
import '../../../data/services/compass_service.dart';
import '../../../data/services/gps_service.dart';

/// Navigation state
enum NavigationState {
  idle,       // Not navigating
  navigating, // Active navigation
  paused,     // Navigation paused
}

/// Navigation data model
class NavigationData {
  final NavigationState state;
  final Route? activeRoute;
  final int currentWaypointIndex;
  final double? targetHeading; // Bearing to next waypoint (0-360°)
  final double? currentHeading; // Current compass heading (0-360°)
  final double? headingError; // Difference (normalized -180 to +180)
  final double? distanceToTarget; // Distance to next waypoint (meters)
  final double? crossTrackDistance; // Perpendicular distance from route (meters)
  final double bufferRadius; // Current buffer setting (meters)
  
  NavigationData({
    this.state = NavigationState.idle,
    this.activeRoute,
    this.currentWaypointIndex = 0,
    this.targetHeading,
    this.currentHeading,
    this.headingError,
    this.distanceToTarget,
    this.crossTrackDistance,
    this.bufferRadius = AppConfig.defaultBufferRadius,
  });
  
  NavigationData copyWith({
    NavigationState? state,
    Route? activeRoute,
    int? currentWaypointIndex,
    double? targetHeading,
    double? currentHeading,
    double? headingError,
    double? distanceToTarget,
    double? crossTrackDistance,
    double? bufferRadius,
  }) {
    return NavigationData(
      state: state ?? this.state,
      activeRoute: activeRoute ?? this.activeRoute,
      currentWaypointIndex: currentWaypointIndex ?? this.currentWaypointIndex,
      targetHeading: targetHeading ?? this.targetHeading,
      currentHeading: currentHeading ?? this.currentHeading,
      headingError: headingError ?? this.headingError,
      distanceToTarget: distanceToTarget ?? this.distanceToTarget,
      crossTrackDistance: crossTrackDistance ?? this.crossTrackDistance,
      bufferRadius: bufferRadius ?? this.bufferRadius,
    );
  }
}

/// Provider for navigation engine
final navigationEngineProvider = StateNotifierProvider<NavigationEngine, NavigationData>((ref) {
  final gpsService = ref.watch(gpsServiceProvider);
  final compassService = ref.watch(compassServiceProvider);
  return NavigationEngine(gpsService, compassService);
});

/// Navigation Engine - Core logic for route following
class NavigationEngine extends StateNotifier<NavigationData> {
  final GPSService _gpsService;
  final CompassService _compassService;
  final Logger _logger = Logger();
  
  StreamSubscription<Position?>? _positionSubscription;
  StreamSubscription<double?>? _headingSubscription;
  
  NavigationEngine(this._gpsService, this._compassService) : super(NavigationData());
  
  /// Start navigation with a route
  Future<void> startNavigation(Route route) async {
    _logger.i('Navigation: Starting with route "${route.name}"');
    
    // Ensure GPS and compass are tracking
    if (!_gpsService.isTracking) {
      await _gpsService.startTracking();
    }
    if (!_compassService.isTracking) {
      await _compassService.startTracking();
    }
    
    state = state.copyWith(
      state: NavigationState.navigating,
      activeRoute: route,
      currentWaypointIndex: 0,
    );
    
    // Subscribe to sensor updates
    _positionSubscription = _gpsService.positionStream.listen(_onPositionUpdate);
    _headingSubscription = _compassService.headingStream.listen(_onHeadingUpdate);
    
    // Initial calculation
    _updateNavigationData();
  }
  
  /// Stop navigation
  Future<void> stopNavigation() async {
    _logger.i('Navigation: Stopping');
    
    await _positionSubscription?.cancel();
    await _headingSubscription?.cancel();
    
    state = NavigationData(); // Reset to idle
  }
  
  /// Pause navigation
  void pauseNavigation() {
    if (state.state == NavigationState.navigating) {
      state = state.copyWith(state: NavigationState.paused);
      _logger.i('Navigation: Paused');
    }
  }
  
  /// Resume navigation
  void resumeNavigation() {
    if (state.state == NavigationState.paused) {
      state = state.copyWith(state: NavigationState.navigating);
      _logger.i('Navigation: Resumed');
    }
  }
  
  /// Set buffer radius
  void setBufferRadius(double radius) {
    state = state.copyWith(bufferRadius: radius);
    _logger.i('Navigation: Buffer radius set to ${radius.toStringAsFixed(0)}m');
  }
  
  /// Toggle route direction (Ida ↔ Volta)
  void toggleRouteDirection() {
    if (state.activeRoute == null) return;
    
    final route = state.activeRoute!;
    route.toggleDirection();
    
    // Reset to first waypoint of reversed route
    state = state.copyWith(
      activeRoute: route,
      currentWaypointIndex: 0,
    );
    
    _updateNavigationData();
    _logger.i('Navigation: Direction toggled to ${route.direction}');
  }
  
  /// Handle GPS position updates
  void _onPositionUpdate(Position? position) {
    if (position == null || state.state != NavigationState.navigating) return;
    _updateNavigationData();
  }
  
  /// Handle compass heading updates
  void _onHeadingUpdate(double? heading) {
    if (heading == null || state.state != NavigationState.navigating) return;
    
    state = state.copyWith(currentHeading: heading);
    _updateNavigationData();
  }
  
  /// Update all navigation calculations
  void _updateNavigationData() {
    final route = state.activeRoute;
    final position = _gpsService.currentPosition;
    final heading = _compassService.heading;
    
    if (route == null || position == null) return;
    
    final orderedPoints = route.orderedPoints;
    if (state.currentWaypointIndex >= orderedPoints.length) {
      _logger.i('Navigation: Route completed!');
      stopNavigation();
      return;
    }
    
    final targetPoint = orderedPoints[state.currentWaypointIndex];
    
    // Calculate bearing to target
    final targetHeading = _calculateBearing(
      position.latitude,
      position.longitude,
      targetPoint.latitude,
      targetPoint.longitude,
    );
    
    // Calculate distance to target
    final distanceToTarget = _calculateDistance(
      position.latitude,
      position.longitude,
      targetPoint.latitude,
      targetPoint.longitude,
    );
    
    // Calculate heading error (if compass available)
    double? headingError;
    if (heading != null) {
      headingError = _calculateHeadingError(heading, targetHeading);
    }
    
    // Calculate cross-track distance
    double? crossTrackDistance;
    if (state.currentWaypointIndex < orderedPoints.length - 1) {
      final nextPoint = orderedPoints[state.currentWaypointIndex + 1];
      crossTrackDistance = _calculateCrossTrackDistance(
        position.latitude,
        position.longitude,
        targetPoint.latitude,
        targetPoint.longitude,
        nextPoint.latitude,
        nextPoint.longitude,
      );
    }
    
    state = state.copyWith(
      targetHeading: targetHeading,
      currentHeading: heading,
      headingError: headingError,
      distanceToTarget: distanceToTarget,
      crossTrackDistance: crossTrackDistance,
    );
    
    // Check if reached waypoint
    if (distanceToTarget < AppConfig.waypointThresholdMeters) {
      _advanceToNextWaypoint();
    }
    
    _logger.d(
      'Navigation: target=${targetHeading.toStringAsFixed(0)}°, '
      'distance=${distanceToTarget.toStringAsFixed(0)}m, '
      'error=${headingError?.toStringAsFixed(0)}°'
    );
  }
  
  /// Advance to next waypoint
  void _advanceToNextWaypoint() {
    final newIndex = state.currentWaypointIndex + 1;
    final route = state.activeRoute!;
    
    if (newIndex < route.orderedPoints.length) {
      state = state.copyWith(currentWaypointIndex: newIndex);
      _logger.i('Navigation: Advanced to waypoint $newIndex');
    } else {
      _logger.i('Navigation: Reached final waypoint!');
      // Could auto-stop or trigger completion event
    }
  }
  
  /// Calculate bearing between two points (0-360°)
  double _calculateBearing(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    final bearing = Geolocator.bearingBetween(startLat, startLng, endLat, endLng);
    // Normalize to 0-360°
    return (bearing + 360) % 360;
  }
  
  /// Calculate distance between two points (meters)
  double _calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
  
  /// Calculate heading error (normalized to -180 to +180)
  /// Negative = turn left, Positive = turn right
  double _calculateHeadingError(double currentHeading, double targetHeading) {
    double error = targetHeading - currentHeading;
    
    // Normalize to -180 to +180
    if (error > 180) error -= 360;
    if (error < -180) error += 360;
    
    return error;
  }
  
  /// Calculate cross-track distance (perpendicular distance from route line)
  /// Uses spherical Earth model for accuracy
  double _calculateCrossTrackDistance(
    double currentLat,
    double currentLng,
    double lineStartLat,
    double lineStartLng,
    double lineEndLat,
    double lineEndLng,
  ) {
    // Convert to radians
    final lat1 = lineStartLat * math.pi / 180;
    final lon1 = lineStartLng * math.pi / 180;
    final lat2 = lineEndLat * math.pi / 180;
    final lon2 = lineEndLng * math.pi / 180;
    final lat3 = currentLat * math.pi / 180;
    final lon3 = currentLng * math.pi / 180;
    
    // Distance from start to current position
    final dLat = lat3 - lat1;
    final dLon = lon3 - lon1;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat3) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    const earthRadius = 6371000.0; // meters
    final d13 = earthRadius * c;
    
    // Bearing from start to current
    final y = math.sin(lon3 - lon1) * math.cos(lat3);
    final x = math.cos(lat1) * math.sin(lat3) -
        math.sin(lat1) * math.cos(lat3) * math.cos(lon3 - lon1);
    final brng13 = math.atan2(y, x);
    
    // Bearing from start to end
    final y2 = math.sin(lon2 - lon1) * math.cos(lat2);
    final x2 = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(lon2 - lon1);
    final brng12 = math.atan2(y2, x2);
    
    // Cross-track distance
    final dXt = math.asin(math.sin(d13 / earthRadius) * math.sin(brng13 - brng12)) * earthRadius;
    
    return dXt;
  }
  
  @override
  void dispose() {
    _positionSubscription?.cancel();
    _headingSubscription?.cancel();
    super.dispose();
  }
}