import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Tarja de bússola compacta inspirada no Fishing Points
/// 
/// Características:
/// - Sempre visível no topo do mapa
/// - Mostra COG (Course Over Ground) atual
/// - Rumo alvo (da rota GPX)
/// - Correção angular visual
/// - Indicador de Ida/Volta
/// - Economiza espaço (apenas 80px de altura)
class CompactCompassBar extends StatelessWidget {
  /// Course Over Ground (rumo atual do GPS/bússola)
  final double currentHeading;
  
  /// Rumo alvo (bearing para o próximo waypoint do GPX)
  final double targetHeading;
  
  /// Direção da rota: true = Ida, false = Volta
  final bool isForwardRoute;
  
  /// Callback para alternar direção da rota
  final VoidCallback? onToggleDirection;
  
  const CompactCompassBar({
    Key? key,
    required this.currentHeading,
    required this.targetHeading,
    this.isForwardRoute = true,
    this.onToggleDirection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calcula diferença angular (correção necessária)
    final headingError = _calculateHeadingError();
    final correctionText = _getCorrectionText(headingError);
    final correctionColor = _getCorrectionColor(headingError);
    
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.6),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: correctionColor.withOpacity(0.3),
            width: 3,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // COG (Course Over Ground) - Rumo Atual
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'COG',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${currentHeading.toInt()}°',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getCardinalDirection(currentHeading),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Seta de direção (inclinável conforme sensor)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Transform.rotate(
                angle: currentHeading * math.pi / 180,
                child: const Icon(
                  Icons.arrow_upward,
                  color: Color(0xFF00FFFF), // Ciano
                  size: 32,
                ),
              ),
            ),
            
            // Correção Angular
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Rota a navegar',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    correctionText,
                    style: TextStyle(
                      color: correctionColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Rumo Alvo + Toggle Ida/Volta
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Toggle Ida/Volta
                  GestureDetector(
                    onTap: onToggleDirection,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isForwardRoute
                            ? Colors.green.withOpacity(0.3)
                            : Colors.orange.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isForwardRoute ? Colors.green : Colors.orange,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isForwardRoute
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isForwardRoute ? 'Ida' : 'Volta',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Rumo Alvo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${targetHeading.toInt()}°',
                        style: const TextStyle(
                          color: Color(0xFFFF00FF), // Magenta
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getCardinalDirection(targetHeading),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Calcula diferença angular entre rumo atual e alvo
  /// Retorna valor entre -180 e +180
  /// Negativo = virar esquerda, Positivo = virar direita
  double _calculateHeadingError() {
    double error = targetHeading - currentHeading;
    
    // Normalizar para -180 a +180
    if (error > 180) error -= 360;
    if (error < -180) error += 360;
    
    return error;
  }
  
  /// Retorna texto de correção formatado
  String _getCorrectionText(double error) {
    if (error.abs() < 3) {
      return 'NO RUMO'; // Dentro de ±3°
    }
    
    final direction = error < 0 ? '⬅️' : '➡️';
    return '$direction ${error.abs().toInt()}°';
  }
  
  /// Retorna cor baseada na magnitude do erro
  Color _getCorrectionColor(double error) {
    final absError = error.abs();
    
    if (absError < 3) {
      return const Color(0xFF00FF00); // Verde (no rumo)
    } else if (absError < 15) {
      return const Color(0xFFFFFF00); // Amarelo (pequeno desvio)
    } else {
      return const Color(0xFFFF0000); // Vermelho (grande desvio)
    }
  }
  
  /// Converte graus para direção cardinal
  String _getCardinalDirection(double heading) {
    const directions = [
      'N', 'NNE', 'NE', 'ENE',
      'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW',
      'W', 'WNW', 'NW', 'NNW'
    ];
    
    // Cada direção cobre 22.5° (360 / 16)
    final index = ((heading + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }
}

/// Exemplo de uso na NavigationScreen
class NavigationScreenExample extends StatefulWidget {
  const NavigationScreenExample({Key? key}) : super(key: key);

  @override
  State<NavigationScreenExample> createState() => _NavigationScreenExampleState();
}

class _NavigationScreenExampleState extends State<NavigationScreenExample> {
  double currentHeading = 235.0; // Simulado (virá do CompassService)
  double targetHeading = 203.0;  // Simulado (virá do NavigationEngine)
  bool isForwardRoute = true;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mapa (placeholder)
          Container(
            color: Colors.grey[800],
            child: const Center(
              child: Text(
                'MAPA AQUI\n(flutter_map)',
                style: TextStyle(color: Colors.white, fontSize: 24),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // Bússola compacta no topo
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: CompactCompassBar(
                currentHeading: currentHeading,
                targetHeading: targetHeading,
                isForwardRoute: isForwardRoute,
                onToggleDirection: () {
                  setState(() {
                    isForwardRoute = !isForwardRoute;
                    // Inverter rota GPX aqui
                  });
                },
              ),
            ),
          ),
          
          // Métricas na parte inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black.withOpacity(0.7),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    '🚤 42 km/h',
                    style: TextStyle(
                      color: Color(0xFF00FF00),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '📏 18.7 km',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '🔋 45%',
                    style: TextStyle(
                      color: Color(0xFFFFFF00),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Botão de teste (apenas para debug)
          Positioned(
            right: 16,
            bottom: 100,
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  // Simula mudança de rumo
                  currentHeading = (currentHeading + 10) % 360;
                });
              },
              child: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
    );
  }
}
