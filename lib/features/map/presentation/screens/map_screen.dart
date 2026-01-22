import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';

import '../../../../core/config/app_config.dart';
import '../../../../data/models/route.dart' as app_route;
import '../../../../data/services/compass_service.dart';
import '../../../../data/services/gps_service.dart';
import '../../../navigation/logic/navigation_engine.dart';
import '../../../navigation/presentation/widgets/navigation_compass_tape.dart';
import '../../../gpx/import/gpx_parser.dart';

/// Map Screen - Primary navigation interface with map + compass tape
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  final GPXParser _gpxParser = GPXParser();
  final Logger _logger = Logger();
  
  app_route.Route? _activeRoute;
  bool _isMapReady = false;
  bool _showBufferCircle = true;
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  /// Initialize GPS and Compass services
  Future<void> _initializeServices() async {
    final gpsService = ref.read(gpsServiceProvider);
    final compassService = ref.read(compassServiceProvider);
    
    // Start GPS tracking
    try {
      await gpsService.startTracking();
      _logger.i('GPS Service: Started successfully');
    } catch (e) {
      _logger.e('GPS Service: Failed to start', error: e);
      if (mounted) {
        _showError('GPS não disponível: $e');
      }
    }
    
    // Start compass tracking
    try {
      await compassService.startTracking();
      _logger.i('Compass Service: Started successfully');
    } catch (e) {
      _logger.e('Compass Service: Failed to start', error: e);
      if (mounted) {
        _showError('Bússola não disponível: $e');
      }
    }
    
    // Check compass calibration
    if (!compassService.isCalibrated) {
      if (mounted) {
        _showCalibrationDialog();
      }
    }
    
    setState(() {
      _isMapReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final navigationData = ref.watch(navigationEngineProvider);
    final currentPosition = ref.watch(currentPositionProvider);
    final currentHeadingAsync = ref.watch(currentHeadingProvider);
    
    // Extrai valor do AsyncValue
    final double currentHeading = currentHeadingAsync.when(
      data: (heading) => heading ?? 0.0,
      loading: () => 0.0,
      error: (_, __) => 0.0,
    );
    
    return Scaffold(
      backgroundColor: AppConfig.background,
      body: SafeArea(
        child: Column(
          children: [
            // Compass tape at top (always visible)
            NavigationCompassTape(
              currentHeading: currentHeading,
              targetHeading: navigationData.targetHeading,
              isForwardDirection: _activeRoute?.direction == app_route.RouteDirection.forward,
              onToggleDirection: _activeRoute != null
                  ? () => _toggleRouteDirection()
                  : null,
            ),
            
            // Map area
            Expanded(
              child: Stack(
                children: [
                  // Map widget
                  _buildMap(currentPosition.value, navigationData, currentHeading),
                  
                  // Loading overlay
                  if (!_isMapReady)
                    Container(
                      color: Colors.black87,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppConfig.success),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Inicializando sensores...',
                              style: TextStyle(
                                color: AppConfig.textPrimary.withOpacity(0.8),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // FAB for actions
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Import GPX button
                        FloatingActionButton(
                          heroTag: 'import_gpx',
                          onPressed: _importGPX,
                          backgroundColor: AppConfig.success,
                          tooltip: 'Importar GPX',
                          child: const Icon(Icons.upload_file, color: Colors.black),
                        ),
                        const SizedBox(height: 12),
                        
                        // Toggle buffer circle
                        if (_activeRoute != null)
                          FloatingActionButton.small(
                            heroTag: 'toggle_buffer',
                            onPressed: () {
                              setState(() {
                                _showBufferCircle = !_showBufferCircle;
                              });
                            },
                            backgroundColor: _showBufferCircle 
                                ? AppConfig.warning 
                                : Colors.grey,
                            tooltip: 'Buffer de desvio',
                            child: Icon(
                              _showBufferCircle ? Icons.visibility : Icons.visibility_off,
                              color: Colors.black,
                            ),
                          ),
                        const SizedBox(height: 12),
                        
                        // Center on position button
                        if (currentPosition.value != null)
                          FloatingActionButton.small(
                            heroTag: 'center_position',
                            onPressed: () => _centerOnPosition(currentPosition.value!),
                            backgroundColor: AppConfig.compassNeedle,
                            tooltip: 'Centralizar posição',
                            child: const Icon(Icons.my_location, color: Colors.black),
                          ),
                        const SizedBox(height: 12),
                        
                        // Toggle instrument mode
                        FloatingActionButton(
                          heroTag: 'instrument_mode',
                          onPressed: () => context.go('/instruments'),
                          backgroundColor: AppConfig.warning,
                          tooltip: 'Modo Instrumentos',
                          child: const Icon(Icons.speed, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Metrics bar at bottom (CORRIGIDO: Overflow)
            Container(
              constraints: BoxConstraints(
                maxHeight: AppConfig.metricsBarHeight,
              ),
              child: SingleChildScrollView(
                child: _buildMetricsBar(navigationData, currentPosition.value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build map widget
  Widget _buildMap(dynamic position, NavigationData navigationData, double currentHeading) {
    // Default center (if no GPS)
    LatLng center = const LatLng(-23.5505, -46.6333); // São Paulo
    double zoom = 10.0;
    
    if (position != null) {
      center = LatLng(position.latitude, position.longitude);
      zoom = AppConfig.defaultMapZoom;
    }
    
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        minZoom: 5.0,
        maxZoom: 18.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // Base map tiles
        TileLayer(
          urlTemplate: AppConfig.osmTileUrl,
          userAgentPackageName: 'com.navigatorjet.app',
          tileBuilder: (context, widget, tile) {
            // Darken tiles for better contrast
            return ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.2),
                BlendMode.darken,
              ),
              child: widget,
            );
          },
        ),
        
        // Buffer circle (if active and enabled)
        if (_activeRoute != null && position != null && _showBufferCircle)
          CircleLayer(
            circles: [
              CircleMarker(
                point: LatLng(position.latitude, position.longitude),
                radius: navigationData.bufferRadius,
                useRadiusInMeter: true,
                color: AppConfig.success.withOpacity(0.1),
                borderColor: AppConfig.success.withOpacity(0.3),
                borderStrokeWidth: 2,
              ),
            ],
          ),
        
        // Route line (if active)
        if (_activeRoute != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _activeRoute!.orderedPoints
                    .map((p) => LatLng(p.latitude, p.longitude))
                    .toList(),
                strokeWidth: AppConfig.trackLineWidth,
                color: _activeRoute!.direction == app_route.RouteDirection.forward
                    ? AppConfig.forwardTrackColor
                    : AppConfig.reverseTrackColor,
              ),
            ],
          ),
        
        // Waypoint markers (if active route)
        if (_activeRoute != null)
          MarkerLayer(
            markers: _buildWaypointMarkers(navigationData),
          ),
        
        // Current position marker
        if (position != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(position.latitude, position.longitude),
                width: 40,
                height: 40,
                child: Transform.rotate(
                  angle: currentHeading * (3.14159 / 180),
                  child: const Icon(
                    Icons.navigation,
                    color: AppConfig.compassNeedle,
                    size: 40,
                    shadows: [
                      Shadow(
                        color: Colors.black,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        
        // Attribution
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }

  /// Build waypoint markers for route
  List<Marker> _buildWaypointMarkers(NavigationData navigationData) {
    if (_activeRoute == null) return [];
    
    final markers = <Marker>[];
    final points = _activeRoute!.orderedPoints;
    
    // Show first, last, and current target waypoint
    final indicesToShow = <int>{
      0, // First
      points.length - 1, // Last
      if (navigationData.currentWaypointIndex < points.length)
        navigationData.currentWaypointIndex, // Current target
    };
    
    for (final i in indicesToShow) {
      final point = points[i];
      final isCurrent = i == navigationData.currentWaypointIndex;
      final isFirst = i == 0;
      final isLast = i == points.length - 1;
      
      markers.add(
        Marker(
          point: LatLng(point.latitude, point.longitude),
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: isCurrent 
                  ? AppConfig.compassTarget 
                  : isFirst 
                      ? AppConfig.success 
                      : isLast 
                          ? AppConfig.danger 
                          : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '${i + 1}',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return markers;
  }

  /// Build metrics bar at bottom
  Widget _buildMetricsBar(NavigationData navigationData, dynamic position) {
    final gpsService = ref.read(gpsServiceProvider);
    final speed = gpsService.currentSpeed ?? 0.0;
    final batteryLevel = 85; // TODO: Integrate battery_plus
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.black.withOpacity(0.95),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Speed
          _buildMetric(
            icon: Icons.speed,
            label: 'VEL',
            value: '${speed.toStringAsFixed(1)}',
            unit: 'km/h',
            color: AppConfig.success,
          ),
          
          // Distance to target
          if (navigationData.distanceToTarget != null)
            _buildMetric(
              icon: Icons.flag,
              label: 'DIST',
              value: navigationData.distanceToTarget! < 1000
                  ? navigationData.distanceToTarget!.toStringAsFixed(0)
                  : (navigationData.distanceToTarget! / 1000).toStringAsFixed(2),
              unit: navigationData.distanceToTarget! < 1000 ? 'm' : 'km',
              color: AppConfig.textPrimary,
            ),
          
          // Cross-track distance (buffer status)
          if (navigationData.crossTrackDistance != null)
            _buildMetric(
              icon: Icons.straighten,
              label: 'DESVIO',
              value: '${navigationData.crossTrackDistance!.abs().toStringAsFixed(0)}',
              unit: 'm',
              color: AppConfig.getBufferStatusColor(
                navigationData.crossTrackDistance!,
                navigationData.bufferRadius,
              ),
            ),
          
          // Battery
          _buildMetric(
            icon: Icons.battery_full,
            label: 'BAT',
            value: '$batteryLevel',
            unit: '%',
            color: batteryLevel > 20 ? AppConfig.success : AppConfig.danger,
          ),
        ],
      ),
    );
  }

  /// Build single metric widget
  Widget _buildMetric({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.7),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Import GPX file (CORRIGIDO: Feedback visual + tratamento de erros)
  Future<void> _importGPX() async {
    try {
      // Mostra loading enquanto seleciona arquivo
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppConfig.success),
          ),
        ),
      );

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['gpx', 'kml'],
        dialogTitle: 'Selecione uma rota GPX/KML',
      );

      // Remove loading dialog
      if (mounted) Navigator.pop(context);

      if (result == null || result.files.single.path == null) {
        _logger.w('GPX Import: User cancelled');
        return;
      }

      final file = File(result.files.single.path!);
      _logger.i('GPX Import: File selected - ${file.path}');

      // Mostra progresso de parsing
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.black87,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppConfig.success),
                ),
                const SizedBox(height: 16),
                Text(
                  'Processando GPX...',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Parse GPX
      final route = await _gpxParser.parseGPXFile(file);

      // Remove parsing dialog
      if (mounted) Navigator.pop(context);

      if (route == null) {
        if (mounted) {
          _showError('Erro ao importar GPX.\n\nArquivo inválido ou corrompido.');
        }
        return;
      }

      _logger.i('GPX Import: Route parsed - ${route.name} (${route.waypointCount} pontos)');

      // Salva rota no Hive
      final routesBox = Hive.box<app_route.Route>('routes');
      await routesBox.put(route.id, route);
      _logger.i('GPX Import: Route saved to Hive');

      setState(() {
        _activeRoute = route;
      });

      // Start navigation
      ref.read(navigationEngineProvider.notifier).startNavigation(route);

      // Fit map to route bounds
      final bounds = route.getBounds();
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(bounds.southwest, bounds.northeast),
          padding: const EdgeInsets.all(50),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Rota "${route.name}" carregada!',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${route.waypointCount} pontos • ${(route.totalDistance / 1000).toStringAsFixed(2)} km',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppConfig.success,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e, stackTrace) {
      _logger.e('GPX Import: Error', error: e, stackTrace: stackTrace);
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        _showError('Erro ao importar GPX:\n\n$e');
      }
    }
  }

  /// Toggle route direction (CORRIGIDO: Feedback visual)
  void _toggleRouteDirection() {
    if (_activeRoute == null) return;
    
    ref.read(navigationEngineProvider.notifier).toggleRouteDirection();
    
    setState(() {
      // Força rebuild para mostrar mudança de cor
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _activeRoute!.direction == app_route.RouteDirection.forward
              ? '⬆️ Navegando em IDA'
              : '⬇️ Navegando em VOLTA',
        ),
        backgroundColor: _activeRoute!.direction == app_route.RouteDirection.forward
            ? AppConfig.success
            : AppConfig.warning,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Center map on current position
  void _centerOnPosition(dynamic position) {
    _mapController.move(
      LatLng(position.latitude, position.longitude),
      AppConfig.defaultMapZoom,
    );
  }

  /// Show calibration dialog
  void _showCalibrationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Row(
          children: [
            Icon(Icons.explore, color: AppConfig.warning, size: 32),
            SizedBox(width: 12),
            Text(
              'Calibração da Bússola',
              style: TextStyle(color: AppConfig.warning),
            ),
          ],
        ),
        content: const Text(
          'Para melhor precisão, mova o celular em forma de "8" no ar.\n\n'
          'Isso calibra o magnetômetro.',
          style: TextStyle(color: AppConfig.textPrimary, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppConfig.success)),
          ),
        ],
      ),
    );
  }

  /// Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: AppConfig.danger,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}