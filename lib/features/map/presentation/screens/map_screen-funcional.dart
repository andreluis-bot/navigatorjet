import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';

// Imports do Projeto
import '../../../../core/config/app_config.dart';
import '../../../../data/models/route.dart' as app_route;
import '../../../../data/services/compass_service.dart';
import '../../../../data/services/gps_service.dart';
import '../../../gpx/import/gpx_parser.dart';
import '../../../navigation/logic/navigation_engine.dart';

// ============================================
// CONFIGURAÇÃO DE TEMAS E ESTILOS
// ============================================

enum UITheme { tactical, aviation, maritime }

class ThemeConfig {
  final Color primary;
  final Color secondary;
  final Color danger;
  final Color warning;
  final Color background;
  final Color panel;
  final String fontFamily;

  const ThemeConfig({
    required this.primary,
    required this.secondary,
    required this.danger,
    required this.warning,
    required this.background,
    required this.panel,
    required this.fontFamily,
  });

  // Tema Tático (Padrão - Neon Green/Black)
  static const tactical = ThemeConfig(
    primary: Color(0xFF00FF41), // Verde Matrix
    secondary: Color(0xFF00E5FF), // Ciano
    danger: Color(0xFFFF2B2B),
    warning: Color(0xFFFF9100),
    background: Color(0xFF000000),
    panel: Color(0xCC111111),
    fontFamily: 'RobotoMono',
  );

  // Tema Aviação (Amber/Dark Grey)
  static const aviation = ThemeConfig(
    primary: Color(0xFFFFB300), // Amber
    secondary: Color(0xFF64FFDA),
    danger: Color(0xFFFF5252),
    warning: Color(0xFFFFD740),
    background: Color(0xFF121212),
    panel: Color(0xCC1E1E1E),
    fontFamily: 'monospace',
  );

  // Tema Marítimo (Red/Night Mode)
  static const maritime = ThemeConfig(
    primary: Color(0xFFFF3333), // Vermelho Noturno
    secondary: Color(0xFFD32F2F),
    danger: Color(0xFFFF8A80),
    warning: Color(0xFFFF6E40),
    background: Color(0xFF050505),
    panel: Color(0xCC000000),
    fontFamily: 'sans-serif',
  );
}

enum MapStyle { dark, satellite, light, terrain }
enum NavigationMode { northUp, courseUp }

