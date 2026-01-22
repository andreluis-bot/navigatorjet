import 'package:flutter/material.dart';

/// Application-wide configuration constants
class AppConfig {
  // ============================================
  // COLORS (High Contrast for Sunlight)
  // ============================================
  
  /// Pure black background
  static const Color background = Color(0xFF000000);
  
  /// Pure white text
  static const Color textPrimary = Color(0xFFFFFFFF);
  
  /// Saturated green (success, center buffer)
  static const Color success = Color(0xFF00FF00);
  
  /// Saturated yellow (warning, near buffer edge)
  static const Color warning = Color(0xFFFFFF00);
  
  /// Saturated red (danger, outside buffer)
  static const Color danger = Color(0xFFFF0000);
  
  /// Cyan for current heading
  static const Color compassNeedle = Color(0xFF00FFFF);
  
  /// Magenta for target heading
  static const Color compassTarget = Color(0xFFFF00FF);
  
  /// Neon green for cardinals (N/S/E/W)
  static const Color cardinalColor = Color(0xFF00FF00);
  
  // ============================================
  // NAVIGATION SETTINGS
  // ============================================
  
  /// Distance threshold to advance to next waypoint (meters)
  static const double waypointThresholdMeters = 50.0;
  
  /// Default buffer radius for route deviation (meters)
  static const double defaultBufferRadius = 50.0;
  
  /// Buffer center zone (within 50% of radius)
  static const double bufferCenterRatio = 0.5;
  
  // ============================================
  // SENSOR SETTINGS
  // ============================================
  
  /// Normal sensor update rate (Hz)
  static const int normalFPS = 10;
  
  /// Economy sensor update rate (Hz)
  static const int ecoFPS = 1;
  
  /// Minimum GPS accuracy required (meters)
  static const double minGPSAccuracy = 20.0;
  
  /// Minimum speed for GPS heading (km/h)
  static const double minSpeedForGPSHeading = 5.0;
  
  // ============================================
  // BATTERY THRESHOLDS
  // ============================================
  
  /// Show warning when battery drops below this level (%)
  static const int batteryWarningLevel = 20;
  
  /// Force instrument mode and eco settings below this level (%)
  static const int batteryCriticalLevel = 10;
  
  // ============================================
  // UI DIMENSIONS
  // ============================================
  
  /// Height of compass tape at top of screen (px)
  static const double compassTapeHeight = 120.0;
  
  /// Height of metrics bar at bottom of screen (px)
  static const double metricsBarHeight = 80.0;
  
  /// Size of compass in instrument mode (px)
  static const double instrumentCompassSize = 300.0;
  
  // ============================================
  // COMPASS TAPE CONFIGURATION
  // ============================================
  
  /// Distance between degree marks (px)
  static const double degreeSpacing = 6.0;
  
  /// Height of small tick marks (1° intervals)
  static const double smallTickHeight = 8.0;
  
  /// Height of medium tick marks (5° intervals)
  static const double mediumTickHeight = 12.0;
  
  /// Height of large tick marks (10° intervals)
  static const double largeTickHeight = 16.0;
  
  /// Font size for degree labels
  static const double degreeLabelSize = 13.0;
  
  /// Font size for cardinal letters (N/S/E/W)
  static const double cardinalLabelSize = 18.0;
  
  /// Font size for digital COG display
  static const double cogDisplaySize = 24.0;
  
  // ============================================
  // ANIMATION SETTINGS
  // ============================================
  
  /// Duration for smooth compass transitions (ms)
  static const int compassAnimationDuration = 100;
  
  /// FPS for normal mode
  static const int normalModeFPS = 60;
  
  /// FPS when battery < 50%
  static const int mediumBatteryFPS = 30;
  
  /// FPS when battery < 20%
  static const int lowBatteryFPS = 15;
  
  // ============================================
  // MAP SETTINGS
  // ============================================
  
  /// OpenStreetMap tile URL
  static const String osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  
  /// Default map zoom level
  static const double defaultMapZoom = 15.0;
  
  /// Width of GPX track line on map (px)
  static const double trackLineWidth = 4.0;
  
  /// Default track color (orange)
  static const Color defaultTrackColor = Color(0xFFFF5722);
  
  /// Color for "Ida" (forward) direction
  static const Color forwardTrackColor = Color(0xFF00FF00);
  
  /// Color for "Volta" (reverse) direction
  static const Color reverseTrackColor = Color(0xFFFF9800);
  
  // ============================================
  // HELPER METHODS
  // ============================================
  
  /// Get correction color based on heading error (degrees)
  static Color getCorrectionColor(double headingError) {
    final absError = headingError.abs();
    if (absError < 3) return success;
    if (absError < 15) return warning;
    return danger;
  }
  
  /// Get buffer status color
  static Color getBufferStatusColor(double distance, double bufferRadius) {
    if (distance.abs() < bufferRadius * bufferCenterRatio) {
      return success; // Center (green)
    } else if (distance.abs() < bufferRadius) {
      return warning; // Near edge (yellow)
    } else {
      return danger; // Outside (red)
    }
  }
  
  /// Format heading to 3 digits with leading zeros (e.g., "045°")
  static String formatHeading(double heading) {
    final rounded = heading.round() % 360;
    return '${rounded.toString().padLeft(3, '0')}°';
  }
  
  /// Get cardinal direction from heading
  static String getCardinal(double heading) {
    final normalized = heading % 360;
    if (normalized >= 337.5 || normalized < 22.5) return 'N';
    if (normalized >= 22.5 && normalized < 67.5) return 'NE';
    if (normalized >= 67.5 && normalized < 112.5) return 'E';
    if (normalized >= 112.5 && normalized < 157.5) return 'SE';
    if (normalized >= 157.5 && normalized < 202.5) return 'S';
    if (normalized >= 202.5 && normalized < 247.5) return 'SW';
    if (normalized >= 247.5 && normalized < 292.5) return 'W';
    if (normalized >= 292.5 && normalized < 337.5) return 'NW';
    return 'N';
  }
  
  /// Normalize angle to -180 to +180 range
  static double normalizeAngle(double angle) {
    double normalized = angle % 360;
    if (normalized > 180) normalized -= 360;
    if (normalized < -180) normalized += 360;
    return normalized;
  }
}