// ============================================
// 📄 map_screen.dart - PARTE 1/3
// ⚠️  COLE ESTE BLOCO NO INÍCIO DO ARQUIVO
// ============================================

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
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:logger/logger.dart';

import '../../../../core/config/app_config.dart';
import '../../../../data/models/route.dart' as app_route;
import '../../../../data/services/compass_service.dart';
import '../../../../data/services/gps_service.dart';
import '../../../gpx/import/gpx_parser.dart';
import '../../../navigation/logic/navigation_engine.dart';

// ============================================
// DESIGN SYSTEM
// ============================================

const Color kTacticalGreen = Color(0xFF00FF41);
const Color kTacticalCyan = Color(0xFF00E5FF);
const Color kAlertRed = Color(0xFFFF2B2B);
const Color kAlertOrange = Color(0xFFFF9100);
const Color kGlassPanel = Color(0xCC111111);

enum MapStyle { dark, satellite, light, terrain, topo3D }
enum NavigationMode { northUp, courseUp }

// ============================================
// MODELO DE ROTA GPX CARREGADA
// ============================================

class LoadedGPXRoute {
  final String id;
  final String name;
  final app_route.Route route;
  bool isVisible;
  Color color;

  LoadedGPXRoute({
    required this.id,
    required this.name,
    required this.route,
    this.isVisible = true,
    this.color = Colors.orange,
  });
}

