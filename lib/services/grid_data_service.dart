import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import 'file_reader_stub.dart'
    if (dart.library.io) 'file_reader_desktop.dart'
    if (dart.library.html) 'file_reader_web.dart';

/// Model for an OSM Power Route line segment
class GridRoute {
  final String id;
  final String name;
  final String projectSegment;
  final String fromSubstation;
  final String toSubstation;
  final String toVillage;
  final double lengthKm;
  final Color color;
  final List<LatLng> points;
  final String calloutLabel;
  final String shortLabel;
  final LatLng calloutLocation;
  final bool hasCallout;
  final String voltage;
  final double strokeWidth;

  const GridRoute({
    required this.id,
    required this.name,
    required this.projectSegment,
    required this.fromSubstation,
    required this.toSubstation,
    required this.toVillage,
    required this.lengthKm,
    required this.color,
    required this.points,
    required this.calloutLabel,
    this.shortLabel = '',
    required this.calloutLocation,
    this.hasCallout = false,
    this.voltage = '400 kV',
    this.strokeWidth = 4.2,
  });
}

/// Model for an OSM Substation polygon and marker
class GridSubstation {
  final String id;
  final String name;
  final String voltage;
  final String village;
  final LatLng location;
  final List<LatLng> polygonPoints;
  final bool isPrimary; // Featured in the UI like Meramundali & Meramundali B

  const GridSubstation({
    required this.id,
    required this.name,
    required this.voltage,
    required this.village,
    required this.location,
    required this.polygonPoints,
    this.isPrimary = false,
  });
}

/// Model for a KML Tower placemark
class GridKmlTower {
  final String name;
  final String description;
  final double altitude;
  final LatLng location;
  final String lineCategory;

  const GridKmlTower({
    required this.name,
    required this.description,
    required this.altitude,
    required this.location,
    required this.lineCategory,
  });
}

/// Model for a KML LineString segment
class GridKmlSegment {
  final String name;
  final String lineCategory;
  final List<LatLng> points;
  final double strokeWidth;

  const GridKmlSegment({
    required this.name,
    required this.lineCategory,
    required this.points,
    this.strokeWidth = 2.0,
  });
}

/// Container for all loaded grid data
class GridData {
  final List<GridRoute> routes;
  final List<GridSubstation> substations;
  final List<GridKmlTower> kmlTowers;
  final List<GridKmlSegment> kmlSegments;

  const GridData({
    required this.routes,
    required this.substations,
    required this.kmlTowers,
    required this.kmlSegments,
  });
}

class GridDataService {
  static const String kmlPath = r'C:\flutter_power\transmission_towers.kml';
  static const String substationsPath = r'C:\flutter_power\substations_osm.geojson';
  static const String routesPath = r'C:\flutter_power\osm_power_routes.geojson';

  static const String assetKmlPath = 'assets/data/transmission_towers.kml';
  static const String assetSubstationsPath = 'assets/data/substations_osm.geojson';
  static const String assetRoutesPath = 'assets/data/osm_power_routes.geojson';

  static GridData? _cachedGridData;

  /// Loads raw text content from local disk file path with asset fallback
  static Future<String> _loadFileString(String localDiskPath, String assetFallbackPath) async {
    try {
      final diskContent = await readLocalFile(localDiskPath);
      if (diskContent != null && diskContent.trim().isNotEmpty) {
        return diskContent;
      }
    } catch (e) {
      debugPrint('GridDataService: Disk read error for $localDiskPath: $e');
    }
    return await rootBundle.loadString(assetFallbackPath);
  }

  /// Loads and parses transmission_towers.kml, substations_osm.geojson, and osm_power_routes.geojson
  static Future<GridData> loadGridData() async {
    if (_cachedGridData != null) {
      return _cachedGridData!;
    }

    try {
      final kmlContentFuture = _loadFileString(kmlPath, assetKmlPath);
      final substationsContentFuture = _loadFileString(substationsPath, assetSubstationsPath);
      final routesContentFuture = _loadFileString(routesPath, assetRoutesPath);

      final results = await Future.wait([
        kmlContentFuture,
        substationsContentFuture,
        routesContentFuture,
      ]);

      final kmlString = results[0];
      final substationsJsonString = results[1];
      final routesJsonString = results[2];

      final kmlParsed = _parseKml(kmlString);
      final substations = _parseSubstations(substationsJsonString);
      final routes = _parseRoutes(routesJsonString);

      _cachedGridData = GridData(
        routes: routes,
        substations: substations,
        kmlTowers: kmlParsed.$1,
        kmlSegments: kmlParsed.$2,
      );

      return _cachedGridData!;
    } catch (e, stack) {
      debugPrint('Error loading grid data: $e\n$stack');
      rethrow;
    }
  }

