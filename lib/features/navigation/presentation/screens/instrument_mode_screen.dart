import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../data/services/compass_service.dart';
import '../../../../data/services/gps_service.dart';
import '../../logic/navigation_engine.dart';

/// Instrument Mode Screen - Fallback navigation without map
/// HIGH CONTRAST design for sunlight readability
/// Functions when map is unavailable or battery is critical
class InstrumentModeScreen extends ConsumerStatefulWidget {
  const InstrumentModeScreen({super.key});

  @override
  ConsumerState<InstrumentModeScreen> createState() => _InstrumentModeScreenState();
}

class _InstrumentModeScreenState extends ConsumerState<InstrumentModeScreen> {
  DateTime? _navigationStartTime;
  
  @override
  void initState() {
    super.initState();
    _navigationStartTime = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final navigationData = ref.watch(navigationEngineProvider);
    final currentPosition = ref.watch(currentPositionProvider);
    
    // CORREÇÃO: Acessando .value do AsyncValue e garantindo double
    final double currentHeading = ref.watch(currentHeadingProvider).value ?? 0.0;
    
    final gpsService = ref.read(gpsServiceProvider);
    
    final speed = gpsService.currentSpeed ?? 0.0;
    final elapsed = _navigationStartTime != null
        ? DateTime.now().difference(_navigationStartTime!)
        : Duration.zero;
    
    return Scaffold(
      backgroundColor: AppConfig.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Column(
              children: [
                // Header
                _buildHeader(),
                
                // Large compass
                Expanded(
                  child: Center(
                    child: _buildLargeCompass(
                      currentHeading, // Agora é double seguro
                      navigationData.targetHeading,
                      navigationData.headingError,
                    ),
                  ),
                ),
                
                // Digital speedometer
                _buildSpeedometer(speed),
                
                const SizedBox(height: 16),
                
                // Navigation metrics
                if (navigationData.state == NavigationState.navigating)
                  _buildNavigationMetrics(navigationData),
                
                const SizedBox(height: 16),
                
                // Chronometer
                _buildChronometer(elapsed),
                
                const SizedBox(height: 16),
                
                // GPS coordinates
                if (currentPosition.value != null)
                  _buildCoordinates(currentPosition.value!),
                
                const SizedBox(height: 24),
              ],
            ),
            
            // Back to map button
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () => context.go('/map'),
                icon: const Icon(
                  Icons.map,
                  color: AppConfig.success,
                  size: 32,
                ),
                tooltip: 'Voltar ao Mapa',
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build header with mode indicator
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(
            Icons.speed,
            color: AppConfig.warning,
            size: 32,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MODO INSTRUMENTOS',
                  style: TextStyle(
                    color: AppConfig.warning,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Navegação por rumo',
                  style: TextStyle(
                    color: AppConfig.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build large compass widget
  Widget _buildLargeCompass(
    double currentHeading,
    double? targetHeading,
    double? headingError,
  ) {
    return SizedBox(
      width: AppConfig.instrumentCompassSize,
      height: AppConfig.instrumentCompassSize,
      child: CustomPaint(
        painter: _LargeCompassPainter(
          currentHeading: currentHeading,
          targetHeading: targetHeading,
          headingError: headingError,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Digital COG display
            Text(
              AppConfig.formatHeading(currentHeading),
              style: const TextStyle(
                color: AppConfig.textPrimary,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            
            // Cardinal direction
            Text(
              AppConfig.getCardinal(currentHeading),
              style: const TextStyle(
                color: AppConfig.success,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Heading error (correction indicator)
            if (targetHeading != null && headingError != null)
              _buildCorrectionIndicator(headingError),
          ],
        ),
      ),
    );
  }

  /// Build correction indicator
  Widget _buildCorrectionIndicator(double? headingError) {
    // CORREÇÃO: Tratamento de nulo
    if (headingError == null) return const SizedBox.shrink();

    final absError = headingError.abs();
    final color = AppConfig.getCorrectionColor(headingError);
    
    String arrow;
    String text;
    
    if (absError < 3) {
      arrow = '✓';
      text = 'NO CENTRO';
    } else if (headingError < 0) {
      arrow = '⬅️';
      text = 'CORRIGIR ${absError.toStringAsFixed(0)}°';
    } else {
      arrow = '➡️';
      text = 'CORRIGIR ${absError.toStringAsFixed(0)}°';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            arrow,
            style: TextStyle(
              color: color,
              fontSize: 32,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  /// Build speedometer
  Widget _buildSpeedometer(double speed) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'VELOCIDADE',
            style: TextStyle(
              color: AppConfig.success,
              fontSize: 14,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            speed.toStringAsFixed(1),
            style: const TextStyle(
              color: AppConfig.success,
              fontSize: 64,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          const Text(
            'km/h',
            style: TextStyle(
              color: AppConfig.success,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  /// Build navigation metrics
  Widget _buildNavigationMetrics(NavigationData navigationData) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppConfig.compassTarget, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Target heading
          if (navigationData.targetHeading != null)
            _buildMetricColumn(
              'RUMO ALVO',
              AppConfig.formatHeading(navigationData.targetHeading!),
              AppConfig.compassTarget,
            ),
          
          // Distance to target
          if (navigationData.distanceToTarget != null)
            _buildMetricColumn(
              'DISTÂNCIA',
              navigationData.distanceToTarget! < 1000
                  ? '${navigationData.distanceToTarget!.toStringAsFixed(0)} m'
                  : '${(navigationData.distanceToTarget! / 1000).toStringAsFixed(2)} km',
              AppConfig.textPrimary,
            ),
          
          // Waypoint progress
          if (navigationData.activeRoute != null)
            _buildMetricColumn(
              'WAYPOINT',
              '${navigationData.currentWaypointIndex + 1}/${navigationData.activeRoute!.waypointCount}',
              AppConfig.warning,
            ),
        ],
      ),
    );
  }

  /// Build metric column
  Widget _buildMetricColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.7),
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  /// Build chronometer
  Widget _buildChronometer(Duration elapsed) {
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    final seconds = elapsed.inSeconds.remainder(60);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timer, color: AppConfig.compassNeedle),
          const SizedBox(width: 12),
          Text(
            '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: AppConfig.compassNeedle,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  /// Build GPS coordinates display
  Widget _buildCoordinates(position) {
    final lat = position.latitude.toStringAsFixed(6);
    final lng = position.longitude.toStringAsFixed(6);
    final latDir = position.latitude >= 0 ? 'N' : 'S';
    final lngDir = position.longitude >= 0 ? 'E' : 'W';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const Text(
            'COORDENADAS GPS',
            style: TextStyle(
              color: AppConfig.textPrimary,
              fontSize: 12,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$lat° $latDir  $lng° $lngDir',
            style: const TextStyle(
              color: AppConfig.textPrimary,
              fontSize: 16,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Precisão: ${position.accuracy.toStringAsFixed(0)} m',
            style: TextStyle(
              color: position.accuracy < 20
                  ? AppConfig.success
                  : AppConfig.warning,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for large compass
class _LargeCompassPainter extends CustomPainter {
  final double currentHeading;
  final double? targetHeading;
  final double? headingError;
  
  _LargeCompassPainter({
    required this.currentHeading,
    this.targetHeading,
    this.headingError,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    
    // Draw outer circle
    final outerPaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, outerPaint);
    
    // Draw cardinal directions
    _drawCardinals(canvas, center, radius);
    
    // Draw degree marks
    _drawDegreeMarks(canvas, center, radius);
    
    // Draw current heading needle (cyan)
    _drawNeedle(
      canvas,
      center,
      radius * 0.9,
      0, // Always points up (north in instrument view)
      AppConfig.compassNeedle,
      width: 4,
    );
    
    // Draw target heading indicator (magenta)
    if (targetHeading != null && headingError != null) {
      _drawNeedle(
        canvas,
        center,
        radius * 0.7,
        headingError!, 
        AppConfig.compassTarget,
        width: 3,
      );
    }
  }

  /// Draw cardinal directions (N/S/E/W)
  void _drawCardinals(Canvas canvas, Offset center, double radius) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final cardinals = ['N', 'E', 'S', 'W'];
    final angles = [0, 90, 180, 270];
    
    for (int i = 0; i < 4; i++) {
      final angle = (angles[i] - currentHeading) * math.pi / 180;
      final x = center.dx + radius * 0.85 * math.sin(angle);
      final y = center.dy - radius * 0.85 * math.cos(angle);
      
      textPainter.text = TextSpan(
        text: cardinals[i],
        style: const TextStyle(
          color: AppConfig.cardinalColor,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  /// Draw degree marks around compass
  void _drawDegreeMarks(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5;
    
    for (int i = 0; i < 360; i += 10) {
      final angle = (i - currentHeading) * math.pi / 180;
      final innerRadius = i % 30 == 0 ? radius * 0.85 : radius * 0.9;
      
      final x1 = center.dx + innerRadius * math.sin(angle);
      final y1 = center.dy - innerRadius * math.cos(angle);
      final x2 = center.dx + radius * math.sin(angle);
      final y2 = center.dy - radius * math.cos(angle);
      
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  /// Draw heading needle
  void _drawNeedle(
    Canvas canvas,
    Offset center,
    double length,
    double angleDegrees,
    Color color, {
    double width = 3,
  }) {
    final angle = angleDegrees * math.pi / 180;
    final endX = center.dx + length * math.sin(angle);
    final endY = center.dy - length * math.cos(angle);
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    
    // Draw shadow
    final shadowPaint = Paint()
      ..color = Colors.black54
      ..strokeWidth = width + 2
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    
    canvas.drawLine(center, Offset(endX, endY), shadowPaint);
    canvas.drawLine(center, Offset(endX, endY), paint);
    
    // Draw arrowhead
    final arrowSize = 15.0;
    final arrowAngle = 25 * math.pi / 180;
    
    final leftX = endX - arrowSize * math.sin(angle - arrowAngle);
    final leftY = endY + arrowSize * math.cos(angle - arrowAngle);
    final rightX = endX - arrowSize * math.sin(angle + arrowAngle);
    final rightY = endY + arrowSize * math.cos(angle + arrowAngle);
    
    final arrowPath = Path()
      ..moveTo(endX, endY)
      ..lineTo(leftX, leftY)
      ..lineTo(rightX, rightY)
      ..close();
    
    canvas.drawPath(arrowPath, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_LargeCompassPainter oldDelegate) {
    return oldDelegate.currentHeading != currentHeading ||
        oldDelegate.targetHeading != targetHeading;
  }
}