// ============================================
// TELA PRINCIPAL
// ============================================

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> with TickerProviderStateMixin {
  // Controladores e Serviços
  final MapController _mapController = MapController();
  final GPXParser _gpxParser = GPXParser();
  final Logger _logger = Logger();

  // Estado Local de Navegação
  double _smoothHeading = 0.0;
  double _smoothSpeed = 0.0;
  MapStyle _currentMapStyle = MapStyle.dark;
  NavigationMode _navMode = NavigationMode.courseUp;
  UITheme _currentThemeType = UITheme.tactical;
  bool _hasCalibrated = false;

  // Estado de Interação com Rota (Etiquetas)
  LatLng? _selectedSegmentPoint;
  String? _segmentLabelForward;
  String? _segmentLabelReverse;

  @override
  void initState() {
    super.initState();
    // Garante que a inicialização ocorra após o primeiro frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionsAndStartSensors();
    });
  }

  // Inicialização Robusta dos Sensores
  Future<void> _checkPermissionsAndStartSensors() async {
    _logger.i("Iniciando sensores...");
    
    // Força o Riverpod a instanciar e começar a escutar os streams
    ref.read(currentHeadingProvider);
    ref.read(currentPositionProvider);

    // Verificação de Permissões
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) _showSnack("Permissão de GPS negada permanentemente.", _theme, isError: true);
      return;
    }

    // "Acorda" o hardware de GPS com uma solicitação única de alta precisão
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      try {
        await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (e) {
        _logger.w("Timeout ao acordar GPS: $e");
        // Não faz mal, o stream do Riverpod continuará tentando
      }
    }
  }

  // Getter para o tema atual
  ThemeConfig get _theme {
    switch (_currentThemeType) {
      case UITheme.aviation: return ThemeConfig.aviation;
      case UITheme.maritime: return ThemeConfig.maritime;
      case UITheme.tactical:
      default: return ThemeConfig.tactical;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuta Reativa dos Providers
    final compassAsync = ref.watch(currentHeadingProvider);
    final gpsAsync = ref.watch(currentPositionProvider);
    final navigationState = ref.watch(navigationEngineProvider);

    // Processamento de Dados com Fallback
    final double rawHeading = compassAsync.value ?? _smoothHeading;
    final double rawSpeed = (gpsAsync.value?.speed ?? 0.0) * 3.6; // m/s para km/h

    // Suavização (Lerp) para animações fluidas
    _smoothHeading = _lerpHeading(_smoothHeading, rawHeading, 0.15);
    _smoothSpeed = _lerpDouble(_smoothSpeed, rawSpeed, 0.1);

    // Posição Atual (Se nula, usa uma padrão mas mantém UI funcional)
    final LatLng currentPos = gpsAsync.value != null
        ? LatLng(gpsAsync.value!.latitude, gpsAsync.value!.longitude)
        : const LatLng(-23.5505, -46.6333);

    // Lógica de Rotação do Mapa
    // CourseUp: Mapa gira (-heading) para manter proa para cima.
    // NorthUp: Mapa fixo (0), ícone gira.
    final double mapRotation = _navMode == NavigationMode.courseUp ? -_smoothHeading : 0.0;
    
    final theme = _theme;

    return Scaffold(
      backgroundColor: theme.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. CAMADA DE MAPA
          _buildFlutterMap(currentPos, navigationState, mapRotation, theme),

          // 2. VIGNETTE (Melhora contraste)
          if (_currentMapStyle != MapStyle.light) _buildVignetteOverlay(),

          // 3. HUD SUPERIOR (Bússola)
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              bottom: false,
              child: _buildAvionicsCompass(_smoothHeading, theme),
            ),
          ),

          // 4. PAINEL INFERIOR (Dashboard)
          Positioned(
            bottom: 30, left: 16, right: 16,
            child: SafeArea(
              top: false,
              child: _buildTacticalDashboard(_smoothSpeed, navigationState, gpsAsync, theme),
            ),
          ),

          // 5. CONTROLES LATERAIS ESQUERDOS
          Positioned(
            left: 16,
            top: MediaQuery.of(context).padding.top + 130,
            child: Column(
              children: [
                _buildCircleButton(Icons.layers, () => _showMapStyleSelector(context, theme), theme),
                const SizedBox(height: 12),
                _buildCircleButton(Icons.folder_open, _handleGpxImport, theme),
                const SizedBox(height: 12),
                _buildCircleButton(Icons.settings_input_antenna, () => _showCalibrationDialog(theme), theme),
              ],
            ),
          ),

          // 6. CONTROLES LATERAIS DIREITOS (Zoom/Navegação)
          Positioned(
            right: 16,
            bottom: 180,
            child: Column(
              children: [
                _buildMiniButton(Icons.add, () {
                  final currZoom = _mapController.camera.zoom;
                  _mapController.move(_mapController.camera.center, currZoom + 1);
                }, theme),
                const SizedBox(height: 8),
                _buildMiniButton(Icons.remove, () {
                  final currZoom = _mapController.camera.zoom;
                  _mapController.move(_mapController.camera.center, currZoom - 1);
                }, theme),
                const SizedBox(height: 20),
                _buildCircleButton(Icons.my_location, () {
                  // Força refresh e centraliza
                  ref.refresh(currentPositionProvider);
                  _mapController.move(currentPos, 16);
                }, theme),
                const SizedBox(height: 12),
                _buildCircleButton(
                  _navMode == NavigationMode.northUp ? Icons.explore : Icons.navigation,
                  _toggleNavigationMode,
                  theme, // Passando o tema corretamente
                  active: _navMode == NavigationMode.courseUp,
                ),
              ],
            ),
          ),

          // 7. STATUS SUPERIOR (GPS e Direção)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: _buildDjiGpsStatus(gpsAsync, theme),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: _buildDirectionStatus(_smoothHeading, theme),
          ),
        ],
      ),
    );
  }

  // ============================================
  // WIDGETS DE MAPA
  // ============================================

  Widget _buildFlutterMap(LatLng center, NavigationData navState, double rotation, ThemeConfig theme) {
    String urlTemplate;
    // Seleção de Fontes de Mapa de Alta Qualidade
    switch (_currentMapStyle) {
      case MapStyle.satellite:
        // Esri World Imagery
        urlTemplate = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
        break;
      case MapStyle.terrain:
        // Google Terrain
        urlTemplate = 'https://mt0.google.com/vt/lyrs=p&x={x}&y={y}&z={z}';
        break;
      case MapStyle.light:
        // CartoDB Positron
        urlTemplate = 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
        break;
      case MapStyle.dark:
      default:
        // CartoDB Dark Matter
        urlTemplate = 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
        break;
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 16.0,
        initialRotation: rotation,
        backgroundColor: theme.background,
        onTap: (tapPos, point) => _handleMapTap(point, navState),
        interactionOptions: InteractionOptions(
          // No modo CourseUp, travamos a rotação manual para não conflitar com a bússola automática
          flags: _navMode == NavigationMode.courseUp
              ? InteractiveFlag.all & ~InteractiveFlag.rotate
              : InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: urlTemplate,
          subdomains: _currentMapStyle == MapStyle.terrain ? const [] : const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.navigatorjet.app',
          retinaMode: true, // Alta Resolução
        ),

        // Camada de Rota Ativa
        if (navState.activeRoute != null)
          PolylineLayer(
            key: UniqueKey(), // Garante rebuild ao inverter rota
            polylines: [
              Polyline(
                points: navState.activeRoute!.points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
                strokeWidth: 5.0,
                color: _currentMapStyle == MapStyle.light ? Colors.blue[900]! : theme.secondary.withOpacity(0.8),
                pattern: const StrokePattern.dotted(),
              ),
            ],
          ),

        // Marcador de Segmento (Etiqueta Interativa)
        if (_selectedSegmentPoint != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _selectedSegmentPoint!,
                width: 200,
                height: 90,
                child: _buildSegmentLabel(theme),
                alignment: Alignment.topCenter,
              ),
            ],
          ),

        // Marcador da Embarcação
        MarkerLayer(
          markers: [
            Marker(
              point: center,
              width: 80,
              height: 80,
              child: _buildNavigationMarker(rotation, theme),
            ),
          ],
        ),
      ],
    );
  }

  // Etiqueta de Rumo (Popup da Rota)
  Widget _buildSegmentLabel(ThemeConfig theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.panel.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.primary, width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)],
          ),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_upward, color: theme.primary, size: 14),
                  const SizedBox(width: 4),
                  Text("IDA: $_segmentLabelForward", style: TextStyle(color: theme.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_downward, color: theme.danger, size: 14),
                  const SizedBox(width: 4),
                  Text("VOLTA: $_segmentLabelReverse", style: TextStyle(color: theme.danger, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        ClipPath(
          clipper: TriangleClipper(),
          child: Container(
            width: 12,
            height: 8,
            color: theme.primary,
          ),
        ),
      ],
    );
  }

  // Ícone de Navegação (Seta)
  Widget _buildNavigationMarker(double mapRotation, ThemeConfig theme) {
    // Se CourseUp: Seta fixa para cima (0).
    // Se NorthUp: Seta gira com o heading.
    double iconRotation = _navMode == NavigationMode.courseUp ? 0.0 : (_smoothHeading * (math.pi / 180));

    return Transform.rotate(
      angle: iconRotation,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halo de brilho
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.3),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: theme.primary, blurRadius: 10, spreadRadius: 2)]
            ),
          ),
          Icon(Icons.navigation, color: theme.primary, size: 48),
        ],
      ),
    );
  }

  // ============================================
  // HUD E DASHBOARD
  // ============================================

  Widget _buildAvionicsCompass(double heading, ThemeConfig theme) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.background.withOpacity(0.9), Colors.transparent],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            "${heading.toStringAsFixed(0)}°",
            style: TextStyle(
              color: theme.primary,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              fontFamily: theme.fontFamily,
              shadows: [Shadow(color: theme.primary, blurRadius: 8)],
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                CustomPaint(
                  painter: TacticalCompassPainter(heading: heading, color: Colors.white, accent: theme.danger),
                  size: const Size(double.infinity, 40),
                ),
                Icon(Icons.arrow_drop_up, color: theme.danger, size: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTacticalDashboard(double speed, NavigationData navState, AsyncValue gpsAsync, ThemeConfig theme) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.panel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24, width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // VELOCIDADE
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("VELOCIDADE", style: TextStyle(color: Colors.grey, fontSize: 10)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(speed.toStringAsFixed(0), style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.bold)),
                      Text(" km/h", style: TextStyle(color: theme.primary, fontSize: 14)),
                    ],
                  ),
                ],
              ),
              Container(width: 1, height: 40, color: Colors.white12),
              
              // RUMO E DISTÂNCIA
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInfoRow("RUMO", "${gpsAsync.value?.heading?.toStringAsFixed(0) ?? '000'}°", theme),
                  const SizedBox(height: 4),
                  _buildInfoRow("DIST", navState.distanceToTarget != null ? "${(navState.distanceToTarget! / 1000).toStringAsFixed(1)}km" : "--", theme),
                ],
              ),
              
              // BOTÃO VOLTA
              InkWell(
                onTap: () {
                  ref.read(navigationEngineProvider.notifier).toggleRouteDirection();
                  _showSnack("Rota Invertida", theme);
                  setState(() {}); // Rebuild para atualizar a linha
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: theme.danger.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: theme.danger)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.swap_vert, color: theme.danger, size: 20), Text("VOLTA", style: TextStyle(color: theme.danger, fontSize: 10, fontWeight: FontWeight.bold))]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // STATUS E CONTROLES
  // ============================================

  Widget _buildDjiGpsStatus(AsyncValue gpsAsync, ThemeConfig theme) {
    double accuracy = 999;
    if (gpsAsync.hasValue && gpsAsync.value != null) {
      accuracy = gpsAsync.value!.accuracy;
    }

    Color signalColor;
    String label;
    int bars;

    if (!gpsAsync.hasValue || gpsAsync.value == null) {
      signalColor = theme.danger;
      label = "N/A";
      bars = 0;
    } else if (accuracy <= 5) {
      signalColor = theme.primary;
      label = "GPS 3D";
      bars = 4;
    } else if (accuracy <= 10) {
      signalColor = theme.primary;
      label = "READY";
      bars = 3;
    } else if (accuracy <= 20) {
      signalColor = theme.warning;
      label = "WEAK";
      bars = 2;
    } else {
      signalColor = theme.danger;
      label = "POOR";
      bars = 1;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: signalColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(4, (index) => Container(
              width: 3,
              height: 6.0 + (index * 3),
              margin: const EdgeInsets.only(right: 2),
              color: index < bars ? signalColor : Colors.grey.withOpacity(0.3),
            )),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: signalColor, fontSize: 10, fontWeight: FontWeight.w900)),
              Text("±${accuracy.toStringAsFixed(0)}m", style: const TextStyle(color: Colors.white, fontSize: 9)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDirectionStatus(double heading, ThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        "DIREÇÃO ${heading.toStringAsFixed(0)}°",
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ============================================
  // HELPERS E LÓGICA DE NEGÓCIO
  // ============================================

  void _toggleNavigationMode() {
    setState(() {
      if (_navMode == NavigationMode.northUp) {
        _navMode = NavigationMode.courseUp;
        _showSnack("Modo Proa (Livre)", _theme);
      } else {
        _navMode = NavigationMode.northUp;
        _mapController.rotate(0);
        _showSnack("Modo Norte (Fixo)", _theme);
      }
    });
  }

  Future<void> _handleGpxImport() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null) {
        final File file = File(result.files.single.path!);
        
        // Chamada correta para o parser existente no projeto
        final app_route.Route? route = await _gpxParser.parseGPXFile(file);
        
        if (route != null) {
          ref.read(navigationEngineProvider.notifier).startNavigation(route);
          if (route.points.isNotEmpty) {
            _mapController.move(LatLng(route.points.first.latitude, route.points.first.longitude), 16);
          }
          _showSnack("Rota carregada: ${route.name}", _theme);
        } else {
          _showSnack("Erro: Ficheiro GPX inválido ou vazio", _theme, isError: true);
        }
      }
    } catch (e) {
      _logger.e("GPX Error: $e");
      _showSnack("Erro ao importar GPX: ${e.toString()}", _theme, isError: true);
    }
  }

  // Detecta clique na linha para mostrar etiquetas
  void _handleMapTap(LatLng point, NavigationData navState) {
    if (navState.activeRoute == null) return;
    
    setState(() {
      _selectedSegmentPoint = null;
      _segmentLabelForward = null;
      _segmentLabelReverse = null;
    });

    double minDistance = double.infinity;
    int closestIndex = -1;
    const Distance distanceCalc = Distance();

    final points = navState.activeRoute!.points;
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = LatLng(points[i].latitude, points[i].longitude);
      final p2 = LatLng(points[i+1].latitude, points[i+1].longitude);
      
      final center = LatLng((p1.latitude + p2.latitude)/2, (p1.longitude + p2.longitude)/2);
      final dist = distanceCalc.as(LengthUnit.Meter, point, center);
      
      // Raio de detecção de 500m (ajustável para escala)
      if (dist < 500 && dist < minDistance) {
        minDistance = dist;
        closestIndex = i;
      }
    }

    if (closestIndex != -1) {
      final p1 = points[closestIndex];
      final p2 = points[closestIndex+1];
      
      final bearingForward = distanceCalc.bearing(LatLng(p1.latitude, p1.longitude), LatLng(p2.latitude, p2.longitude));
      
      double fwd = (bearingForward + 360) % 360;
      double rev = (fwd + 180) % 360;

      setState(() {
        _selectedSegmentPoint = point;
        _segmentLabelForward = "${fwd.toStringAsFixed(0)}°";
        _segmentLabelReverse = "${rev.toStringAsFixed(0)}°";
      });
    }
  }

  // Menu de Estilos
  void _showMapStyleSelector(BuildContext context, ThemeConfig theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: theme.panel,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("ESTILO DE MAPA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _mapStyleOption(Icons.nightlight_round, "Tático", MapStyle.dark, theme),
                      _mapStyleOption(Icons.satellite_alt, "Satélite", MapStyle.satellite, theme),
                      _mapStyleOption(Icons.landscape, "Relevo", MapStyle.terrain, theme),
                      _mapStyleOption(Icons.wb_sunny, "Claro", MapStyle.light, theme),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCalibrationDialog(ThemeConfig theme) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.panel,
        title: Row(children: [Icon(Icons.settings_input_antenna, color: theme.primary), const SizedBox(width: 10), const Text("Calibração", style: TextStyle(color: Colors.white))]),
        content: const Text("Mova o dispositivo em '8' para calibrar.", style: TextStyle(color: Colors.white70)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK", style: TextStyle(color: theme.primary)))],
      ),
    );
  }

  void _showSnack(String msg, ThemeConfig theme, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? theme.danger : theme.primary,
      duration: const Duration(seconds: 1),
    ));
  }

  // Componentes Menores Reutilizáveis
  Widget _mapStyleOption(IconData icon, String label, MapStyle style, ThemeConfig theme) {
    bool isSelected = _currentMapStyle == style;
    return GestureDetector(
      onTap: () {
        setState(() => _currentMapStyle = style);
        Navigator.pop(context);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? theme.primary : Colors.white10,
              shape: BoxShape.circle,
              boxShadow: isSelected ? [BoxShadow(color: theme.primary, blurRadius: 10)] : [],
            ),
            child: Icon(icon, color: isSelected ? Colors.black : Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: isSelected ? theme.primary : Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap, ThemeConfig theme, {bool active = false}) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: active ? theme.primary : theme.panel,
        shape: BoxShape.circle,
        border: Border.all(color: active ? theme.primary : Colors.white24),
      ),
      child: IconButton(icon: Icon(icon, color: active ? Colors.black : Colors.white, size: 20), onPressed: onTap),
    );
  }

  Widget _buildMiniButton(IconData icon, VoidCallback onTap, ThemeConfig theme) {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: theme.panel.withOpacity(0.6), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)),
      child: IconButton(padding: EdgeInsets.zero, icon: Icon(icon, color: Colors.white, size: 18), onPressed: onTap),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeConfig theme) {
    return Row(children: [Text("$label ", style: const TextStyle(color: Colors.grey, fontSize: 10)), Text(value, style: TextStyle(color: theme.secondary, fontSize: 12, fontWeight: FontWeight.bold))]);
  }

  Widget _buildVignetteOverlay() {
    return IgnorePointer(child: Container(decoration: BoxDecoration(gradient: RadialGradient(colors: [Colors.transparent, Colors.black.withOpacity(0.5)], radius: 1.2, stops: const [0.7, 1.0]))));
  }

  double _lerpHeading(double a, double b, double t) {
    double diff = b - a;
    if (diff > 180) diff -= 360; if (diff < -180) diff += 360;
    return a + diff * t;
  }
  double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