// ============================================
// MAIN SCREEN
// ============================================

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final GPXParser _gpxParser = GPXParser();
  final Logger _logger = Logger();

  // Estado Local
  double _smoothHeading = 0.0;
  double _smoothSpeed = 0.0;
  MapStyle _currentMapStyle = MapStyle.dark;
  NavigationMode _navMode = NavigationMode.courseUp;
  bool _hasCalibrated = false;

  // Múltiplas rotas GPX
  List<LoadedGPXRoute> _loadedRoutes = [];
  String? _activeRouteId; // ID da rota sendo navegada

  // Estado para etiqueta de segmento GPX
  LatLng? _selectedSegmentPoint;
  String? _segmentLabelForward;
  String? _segmentLabelReverse;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionsAndStartSensors();
    });
  }

  Future<void> _checkPermissionsAndStartSensors() async {
    ref.read(currentHeadingProvider);
    ref.read(currentPositionProvider);

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
          .then((_) {})
          .catchError((e) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final compassAsync = ref.watch(currentHeadingProvider);
    final gpsAsync = ref.watch(currentPositionProvider);
    final navigationState = ref.watch(navigationEngineProvider);

    final double rawHeading = compassAsync.value ?? _smoothHeading;
    final double rawSpeed = (gpsAsync.value?.speed ?? 0.0) * 3.6;

    _smoothHeading = _lerpHeading(_smoothHeading, rawHeading, 0.15);
    _smoothSpeed = _lerpDouble(_smoothSpeed, rawSpeed, 0.1);

    final LatLng currentPos = gpsAsync.value != null
        ? LatLng(gpsAsync.value!.latitude, gpsAsync.value!.longitude)
        : const LatLng(-23.5505, -46.6333);

    final double mapRotation =
        _navMode == NavigationMode.courseUp ? -_smoothHeading : 0.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. MAPA INTERATIVO
          _buildFlutterMap(currentPos, navigationState, mapRotation),

          // 2. VIGNETTE
          if (_currentMapStyle != MapStyle.light) _buildVignetteOverlay(),

          // 3. HUD SUPERIOR (Bússola)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: _buildAvionicsCompass(_smoothHeading),
            ),
          ),

          // 4. PAINEL INFERIOR (Dashboard)
          Positioned(
            bottom: 30,
            left: 16,
            right: 16,
            child: SafeArea(
              top: false,
              child:
                  _buildTacticalDashboard(_smoothSpeed, navigationState, gpsAsync),
            ),
          ),

          // 5. CONTROLES LATERAIS ESQUERDOS
          Positioned(
            left: 16,
            top: MediaQuery.of(context).padding.top + 130,
            child: Column(
              children: [
                _buildCircleButton(Icons.layers,
                    () => _showMapStyleSelector(context)),
                const SizedBox(height: 12),
                _buildCircleButton(Icons.folder_open, _handleGpxImport),
                const SizedBox(height: 12),
                _buildCircleButton(
                    Icons.route, () => _showRoutesManager(context)),
                const SizedBox(height: 12),
                _buildCircleButton(
                    Icons.settings_input_antenna, _showCalibrationDialog),
              ],
            ),
          ),

          // 6. CONTROLES LATERAIS DIREITOS
          Positioned(
            right: 16,
            bottom: 180,
            child: Column(
              children: [
                _buildMiniButton(Icons.add, () {
                  final currZoom = _mapController.camera.zoom;
                  _mapController.move(
                      _mapController.camera.center, currZoom + 1);
                }),
                const SizedBox(height: 8),
                _buildMiniButton(Icons.remove, () {
                  final currZoom = _mapController.camera.zoom;
                  _mapController.move(
                      _mapController.camera.center, currZoom - 1);
                }),
                const SizedBox(height: 20),
                _buildCircleButton(Icons.my_location, () {
                  ref.refresh(currentPositionProvider);
                  _mapController.move(currentPos, 16);
                }),
                const SizedBox(height: 12),
                _buildCircleButton(
                  _navMode == NavigationMode.northUp
                      ? Icons.explore
                      : Icons.navigation,
                  _toggleNavigationMode,
                  active: _navMode == NavigationMode.courseUp,
                ),
              ],
            ),
          ),

          // 7. STATUS SUPERIORES
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: _buildDjiGpsStatus(gpsAsync),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: _buildDirectionStatus(_smoothHeading),
          ),
        ],
      ),
    );
  }

  // ============================================
  // COMPONENTE: MAPA
  // ============================================

  Widget _buildFlutterMap(
    LatLng center,
    NavigationData navState,
    double rotation,
  ) {
    String urlTemplate;
    switch (_currentMapStyle) {
      case MapStyle.satellite:
        urlTemplate =
            'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
        break;
      case MapStyle.terrain:
        urlTemplate = 'https://mt0.google.com/vt/lyrs=p&x={x}&y={y}&z={z}';
        break;
      case MapStyle.topo3D:
        // Mapa Topográfico 3D (Thunderforest Outdoors - Gratuito até 150k tiles/mês)
        urlTemplate =
            'https://tile.thunderforest.com/outdoors/{z}/{x}/{y}.png?apikey=390a046832534c7c9d2e44227a9fcd92';
        break;
      case MapStyle.light:
        urlTemplate =
            'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
        break;
      case MapStyle.dark:
      default:
        urlTemplate =
            'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
        break;
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 16.0,
        initialRotation: rotation,
        backgroundColor: Colors.black,
        onTap: (tapPos, point) => _handleMapTap(point),
        interactionOptions: InteractionOptions(
          flags: _navMode == NavigationMode.courseUp
              ? InteractiveFlag.all & ~InteractiveFlag.rotate
              : InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: urlTemplate,
          subdomains: _currentMapStyle == MapStyle.terrain ||
                  _currentMapStyle == MapStyle.topo3D
              ? const []
              : const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.navigatorjet.app',
          retinaMode: true,
        ),

        // TODAS as rotas carregadas (visíveis)
        ..._loadedRoutes
            .where((r) => r.isVisible)
            .map((loadedRoute) => PolylineLayer(
                  polylines: [
                    Polyline(
                      points: loadedRoute.route.points
                          .map((p) => LatLng(p.latitude, p.longitude))
                          .toList(),
                      strokeWidth: 5.0,
                      color: loadedRoute.color,
                      pattern: const StrokePattern.solid(),
                    ),
                  ],
                ))
            .toList(),

        // Marcador de Segmento (Etiqueta)
        if (_selectedSegmentPoint != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _selectedSegmentPoint!,
                width: 200,
                height: 90,
                child: _buildSegmentLabel(),
                alignment: Alignment.topCenter,
              ),
            ],
          ),

        // Marcador do Navio
        MarkerLayer(
          markers: [
            Marker(
              point: center,
              width: 80,
              height: 80,
              child: _buildNavigationMarker(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSegmentLabel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: kGlassPanel.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kTacticalGreen, width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.5), blurRadius: 10),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_upward,
                      color: kTacticalGreen, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    "IDA: $_segmentLabelForward",
                    style: const TextStyle(
                      color: kTacticalGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_downward,
                      color: kAlertRed, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    "VOLTA: $_segmentLabelReverse",
                    style: const TextStyle(
                      color: kAlertRed,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
            color: kTacticalGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationMarker() {
    double iconRotation = _navMode == NavigationMode.courseUp
        ? 0.0
        : (_smoothHeading * (math.pi / 180));

    return Transform.rotate(
      angle: iconRotation,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: kTacticalGreen.withOpacity(0.3),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: kTacticalGreen,
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
          ),
          const Icon(Icons.navigation, color: kTacticalGreen, size: 48),
        ],
      ),
    );
  }

  // ============================================
  // COMPONENTE: HUD BÚSSOLA
  // ============================================

  Widget _buildAvionicsCompass(double heading) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.9),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            "${heading.toStringAsFixed(0)}°",
            style: const TextStyle(
              color: kTacticalGreen,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              shadows: [Shadow(color: kTacticalGreen, blurRadius: 8)],
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                CustomPaint(
                  painter: TacticalCompassPainter(heading: heading),
                  size: const Size(double.infinity, 40),
                ),
                const Icon(Icons.arrow_drop_up, color: kAlertRed, size: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // COMPONENTE: DASHBOARD
  // ============================================

  Widget _buildTacticalDashboard(
    double speed,
    NavigationData navState,
    AsyncValue gpsAsync,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: kGlassPanel,
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
                  const Text("VELOCIDADE",
                      style: TextStyle(color: Colors.grey, fontSize: 10)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        speed.toStringAsFixed(0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        " km/h",
                        style: TextStyle(color: kTacticalGreen, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),

              Container(width: 1, height: 40, color: Colors.white12),

              // RUMO & DIST
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildInfoRow(
                    "RUMO",
                    "${gpsAsync.value?.heading?.toStringAsFixed(0) ?? '000'}°",
                  ),
                  const SizedBox(height: 4),
                  _buildInfoRow(
                    "DIST",
                    navState.distanceToTarget != null
                        ? "${(navState.distanceToTarget! / 1000).toStringAsFixed(1)}km"
                        : "--",
                  ),
                ],
              ),

              // VOLTA (Inverter rota ativa)
              InkWell(
                onTap: () {
                  if (_activeRouteId != null) {
                    ref
                        .read(navigationEngineProvider.notifier)
                        .toggleRouteDirection();
                    _showSnack("Rota Invertida");
                    setState(() {});
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: kAlertRed.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kAlertRed),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.swap_vert, color: kAlertRed, size: 20),
                      Text(
                        "VOLTA",
                        style: TextStyle(
                          color: kAlertRed,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          "$label ",
          style: const TextStyle(color: Colors.grey, fontSize: 10),
        ),
        Text(
          value,
          style: const TextStyle(
            color: kTacticalCyan,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

// ============================================
// 🔚 FIM DA PARTE 1/3
// ⚠️  CONTINUE COM A PARTE 2/3
// ============================================
// ============================================
// 📄 map_screen.dart - PARTE 2/3
// ⚠️  COLE ESTE BLOCO APÓS A PARTE 1/3
// ============================================

  // COMPONENTES DE STATUS (continuação da classe _MapScreenState)

  Widget _buildDjiGpsStatus(AsyncValue gpsAsync) {
    double accuracy = 999;
    if (gpsAsync.hasValue && gpsAsync.value != null) {
      accuracy = gpsAsync.value!.accuracy;
    }

    Color signalColor;
    String label;
    int bars;

    if (!gpsAsync.hasValue || gpsAsync.value == null) {
      signalColor = kAlertRed;
      label = "N/A";
      bars = 0;
    } else if (accuracy <= 5) {
      signalColor = kTacticalGreen;
      label = "GPS 3D";
      bars = 4;
    } else if (accuracy <= 10) {
      signalColor = kTacticalGreen;
      label = "READY";
      bars = 3;
    } else if (accuracy <= 20) {
      signalColor = kAlertOrange;
      label = "WEAK";
      bars = 2;
    } else {
      signalColor = kAlertRed;
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
            children: List.generate(
              4,
              (index) => Container(
                width: 3,
                height: 6.0 + (index * 3),
                margin: const EdgeInsets.only(right: 2),
                color: index < bars
                    ? signalColor
                    : Colors.grey.withOpacity(0.3),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: signalColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                "±${accuracy.toStringAsFixed(0)}m",
                style: const TextStyle(color: Colors.white, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDirectionStatus(double heading) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        "${heading.toStringAsFixed(0)}°",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================
  // GERENCIADOR DE ROTAS MÚLTIPLAS
  // ============================================

  void _showRoutesManager(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: kGlassPanel,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "ROTAS CARREGADAS",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    // Lista de Rotas
                    Expanded(
                      child: _loadedRoutes.isEmpty
                          ? const Center(
                              child: Text(
                                "Nenhuma rota carregada",
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _loadedRoutes.length,
                              itemBuilder: (context, index) {
                                final route = _loadedRoutes[index];
                                final isActive = route.id == _activeRouteId;

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? kTacticalGreen.withOpacity(0.2)
                                        : Colors.white10,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isActive
                                          ? kTacticalGreen
                                          : Colors.white24,
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.route,
                                      color: route.color,
                                    ),
                                    title: Text(
                                      route.name,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      "${route.route.points.length} pontos",
                                      style:
                                          const TextStyle(color: Colors.grey),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Trocar cor
                                        IconButton(
                                          icon: Icon(Icons.palette,
                                              color: route.color),
                                          onPressed: () {
                                            _showColorPicker(
                                                context, route, setModalState);
                                          },
                                        ),
                                        // Visibilidade
                                        IconButton(
                                          icon: Icon(
                                            route.isVisible
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            color: Colors.white,
                                          ),
                                          onPressed: () {
                                            setModalState(() {
                                              route.isVisible =
                                                  !route.isVisible;
                                            });
                                            setState(() {});
                                          },
                                        ),
                                        // Navegar
                                        IconButton(
                                          icon: Icon(
                                            Icons.navigation,
                                            color: isActive
                                                ? kTacticalGreen
                                                : Colors.white,
                                          ),
                                          onPressed: () {
                                            _activateRoute(route.id);
                                            setModalState(() {});
                                            setState(() {});
                                          },
                                        ),
                                        // Deletar
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: kAlertRed),
                                          onPressed: () {
                                            setModalState(() {
                                              _loadedRoutes.remove(route);
                                              if (_activeRouteId == route.id) {
                                                _activeRouteId = null;
                                                ref
                                                    .read(
                                                        navigationEngineProvider
                                                            .notifier)
                                                    .stopNavigation();
                                              }
                                            });
                                            setState(() {});
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showColorPicker(
      BuildContext context, LoadedGPXRoute route, StateSetter setModalState) {
    final colors = [
      Colors.orange,
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.yellow,
      Colors.pink,
      Colors.cyan,
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: kGlassPanel,
          title: const Text("Escolher Cor",
              style: TextStyle(color: Colors.white)),
          content: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: colors.map((color) {
              return GestureDetector(
                onTap: () {
                  setModalState(() {
                    route.color = color;
                  });
                  setState(() {});
                  Navigator.pop(context);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: route.color == color
                          ? Colors.white
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _activateRoute(String routeId) {
    final route = _loadedRoutes.firstWhere((r) => r.id == routeId);
    _activeRouteId = routeId;
    ref.read(navigationEngineProvider.notifier).startNavigation(route.route);

    if (route.route.points.isNotEmpty) {
      _mapController.move(
        LatLng(
          route.route.points.first.latitude,
          route.route.points.first.longitude,
        ),
        16,
      );
    }

    _showSnack("Navegando: ${route.name}");
  }

  // ============================================
  // LÓGICA: IMPORTAÇÃO GPX
  // ============================================

  Future<void> _handleGpxImport() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null) {
        final File file = File(result.files.single.path!);
        final app_route.Route? route = await _gpxParser.parseGPXFile(file);

        if (route != null) {
          // Gera ID único e cor aleatória
          final id = DateTime.now().millisecondsSinceEpoch.toString();
          final colors = [
            Colors.orange,
            Colors.blue,
            Colors.red,
            Colors.green,
            Colors.purple,
            Colors.cyan,
          ];
          final randomColor = colors[math.Random().nextInt(colors.length)];

          final loadedRoute = LoadedGPXRoute(
            id: id,
            name: route.name.isEmpty
                ? "Rota ${_loadedRoutes.length + 1}"
                : route.name,
            route: route,
            color: randomColor,
          );

          setState(() {
            _loadedRoutes.add(loadedRoute);
          });

          _showSnack("Rota carregada: ${loadedRoute.name}");
        }
      }
    } catch (e) {
      _logger.e("GPX Error: $e");
      _showSnack("Erro ao importar GPX", isError: true);
    }
  }

  // ============================================
  // LÓGICA: MAPA E NAVEGAÇÃO
  // ============================================

  void _handleMapTap(LatLng point) {
    // Encontra a rota ATIVA para mostrar etiquetas
    if (_activeRouteId == null) return;

    final activeRoute =
        _loadedRoutes.firstWhere((r) => r.id == _activeRouteId);

    setState(() {
      _selectedSegmentPoint = null;
      _segmentLabelForward = null;
      _segmentLabelReverse = null;
    });

    double minDistance = double.infinity;
    int closestIndex = -1;
    const Distance distanceCalc = Distance();

    final points = activeRoute.route.points;
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = LatLng(points[i].latitude, points[i].longitude);
      final p2 = LatLng(points[i + 1].latitude, points[i + 1].longitude);

      final center = LatLng(
        (p1.latitude + p2.latitude) / 2,
        (p1.longitude + p2.longitude) / 2,
      );

      final dist = distanceCalc.as(LengthUnit.Meter, point, center);

      if (dist < 500 && dist < minDistance) {
        minDistance = dist;
        closestIndex = i;
      }
    }

    if (closestIndex != -1) {
      final p1 = points[closestIndex];
      final p2 = points[closestIndex + 1];

      final bearingForward = distanceCalc.bearing(
        LatLng(p1.latitude, p1.longitude),
        LatLng(p2.latitude, p2.longitude),
      );

      double fwd = (bearingForward + 360) % 360;
      double rev = (fwd + 180) % 360;

      setState(() {
        _selectedSegmentPoint = point;
        _segmentLabelForward = "${fwd.toStringAsFixed(0)}°";
        _segmentLabelReverse = "${rev.toStringAsFixed(0)}°";
      });
    }
  }

  void _toggleNavigationMode() {
    setState(() {
      if (_navMode == NavigationMode.northUp) {
        _navMode = NavigationMode.courseUp;
        _showSnack("Modo Proa (Livre)");
      } else {
        _navMode = NavigationMode.northUp;
        _mapController.rotate(0);
        _showSnack("Modo Norte (Fixo)");
      }
    });
  }

  // ============================================
  // DIÁLOGOS E MENUS
  // ============================================

  void _showMapStyleSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: kGlassPanel,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "ESTILO DE MAPA",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      _mapStyleOption(
                          Icons.nightlight_round, "Tático", MapStyle.dark),
                      _mapStyleOption(
                          Icons.satellite_alt, "Satélite", MapStyle.satellite),
                      _mapStyleOption(
                          Icons.landscape, "Terreno", MapStyle.terrain),
                      _mapStyleOption(
                          Icons.terrain, "Topo 3D", MapStyle.topo3D),
                      _mapStyleOption(Icons.wb_sunny, "Claro", MapStyle.light),
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

  Widget _mapStyleOption(IconData icon, String label, MapStyle style) {
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
              color: isSelected ? kTacticalGreen : Colors.white10,
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? [const BoxShadow(color: kTacticalGreen, blurRadius: 10)]
                  : [],
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.black : Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? kTacticalGreen : Colors.grey,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showCalibrationDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kGlassPanel,
        title: const Row(
          children: [
            Icon(Icons.settings_input_antenna, color: kTacticalGreen),
            SizedBox(width: 10),
            Text("Calibração", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          "Mova o dispositivo em '8' para calibrar.\nNecessário apenas uma vez por uso.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: kTacticalGreen)),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? kAlertRed : kTacticalGreen,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // ============================================
  // COMPONENTES VISUAIS
  // ============================================

  Widget _buildCircleButton(
    IconData icon,
    VoidCallback onTap, {
    bool active = false,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: active ? kTacticalGreen : kGlassPanel,
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? kTacticalGreen : Colors.white24,
        ),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: active ? Colors.black : Colors.white,
          size: 20,
        ),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildMiniButton(IconData icon, VoidCallback onTap) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: kGlassPanel.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: Colors.white, size: 18),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildVignetteOverlay() {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.5),
            ],
            radius: 1.2,
            stops: const [0.7, 1.0],
          ),
        ),
      ),
    );
  }

  // ============================================
  // UTILS
  // ============================================

  double _lerpHeading(double a, double b, double t) {
    double diff = b - a;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return a + diff * t;
  }

  double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

// ============================================
// 🔚 FIM DA PARTE 2/3
// ⚠️  CONTINUE COM A PARTE 3/3 (PAINTERS)
// ============================================

// ============================================
// 📄 map_screen.dart - PARTE 3/3 (FINAL)
// ⚠️  COLE ESTE BLOCO APÓS A PARTE 2/3
// ============================================

// ============================================
// CUSTOM PAINTERS
// ============================================

class TacticalCompassPainter extends CustomPainter {
  final double heading;

  TacticalCompassPainter({required this.heading});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final TextPainter tp = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    double pixelPerDegree = size.width / 100;
    double centerX = size.width / 2;

    for (int i = (heading - 50).floor(); i <= (heading + 50).ceil(); i++) {
      int deg = i % 360;
      if (deg < 0) deg += 360;

      double x = centerX + (i - heading) * pixelPerDegree;
      double opacity =
          (1.0 - ((x - centerX).abs() / (size.width / 2))).clamp(0.0, 1.0);

      paint.color = Colors.white.withOpacity(opacity);

      if (deg % 90 == 0) {
        String label =
            deg == 0 ? "N" : deg == 90 ? "E" : deg == 180 ? "S" : "W";

        tp.text = TextSpan(
          text: label,
          style: TextStyle(
            color: label == "N"
                ? kAlertRed.withOpacity(opacity)
                : Colors.white.withOpacity(opacity),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        );

        tp.layout();
        tp.paint(canvas, Offset(x - tp.width / 2, 0));

        paint.strokeWidth = 3;
        canvas.drawLine(Offset(x, 25), Offset(x, 40), paint);
      } else if (deg % 10 == 0) {
        tp.text = TextSpan(
          text: "${deg ~/ 10}",
          style: TextStyle(
            color: Colors.white.withOpacity(opacity),
            fontSize: 12,
          ),
        );

        tp.layout();
        tp.paint(canvas, Offset(x - tp.width / 2, 8));

        paint.strokeWidth = 1.5;
        canvas.drawLine(Offset(x, 30), Offset(x, 40), paint);
      } else if (deg % 5 == 0) {
        paint.strokeWidth = 1;
        canvas.drawLine(Offset(x, 35), Offset(x, 40), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant TacticalCompassPainter oldDelegate) =>
      (oldDelegate.heading - heading).abs() > 0.1;
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

// ============================================
// 🎉 FIM DO ARQUIVO map_screen.dart
// ============================================