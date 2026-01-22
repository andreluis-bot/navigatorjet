import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Provider for Compass service singleton
final compassServiceProvider = Provider<CompassService>((ref) {
  return CompassService();
});

/// Current heading state
final currentHeadingProvider = StreamProvider<double?>((ref) {
  final compassService = ref.watch(compassServiceProvider);
  return compassService.headingStream;
});

/// Compass Service - Manages magnetic heading with sensor fusion
class CompassService {
  final Logger _logger = Logger();
  
  // Stream controllers
  final _headingController = StreamController<double?>.broadcast();
  
  // Subscriptions
  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  
  // Current state
  double? _magneticHeading; // Raw from magnetometer
  double? _fusedHeading; // After sensor fusion
  bool _isCalibrated = false;
  double _calibrationQuality = 0.0; // 0-100%
  bool _isTracking = false;
  
  // Gyroscope integration for fusion
  double _integratedGyroHeading = 0.0;
  DateTime? _lastGyroUpdate;
  
  // Magnetometer quality tracking
  final List<double> _recentReadings = [];
  static const int _maxReadings = 10;
  
  // Getters
  double? get magneticHeading => _magneticHeading;
  double? get heading => _fusedHeading ?? _magneticHeading; // Prefer fused
  Stream<double?> get headingStream => _headingController.stream;
  bool get isCalibrated => _isCalibrated;
  double get calibrationQuality => _calibrationQuality;
  bool get isTracking => _isTracking;
  
  /// True heading (with magnetic declination correction)
  /// TODO: Add declination lookup based on GPS position
  double? get trueHeading {
    if (heading == null) return null;
    // For now, assuming declination = 0
    // In future: lookup declination from GPS position
    return heading;
  }
  
  /// Start compass tracking
  Future<void> startTracking() async {
    if (_isTracking) {
      _logger.w('Compass: Already tracking');
      return;
    }
    
    _logger.i('Compass: Starting tracking');
    
    // Start magnetometer stream
    _compassSubscription = FlutterCompass.events?.listen(
      _onCompassUpdate,
      onError: (error) {
        _logger.e('Compass: Error - $error');
      },
    );
    
    // Start gyroscope stream for fusion
    _gyroSubscription = gyroscopeEventStream().listen(
      _onGyroUpdate,
      onError: (error) {
        _logger.e('Gyroscope: Error - $error');
      },
    );
    
    _isTracking = true;
  }
  
  /// Stop compass tracking
  Future<void> stopTracking() async {
    if (!_isTracking) return;
    
    _logger.i('Compass: Stopping tracking');
    await _compassSubscription?.cancel();
    await _gyroSubscription?.cancel();
    _compassSubscription = null;
    _gyroSubscription = null;
    _isTracking = false;
  }
  
  /// Handle compass updates from magnetometer
  void _onCompassUpdate(CompassEvent event) {
    if (event.heading == null) return;
    
    _magneticHeading = event.heading!;
    
    // Track reading quality
    _recentReadings.add(_magneticHeading!);
    if (_recentReadings.length > _maxReadings) {
      _recentReadings.removeAt(0);
    }
    
    // Calculate quality based on variance
    _updateCalibrationQuality();
    
    // Apply sensor fusion
    _updateFusedHeading();
    
    _headingController.add(_fusedHeading);
    
    _logger.d(
      'Compass: mag=${_magneticHeading!.toStringAsFixed(1)}°, '
      'fused=${_fusedHeading?.toStringAsFixed(1)}°, '
      'quality=${_calibrationQuality.toStringAsFixed(0)}%'
    );
  }
  
  /// Handle gyroscope updates
  void _onGyroUpdate(GyroscopeEvent event) {
    final now = DateTime.now();
    
    if (_lastGyroUpdate != null) {
      final dt = now.difference(_lastGyroUpdate!).inMilliseconds / 1000.0;
      
      // Integrate gyro Z-axis (rotation around vertical axis)
      // Convert rad/s to degrees/s
      final rotationRate = event.z * (180 / math.pi);
      _integratedGyroHeading += rotationRate * dt;
      
      // Normalize to 0-360°
      _integratedGyroHeading = (_integratedGyroHeading % 360);
      if (_integratedGyroHeading < 0) _integratedGyroHeading += 360;
    }
    
    _lastGyroUpdate = now;
  }
  
  /// Sensor fusion: Complementary filter
  /// 90% magnetometer (slow, accurate) + 10% gyroscope (fast, drift-prone)
  void _updateFusedHeading() {
    if (_magneticHeading == null) return;
    
    if (_integratedGyroHeading == 0.0 || _calibrationQuality < 30) {
      // Low quality or no gyro data - use magnetometer only
      _fusedHeading = _magneticHeading;
      return;
    }
    
    // Complementary filter weights based on calibration quality
    final magWeight = _calibrationQuality / 100.0; // 0.0 to 1.0
    final gyroWeight = 1.0 - magWeight;
    
    // Handle angle wraparound (e.g., 359° and 1° should average to 0°)
    double mag = _magneticHeading!;
    double gyro = _integratedGyroHeading;
    
    double diff = (gyro - mag).abs();
    if (diff > 180) {
      if (gyro > mag) {
        mag += 360;
      } else {
        gyro += 360;
      }
    }
    
    _fusedHeading = (magWeight * mag + gyroWeight * gyro) % 360;
    
    // Slowly drift gyro towards magnetometer to prevent long-term drift
    _integratedGyroHeading = _fusedHeading!;
  }
  
  /// Calculate calibration quality based on variance of recent readings
  void _updateCalibrationQuality() {
    if (_recentReadings.length < 3) {
      _calibrationQuality = 0.0;
      _isCalibrated = false;
      return;
    }
    
    // Calculate circular variance
    double sumSin = 0.0;
    double sumCos = 0.0;
    
    for (final heading in _recentReadings) {
      final rad = heading * (math.pi / 180.0);
      sumSin += math.sin(rad);
      sumCos += math.cos(rad);
    }
    
    final meanSin = sumSin / _recentReadings.length;
    final meanCos = sumCos / _recentReadings.length;
    final R = math.sqrt(meanSin * meanSin + meanCos * meanCos);
    
    // R close to 1 = low variance (good)
    // R close to 0 = high variance (bad)
    _calibrationQuality = (R * 100).clamp(0.0, 100.0);
    
    // Consider calibrated if quality > 70%
    _isCalibrated = _calibrationQuality > 70.0;
    
    if (!_isCalibrated && _recentReadings.length >= _maxReadings) {
      _logger.w('Compass: Poor calibration (${_calibrationQuality.toStringAsFixed(0)}%). Move device in figure-8 pattern.');
    }
  }
  
  /// Detect magnetic interference (e.g., from jet ski motor)
  bool isInterferenceDetected() {
    // High variance in recent readings suggests interference
    return _calibrationQuality < 50.0 && _recentReadings.length >= _maxReadings;
  }
  
  /// Reset gyro integration (useful after long period or detected drift)
  void resetGyroIntegration() {
    if (_magneticHeading != null) {
      _integratedGyroHeading = _magneticHeading!;
      _logger.i('Compass: Gyro integration reset to magnetometer');
    }
  }
  
  /// Manual calibration trigger
  Future<void> calibrate() async {
    _logger.i('Compass: Starting calibration...');
    _recentReadings.clear();
    _isCalibrated = false;
    _calibrationQuality = 0.0;
    
    // User should move device in figure-8 pattern
    // Calibration will complete automatically when quality improves
  }
  
  /// Dispose resources
  void dispose() {
    _compassSubscription?.cancel();
    _gyroSubscription?.cancel();
    _headingController.close();
  }
}