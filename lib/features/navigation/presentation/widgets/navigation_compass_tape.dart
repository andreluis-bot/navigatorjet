import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../../core/config/app_config.dart';

/// Navigation Compass Tape - Linear sliding compass ruler (aviation style)
/// CORRIGIDO: Agora atualiza em tempo real com o stream de heading
class NavigationCompassTape extends StatefulWidget {
  final double currentHeading; // 0-360°
  final double? targetHeading; // 0-360° (bearing to next waypoint)
  final bool isForwardDirection; // true = Ida (⬆️), false = Volta (⬇️)
  final VoidCallback? onToggleDirection;
  
  const NavigationCompassTape({
    super.key,
    required this.currentHeading,
    this.targetHeading,
    this.isForwardDirection = true,
    this.onToggleDirection,
  });

  @override
  State<NavigationCompassTape> createState() => _NavigationCompassTapeState();
}

class _NavigationCompassTapeState extends State<NavigationCompassTape> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _headingAnimation;
  double _previousHeading = 0.0;

  @override
  void initState() {
    super.initState();
    _previousHeading = widget.currentHeading;
    
    // Animação suave para transições de heading (evita "saltos")
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    
    _headingAnimation = Tween<double>(
      begin: _previousHeading,
      end: widget.currentHeading,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(NavigationCompassTape oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Detecta mudança de heading e anima
    if (oldWidget.currentHeading != widget.currentHeading) {
      _previousHeading = oldWidget.currentHeading;
      
      _headingAnimation = Tween<double>(
        begin: _previousHeading,
        end: widget.currentHeading,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ));
      
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final headingError = widget.targetHeading != null
        ? AppConfig.normalizeAngle(widget.targetHeading! - widget.currentHeading)
        : 0.0;
    
    final correctionColor = AppConfig.getCorrectionColor(headingError);
    final correctionText = _getCorrectionText(headingError);

    return Container(
      height: AppConfig.compassTapeHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.95),
            Colors.black.withOpacity(0.85),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: correctionColor.withOpacity(0.3),
            width: 2,
          ),
        ),
      ),
      child: Column(
        children: [
          // Top section: COG display, Direction toggle, Target heading
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Current heading (COG)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'COG',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _headingAnimation,
                      builder: (context, child) {
                        return Text(
                          AppConfig.formatHeading(_headingAnimation.value),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                // Direction toggle button (CORRIGIDO: Feedback visual)
                GestureDetector(
                  onTap: widget.onToggleDirection,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.isForwardDirection 
                          ? AppConfig.success.withOpacity(0.2)
                          : AppConfig.warning.withOpacity(0.2),
                      border: Border.all(
                        color: widget.isForwardDirection 
                            ? AppConfig.success 
                            : AppConfig.warning,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.isForwardDirection 
                              ? Icons.arrow_upward 
                              : Icons.arrow_downward,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.isForwardDirection ? 'IDA' : 'VOLTA',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Target heading
                if (widget.targetHeading != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ALVO',
                        style: TextStyle(
                          color: AppConfig.compassTarget.withOpacity(0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        AppConfig.formatHeading(widget.targetHeading!),
                        style: const TextStyle(
                          color: AppConfig.compassTarget,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          
          // Compass tape ruler (CORRIGIDO: Usa AnimatedBuilder)
          Expanded(
            child: Stack(
              children: [
                // Scrolling compass tape
                AnimatedBuilder(
                  animation: _headingAnimation,
                  builder: (context, child) {
                    return _buildCompassTape(_headingAnimation.value);
                  },
                ),
                
                // Center lubber line (fixed) - MELHORADO: Visual mais destacado
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 4,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.red,
                              Color(0xFFFF4444),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      // Triângulo indicador
                      CustomPaint(
                        size: const Size(16, 12),
                        painter: _TrianglePainter(color: Colors.red),
                      ),
                    ],
                  ),
                ),
                
                // Target heading indicator (if available)
                if (widget.targetHeading != null)
                  AnimatedBuilder(
                    animation: _headingAnimation,
                    builder: (context, child) {
                      return _buildTargetIndicator(headingError);
                    },
                  ),
                
                // Correction text below tape
                if (widget.targetHeading != null)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.black.withOpacity(0.9),
                          ],
                        ),
                      ),
                      child: Text(
                        correctionText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: correctionColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build scrolling compass tape
  Widget _buildCompassTape(double animatedHeading) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final centerX = width / 2;
        
        return CustomPaint(
          size: Size(width, constraints.maxHeight),
          painter: _CompassTapePainter(
            currentHeading: animatedHeading,
            centerX: centerX,
          ),
        );
      },
    );
  }

  /// Build target heading indicator
  Widget _buildTargetIndicator(double headingError) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final centerX = width / 2;
        
        // Calculate pixel offset for target indicator
        final pixelOffset = headingError * AppConfig.degreeSpacing;
        final targetX = centerX + pixelOffset;
        
        // Only show if within visible range
        if (targetX < 0 || targetX > width) {
          return const SizedBox.shrink();
        }
        
        return Positioned(
          left: targetX - 2,
          top: 10,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppConfig.compassTarget,
                      Color(0xFFFF00AA),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppConfig.compassTarget.withOpacity(0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              // Triângulo indicador
              CustomPaint(
                size: const Size(12, 8),
                painter: _TrianglePainter(color: AppConfig.compassTarget),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Get correction text (e.g., "⬅️ 5°" or "NO CENTRO")
  String _getCorrectionText(double headingError) {
    final absError = headingError.abs();
    
    if (absError < 3) {
      return '✓ NO CENTRO';
    } else if (headingError < 0) {
      return '⬅️ CORRIGIR ${absError.toStringAsFixed(0)}°';
    } else {
      return 'CORRIGIR ${absError.toStringAsFixed(0)}° ➡️';
    }
  }
}

/// Custom painter for compass tape
class _CompassTapePainter extends CustomPainter {
  final double currentHeading;
  final double centerX;
  
  _CompassTapePainter({
    required this.currentHeading,
    required this.centerX,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5;
    
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    // Draw marks from -180° to +180° relative to current heading
    for (int i = -180; i <= 180; i++) {
      final heading = (currentHeading + i) % 360;
      final x = centerX + (i * AppConfig.degreeSpacing);
      
      // Only draw if within visible range (with margin)
      if (x < -50 || x > size.width + 50) continue;
      
      // Determine tick height
      double tickHeight;
      Color tickColor = Colors.white70;
      
      if (i % 10 == 0) {
        tickHeight = AppConfig.largeTickHeight;
        tickColor = Colors.white;
      } else if (i % 5 == 0) {
        tickHeight = AppConfig.mediumTickHeight;
      } else {
        tickHeight = AppConfig.smallTickHeight;
      }
      
      // Draw tick mark
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, tickHeight),
        paint..color = tickColor,
      );
      
      // Draw degree label every 10°
      if (i % 10 == 0) {
        final label = heading.round().toString().padLeft(3, '0');
        textPainter.text = TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: AppConfig.degreeLabelSize,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w500,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, tickHeight + 4),
        );
      }
      
      // Draw cardinal letters (N/S/E/W) with DESTAQUE VERMELHO
      final normalizedHeading = heading.round();
      if (normalizedHeading == 0 || normalizedHeading == 360) {
        _drawCardinal(canvas, textPainter, x, 'N', isNorth: true);
      } else if (normalizedHeading == 90) {
        _drawCardinal(canvas, textPainter, x, 'E');
      } else if (normalizedHeading == 180) {
        _drawCardinal(canvas, textPainter, x, 'S');
      } else if (normalizedHeading == 270) {
        _drawCardinal(canvas, textPainter, x, 'W');
      }
    }
  }

  /// Draw cardinal letter with highlight (NORTE em VERMELHO)
  void _drawCardinal(
    Canvas canvas, 
    TextPainter textPainter, 
    double x, 
    String letter, {
    bool isNorth = false,
  }) {
    final cardinalColor = isNorth ? Colors.red : AppConfig.cardinalColor;
    
    textPainter.text = TextSpan(
      text: letter,
      style: TextStyle(
        color: cardinalColor,
        fontSize: AppConfig.cardinalLabelSize,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
      ),
    );
    textPainter.layout();
    
    // Draw glow effect (mais intenso para o Norte)
    final glowPaint = Paint()
      ..color = cardinalColor.withOpacity(isNorth ? 0.5 : 0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isNorth ? 12 : 8);
    
    canvas.drawCircle(
      Offset(x, AppConfig.largeTickHeight + textPainter.height / 2 + 6),
      textPainter.width / 2 + (isNorth ? 6 : 4),
      glowPaint,
    );
    
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, AppConfig.largeTickHeight + 4),
    );
  }

  @override
  bool shouldRepaint(_CompassTapePainter oldDelegate) {
    return oldDelegate.currentHeading != currentHeading;
  }
}

/// Painter para triângulos indicadores
class _TrianglePainter extends CustomPainter {
  final Color color;
  
  _TrianglePainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final path = Path()
      ..moveTo(size.width / 2, size.height) // Ponta para baixo
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(_TrianglePainter oldDelegate) => false;
}