import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../core/config/app_config.dart';

/// Provider for GPS service singleton
final gpsServiceProvider = Provider<GPSService>((ref) {
  return GPSService();
});

/// Current GPS position state
final currentPositionProvider = StreamProvider<Position?>((ref) {
  final gpsService = ref.watch(gpsServiceProvider);
  return gpsService.positionStream;
});

/// GPS Service - Manages location tracking and updates
class GPSService {
  final Logger _logger = Logger();
  
  // Stream controllers
  final _positionController = StreamController<Position?>.broadcast();
  
  // Current state
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;
  bool _isTracking = false;
  
  // GPS heading history (for calculating direction when stationary)
  final List<Position> _recentPositions = [];
  static const int _maxHistoryPoints = 5;
  
  // Getters
  Position? get currentPosition => _currentPosition;
  Stream<Position?> get positionStream => _positionController.stream;
  bool get isTracking => _isTracking;
  
  /// Current speed in km/h
  double? get currentSpeed {
    if (_currentPosition == null) return null;
    // Convert m/s to km/h
    return (_currentPosition!.speed * 3.6);
  }
  
  /// Current altitude in meters
  double? get altitude => _currentPosition?.altitude;
  
  /// GPS heading (only reliable when moving > 5 km/h)
  double? get gpsHeading {
    if (_currentPosition == null) return null;
    if (currentSpeed == null || currentSpeed! < AppConfig.minSpeedForGPSHeading) {
      return null; // Not reliable when stationary
    }
    return _currentPosition!.heading;
  }
  
  /// Calculate heading based on last two positions (more reliable at low speeds)
  double? getCalculatedHeading() {
    if (_recentPositions.length < 2) return null;
    
    final from = _recentPositions[_recentPositions.length - 2];
    final to = _recentPositions.last;
    
    return Geolocator.bearingBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }
  
  /// Check and request location permissions
  Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _logger.w('GPS: Location services are disabled');
      return false;
    }
    
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _logger.e('GPS: Location permissions denied');
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _logger.e('GPS: Location permissions permanently denied');
      return false;
    }
    
    _logger.i('GPS: Permissions granted');
    return true;
  }
  
  /// Start GPS tracking
  Future<void> startTracking({bool highAccuracy = true}) async {
    if (_isTracking) {
      _logger.w('GPS: Already tracking');
      return;
    }
    
    final hasPermission = await checkPermissions();
    if (!hasPermission) {
      throw Exception('GPS permissions not granted');
    }
    
    _logger.i('GPS: Starting tracking (highAccuracy: $highAccuracy)');
    
    final locationSettings = LocationSettings(
      accuracy: highAccuracy ? LocationAccuracy.high : LocationAccuracy.medium,
      distanceFilter: 5, // Update every 5 meters
    );
    
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      _onPositionUpdate,
      onError: (error) {
        _logger.e('GPS: Error - $error');
      },
    );
    
    _isTracking = true;
  }
  
  /// Stop GPS tracking
  Future<void> stopTracking() async {
    if (!_isTracking) return;
    
    _logger.i('GPS: Stopping tracking');
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
  }
  
  /// Handle position updates
  void _onPositionUpdate(Position position) {
    // Check accuracy threshold
    if (position.accuracy > AppConfig.minGPSAccuracy) {
      _logger.w('GPS: Low accuracy (${position.accuracy.toStringAsFixed(1)}m)');
      // Still update, but users should be warned
    }
    
    _currentPosition = position;
    
    // Maintain history for heading calculation
    _recentPositions.add(position);
    if (_recentPositions.length > _maxHistoryPoints) {
      _recentPositions.removeAt(0);
    }
    
    _positionController.add(position);
    
    _logger.d(
      'GPS: lat=${position.latitude.toStringAsFixed(6)}, '
      'lng=${position.longitude.toStringAsFixed(6)}, '
      'acc=${position.accuracy.toStringAsFixed(1)}m, '
      'spd=${(position.speed * 3.6).toStringAsFixed(1)}km/h'
    );
  }
  
  /// Get current position once (no streaming)
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await checkPermissions();
    if (!hasPermission) return null;
    
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentPosition = position;
      return position;
    } catch (e) {
      _logger.e('GPS: Failed to get current position - $e');
      return null;
    }
  }
  
  /// Calculate distance between two positions (meters)
  static double distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
  
  /// Calculate bearing between two positions (0-360°)
  static double bearingBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    final bearing = Geolocator.bearingBetween(startLat, startLng, endLat, endLng);
    // Normalize to 0-360°
    return (bearing + 360) % 360;
  }
  
  /// Dispose resources
  void dispose() {
    _positionSubscription?.cancel();
    _positionController.close();
  }
}