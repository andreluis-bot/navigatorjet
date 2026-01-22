import 'dart:io';

import 'package:gpx/gpx.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/app_config.dart';
// Mantemos o alias para evitar conflito com Route do Flutter
import '../../../data/models/route.dart' as app_models;
// Se RoutePoint estiver em route.dart, não precisamos importar waypoint.dart separadamente para ele, 
// mas se Waypoint for outra classe usada, mantemos.
import '../../../data/models/waypoint.dart'; 

class GPXParser {
  final Logger _logger = Logger();
  final _uuid = const Uuid();
  
  Future<app_models.Route?> parseGPXFile(File file) async {
    try {
      _logger.i('GPX: Parsing file ${file.path}');
      
      final gpxString = await file.readAsString();
      final gpx = GpxReader().fromString(gpxString);
      
      if (gpx.trks.isEmpty && gpx.rtes.isEmpty) {
        _logger.e('GPX: No tracks or routes found');
        return null;
      }
      
      // CORREÇÃO: Usando app_models.RoutePoint
      List<app_models.RoutePoint> points = [];
      String routeName = 'Imported Route';
      
      if (gpx.trks.isNotEmpty) {
        final track = gpx.trks.first;
        routeName = track.name ?? routeName;
        
        for (final segment in track.trksegs) {
          int segmentIndex = 0;
          for (final point in segment.trkpts) {
            if (point.lat != null && point.lon != null) {
              // CORREÇÃO: app_models.RoutePoint
              points.add(app_models.RoutePoint(
                latitude: point.lat!,
                longitude: point.lon!,
                elevation: point.ele,
                segmentIndex: segmentIndex,
              ));
              segmentIndex++;
            }
          }
        }
      } else if (gpx.rtes.isNotEmpty) {
        final route = gpx.rtes.first;
        routeName = route.name ?? routeName;
        
        int segmentIndex = 0;
        for (final point in route.rtepts) {
          if (point.lat != null && point.lon != null) {
            // CORREÇÃO: app_models.RoutePoint
            points.add(app_models.RoutePoint(
              latitude: point.lat!,
              longitude: point.lon!,
              elevation: point.ele,
              segmentIndex: segmentIndex,
            ));
            segmentIndex++;
          }
        }
      }
      
      if (points.isEmpty) {
        _logger.e('GPX: No valid points found');
        return null;
      }
      
      final totalDistance = _calculateTotalDistance(points);
      
      _logger.i('GPX: Parsed successfully - ${points.length} points');
      
      return app_models.Route(
        id: _uuid.v4(),
        name: routeName,
        points: points,
        direction: app_models.RouteDirection.forward,
        totalDistance: totalDistance,
        lineColor: AppConfig.defaultTrackColor,
      );
      
    } catch (e, stackTrace) {
      _logger.e('GPX: Parse error - $e', error: e, stackTrace: stackTrace);
      return null;
    }
  }
  
  // CORREÇÃO: app_models.RoutePoint
  double _calculateTotalDistance(List<app_models.RoutePoint> points) {
    if (points.length < 2) return 0.0;
    double totalDistance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += points[i].distanceTo(points[i + 1]);
    }
    return totalDistance;
  }
  
  // CORREÇÃO: app_models.RoutePoint (nos parâmetros e retorno)
  List<app_models.RoutePoint> simplifyRoute(List<app_models.RoutePoint> points, {double tolerance = 10.0}) {
    if (points.length < 3) return points;
    return _douglasPeucker(points, tolerance);
  }
  
  // CORREÇÃO: app_models.RoutePoint
  List<app_models.RoutePoint> _douglasPeucker(List<app_models.RoutePoint> points, double tolerance) {
    if (points.length < 3) return points;
    
    double maxDistance = 0.0;
    int maxIndex = 0;
    final first = points.first;
    final last = points.last;
    
    for (int i = 1; i < points.length - 1; i++) {
      final distance = _perpendicularDistance(points[i], first, last);
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }
    
    if (maxDistance > tolerance) {
      final left = _douglasPeucker(points.sublist(0, maxIndex + 1), tolerance);
      final right = _douglasPeucker(points.sublist(maxIndex), tolerance);
      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      return [first, last];
    }
  }
  
  // CORREÇÃO: app_models.RoutePoint
  double _perpendicularDistance(app_models.RoutePoint point, app_models.RoutePoint lineStart, app_models.RoutePoint lineEnd) {
    final numerator = ((lineEnd.longitude - lineStart.longitude) * point.latitude - 
                      (lineEnd.latitude - lineStart.latitude) * point.longitude + 
                      lineEnd.latitude * lineStart.longitude - 
                      lineEnd.longitude * lineStart.latitude).abs();
    
    final denominator = ((lineEnd.longitude - lineStart.longitude) * (lineEnd.longitude - lineStart.longitude) + 
                        (lineEnd.latitude - lineStart.latitude) * (lineEnd.latitude - lineStart.latitude));
    
    if (denominator == 0) return 0.0;
    const metersPerDegree = 111320.0; 
    return (numerator / denominator) * metersPerDegree;
  }
  
  String exportToGPX(app_models.Route route) {
    final gpx = Gpx();
    gpx.creator = 'NavigatorJet';
    gpx.version = '1.1';
    
    final track = Trk();
    track.name = route.name;
    final segment = Trkseg();
    
    for (final point in route.points) {
      segment.trkpts.add(Wpt(
        lat: point.latitude,
        lon: point.longitude,
        ele: point.elevation,
      ));
    }
    
    track.trksegs.add(segment);
    gpx.trks.add(track);
    
    return GpxWriter().asString(gpx, pretty: true);
  }
}