// ============================================
// PAINTERS E CLIPPERS
// ============================================

class TacticalCompassPainter extends CustomPainter {
  final double heading;
  final Color color;
  final Color accent;

  TacticalCompassPainter({required this.heading, required this.color, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke;
    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr, textAlign: TextAlign.center);

    double pixelPerDegree = size.width / 100; double centerX = size.width / 2;

    for (int i = (heading - 50).floor(); i <= (heading + 50).ceil(); i++) {
      int deg = i % 360; if (deg < 0) deg += 360;
      double x = centerX + (i - heading) * pixelPerDegree;
      double opacity = (1.0 - ((x - centerX).abs() / (size.width / 2))).clamp(0.0, 1.0);
      paint.color = color.withOpacity(opacity);

      if (deg % 90 == 0) {
        String label = deg == 0 ? "N" : deg == 90 ? "E" : deg == 180 ? "S" : "W";
        tp.text = TextSpan(text: label, style: TextStyle(color: label == "N" ? accent.withOpacity(opacity) : color.withOpacity(opacity), fontSize: 20, fontWeight: FontWeight.bold));
        tp.layout(); tp.paint(canvas, Offset(x - tp.width / 2, 0));
        paint.strokeWidth = 3; canvas.drawLine(Offset(x, 25), Offset(x, 40), paint);
      } else if (deg % 10 == 0) {
        tp.text = TextSpan(text: "${deg ~/ 10}", style: TextStyle(color: color.withOpacity(opacity), fontSize: 12));
        tp.layout(); tp.paint(canvas, Offset(x - tp.width / 2, 8));
        paint.strokeWidth = 1.5; canvas.drawLine(Offset(x, 30), Offset(x, 40), paint);
      } else if (deg % 5 == 0) {
         paint.strokeWidth = 1; canvas.drawLine(Offset(x, 35), Offset(x, 40), paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant TacticalCompassPainter oldDelegate) => (oldDelegate.heading - heading).abs() > 0.1;
}

class TriangleClipper extends CustomClipper<ui.Path> {
  @override
  ui.Path getClip(Size size) {
    final path = ui.Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(TriangleClipper oldClipper) => false;
}