  /// Parses transmission_towers.kml
  static (List<GridKmlTower>, List<GridKmlSegment>) _parseKml(String kmlString) {
    final towers = <GridKmlTower>[];
    final segments = <GridKmlSegment>[];

    // Split folders
    final folderRegex = RegExp(r'<Folder>(.*?)</Folder>', dotAll: true);
    final placemarkRegex = RegExp(r'<Placemark>(.*?)</Placemark>', dotAll: true);
    final nameRegex = RegExp(r'<name>(.*?)</name>');
    final descRegex = RegExp(r'<description>(.*?)</description>');
    final pointRegex = RegExp(r'<Point>\s*<coordinates>(.*?)</coordinates>\s*</Point>', dotAll: true);
    final lineRegex = RegExp(r'<LineString>.*?<coordinates>(.*?)</coordinates>.*?</LineString>', dotAll: true);

    for (final folderMatch in folderRegex.allMatches(kmlString)) {
      final folderXml = folderMatch.group(1) ?? '';
      final folderName = nameRegex.firstMatch(folderXml)?.group(1)?.trim() ?? '';

      for (final pmMatch in placemarkRegex.allMatches(folderXml)) {
        final pmXml = pmMatch.group(1) ?? '';
        final name = nameRegex.firstMatch(pmXml)?.group(1)?.trim() ?? '';
        final desc = descRegex.firstMatch(pmXml)?.group(1)?.trim() ?? '';

        final pointMatch = pointRegex.firstMatch(pmXml);
        if (pointMatch != null) {
          final coordsStr = pointMatch.group(1)?.trim() ?? '';
          final parts = coordsStr.split(',');
          if (parts.length >= 2) {
            final lng = double.tryParse(parts[0].trim()) ?? 0.0;
            final lat = double.tryParse(parts[1].trim()) ?? 0.0;
            final alt = parts.length > 2 ? (double.tryParse(parts[2].trim()) ?? 0.0) : 0.0;
            if (lat != 0.0 && lng != 0.0) {
              towers.add(GridKmlTower(
                name: name,
                description: desc,
                altitude: alt,
                location: LatLng(lat, lng),
                lineCategory: folderName,
              ));
            }
          }
        }

        final lineMatch = lineRegex.firstMatch(pmXml);
        if (lineMatch != null) {
          final coordsBlock = lineMatch.group(1)?.trim() ?? '';
          final lines = coordsBlock.split(RegExp(r'\s+'));
          final linePts = <LatLng>[];
          for (final line in lines) {
            final p = line.trim();
            if (p.isEmpty) continue;
            final parts = p.split(',');
            if (parts.length >= 2) {
              final lng = double.tryParse(parts[0].trim()) ?? 0.0;
              final lat = double.tryParse(parts[1].trim()) ?? 0.0;
              if (lat != 0.0 && lng != 0.0) {
                linePts.add(LatLng(lat, lng));
              }
            }
          }
          if (linePts.isNotEmpty) {
            double segWidth = 2.0;
            if (folderName.contains('400')) {
              segWidth = 4.2;
            } else if (folderName.contains('220')) {
              segWidth = 2.8;
            } else if (folderName.contains('135') || folderName.contains('132')) {
              segWidth = 1.6;
            }
            segments.add(GridKmlSegment(
              name: name,
              lineCategory: folderName,
              points: linePts,
              strokeWidth: segWidth,
            ));
          }
        }
      }
    }

    return (towers, segments);
  }

  /// Parses substations_osm.geojson
  static List<GridSubstation> _parseSubstations(String jsonString) {
    final substations = <GridSubstation>[];
    final dynamic decoded = json.decode(jsonString);
    if (decoded is! Map<String, dynamic>) return substations;

    final features = decoded['features'] as List<dynamic>? ?? [];
    for (final f in features) {
      if (f is! Map<String, dynamic>) continue;
      final props = f['properties'] as Map<String, dynamic>? ?? {};
      final geom = f['geometry'] as Map<String, dynamic>? ?? {};

      final name = props['osm_name'] as String? ?? '';
      final label = props['label'] as String? ?? '';
      final voltage = props['osm_voltage'] as String? ?? '';
      final village = props['village'] as String? ?? '';

      final geomType = geom['type'] as String? ?? '';
      final coords = geom['coordinates'] as List<dynamic>? ?? [];

      final polyPoints = <LatLng>[];
      if (geomType == 'Polygon' && coords.isNotEmpty) {
        final ring = coords[0] as List<dynamic>? ?? [];
        for (final pt in ring) {
          if (pt is List && pt.length >= 2) {
            final lng = (pt[0] as num).toDouble();
            final lat = (pt[1] as num).toDouble();
            polyPoints.add(LatLng(lat, lng));
          }
        }
      }

      // Calculate centroid or representative location
      LatLng loc = const LatLng(20.8226, 85.2530);
      if (polyPoints.isNotEmpty) {
        double sumLat = 0;
        double sumLng = 0;
        for (final p in polyPoints) {
          sumLat += p.latitude;
          sumLng += p.longitude;
        }
        loc = LatLng(sumLat / polyPoints.length, sumLng / polyPoints.length);
      }

      // Determine clean display name and subtext
      String displayName = name.isNotEmpty && name != '(none)' ? name : label;
      String displayVoltage = '400/220/132 kV';
      if (voltage.contains('400000') && voltage.contains('220000') && voltage.contains('132000')) {
        displayVoltage = '400/220/132 kV';
      } else if (voltage.contains('400000') && voltage.contains('220000')) {
        displayVoltage = '400/220 kV';
      } else if (voltage.contains('220000') && voltage.contains('132000')) {
        displayVoltage = '220/132 kV';
      } else if (voltage.contains('220000')) {
        displayVoltage = '220 kV';
      } else if (voltage.contains('132000')) {
        displayVoltage = '132 kV';
      }

      final isMeramundali = displayName.toLowerCase().contains('meramundali');
      final isMeramundaliB = displayName.toLowerCase().contains('meramundali b');

      if (isMeramundaliB) {
        displayName = 'Meramundali B';
      } else if (isMeramundali) {
        displayName = 'Meramundali';
      }

      substations.add(GridSubstation(
        id: props['osm_way']?.toString() ?? displayName,
        name: displayName,
        voltage: displayVoltage,
        village: village.isNotEmpty ? village : '',
        location: loc,
        polygonPoints: polyPoints,
        isPrimary: isMeramundali || isMeramundaliB,
      ));
    }

    return substations;
  }

  /// Parses osm_power_routes.geojson and assigns colors & callout pills
  static List<GridRoute> _parseRoutes(String jsonString) {
    final routes = <GridRoute>[];
    final dynamic decoded = json.decode(jsonString);
    if (decoded is! Map<String, dynamic>) return routes;

    final features = decoded['features'] as List<dynamic>? ?? [];
    for (int i = 0; i < features.length; i++) {
      final f = features[i] as Map<String, dynamic>? ?? {};
      final props = f['properties'] as Map<String, dynamic>? ?? {};
      final geom = f['geometry'] as Map<String, dynamic>? ?? {};

      final routeName = props['route'] as String? ?? 'Route $i';
      final projectSegment = props['project_segment'] as String? ?? '';
      final fromSub = props['from_substation'] as String? ?? '';
      final toSub = props['to_substation'] as String? ?? '';
      final toVillage = props['to_village'] as String? ?? '';
      final lengthKm = (props['length_km'] as num?)?.toDouble() ?? 0.0;

      final coords = geom['coordinates'] as List<dynamic>? ?? [];
      final points = <LatLng>[];
      for (final pt in coords) {
        if (pt is List && pt.length >= 2) {
          final lng = (pt[0] as num).toDouble();
          final lat = (pt[1] as num).toDouble();
          points.add(LatLng(lat, lng));
        }
      }

      // Assign exact colors and callout placement based on Penpot design
      Color color;
      String calloutLabel = '';
      String shortLabel = '';
      LatLng calloutLocation = points.isNotEmpty ? points[points.length ~/ 2] : const LatLng(20.8, 85.25);
      bool hasCallout = false;

      if (routeName.contains('R5') || routeName.contains('Mendhasal')) {
        // Mendhasal 400 kV (Purple) - Heads South-East
        color = const Color(0xFF7631EC);
        calloutLabel = 'Mendhasal 400 kV · 99 km';
        shortLabel = 'Mendhasal · 400 kV';
        calloutLocation = const LatLng(20.7550, 85.3550);
        hasCallout = true;
      } else if (routeName.contains('R4alt') || routeName.contains('Charagadia') || routeName.contains('parallel to 400kV')) {
        // Charagadia 132 kV (Brown) - 7 km link
        color = const Color(0xFFA78565);
        calloutLabel = 'Charagadia 132 kV · 7 km';
        shortLabel = 'Charagadia · 132 kV';
        calloutLocation = const LatLng(20.8030, 85.2840);
        hasCallout = true;
      } else if (routeName.contains('R4') || routeName.contains('Duburi (New)')) {
        // Duburi (New) 400 kV (Pink / Magenta) - Heads North-East
        color = const Color(0xFFD91D71);
        calloutLabel = 'Duburi (New) 400 kV · 96 km';
        shortLabel = 'Duburi (New) · 400 kV';
        calloutLocation = const LatLng(20.8580, 85.3150);
        hasCallout = true;
      } else if (routeName.contains('R2') || routeName.contains('Bhanjanagar')) {
        // Bhanjanagar 220 kV (Blue) - Heads West
        color = const Color(0xFF366FED);
        calloutLabel = 'Bhanjanagar 220 kV · 136 km';
        shortLabel = 'Bhanjanagar · 220 kV';
        calloutLocation = const LatLng(20.8140, 85.1950);
        hasCallout = true;
      } else if (routeName.contains('R1') || routeName.contains('135KV Line') || routeName.contains('Gundicha')) {
        // Gundicha Pada 132 kV (Teal) - Heads East/South-East
        color = const Color(0xFF47AEA5);
        calloutLabel = 'Gundicha Pada 132 kV · 36 km';
        shortLabel = 'Gundicha · 132 kV';
        calloutLocation = const LatLng(20.7720, 85.3750);
        hasCallout = true;
      } else if (routeName.contains('R3') || routeName.contains('Joda') || routeName.contains('Site B (to tee)')) {
        // Joda / Duburi (Old) 220 kV (Cyan) - Heads North
        color = const Color(0xFF19BCD7);
        calloutLabel = 'Joda / Duburi (Old) 220 kV · 132 km';
        shortLabel = 'Joda / Duburi · 220 kV';
        calloutLocation = points.isNotEmpty ? points[points.length ~/ 2] : const LatLng(20.8800, 85.2720);
        hasCallout = true;
      } else {
        color = const Color(0xFF64748B);
        calloutLabel = '$routeName · ${lengthKm.toStringAsFixed(0)} km';
        shortLabel = routeName;
        hasCallout = true;
      }
      String routeVoltage;
      double routeStrokeWidth;
      if (routeName.contains('R4alt') || routeName.contains('132') || routeName.contains('135')) {
        routeVoltage = '132 kV';
        routeStrokeWidth = 1.6;
      } else if (routeName.contains('400')) {
        routeVoltage = '400 kV';
        routeStrokeWidth = 4.2;
      } else if (routeName.contains('220')) {
        routeVoltage = '220 kV';
        routeStrokeWidth = 2.8;
      } else {
        routeVoltage = 'Other';
        routeStrokeWidth = 2.0;
      }

      routes.add(GridRoute(
        id: 'route_$i',
        name: routeName,
        projectSegment: projectSegment,
        fromSubstation: fromSub,
        toSubstation: toSub,
        toVillage: toVillage,
        lengthKm: lengthKm,
        color: color,
        points: points,
        calloutLabel: calloutLabel,
        shortLabel: shortLabel,
        calloutLocation: calloutLocation,
        hasCallout: hasCallout,
        voltage: routeVoltage,
        strokeWidth: routeStrokeWidth,
      ));
    }

    return routes;
  }
}
