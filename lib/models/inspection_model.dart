import 'dart:ui';

/// Full Inspection Model mapped directly from inspection 1.json
class InspectionData {
  final String inspectionId;
  final Tower tower;

  InspectionData({
    required this.inspectionId,
    required this.tower,
  });

  factory InspectionData.fromJson(Map<String, dynamic> json) {
    return InspectionData(
      inspectionId: json['inspection_id'] as String? ?? '',
      tower: Tower.fromJson(json['tower'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class TowerLocation {
  final double latitude;
  final double longitude;
  final double altitudeM;

  TowerLocation({
    required this.latitude,
    required this.longitude,
    required this.altitudeM,
  });

  factory TowerLocation.fromJson(Map<String, dynamic> json) {
    return TowerLocation(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      altitudeM: (json['altitude_m'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class TowerDetection {
  final double confidence;
  final List<double> bbox; // [x, y, w, h]
  final String imagePath;
  final int imageWidth;
  final int imageHeight;
  final String videoId;
  final int frameNumber;
  final String timestamp;

  TowerDetection({
    required this.confidence,
    required this.bbox,
    required this.imagePath,
    required this.imageWidth,
    required this.imageHeight,
    required this.videoId,
    required this.frameNumber,
    required this.timestamp,
  });

  factory TowerDetection.fromJson(Map<String, dynamic> json) {
    return TowerDetection(
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      bbox: (json['bbox'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      imagePath: json['image_path'] as String? ?? '',
      imageWidth: (json['image_width'] as num?)?.toInt() ?? 1920,
      imageHeight: (json['image_height'] as num?)?.toInt() ?? 1080,
      videoId: json['video_id'] as String? ?? '',
      frameNumber: (json['frame_number'] as num?)?.toInt() ?? 0,
      timestamp: json['timestamp'] as String? ?? '',
    );
  }
}

class TowerSummary {
  final int circuitCount;
  final String componentDetectionStatus;
  final Map<String, int> componentCounts;
  final List<String> missingComponents;

  TowerSummary({
    required this.circuitCount,
    required this.componentDetectionStatus,
    required this.componentCounts,
    required this.missingComponents,
  });

  factory TowerSummary.fromJson(Map<String, dynamic> json) {
    final countsMap = <String, int>{};
    final detCounts = json['detection_counts'] as Map<String, dynamic>?;
    if (detCounts != null) {
      final comps = detCounts['components'] as Map<String, dynamic>?;
      if (comps != null) {
        comps.forEach((k, v) {
          countsMap[k] = (v as num?)?.toInt() ?? 0;
        });
      }
    }

    final missing = (json['missing_components'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return TowerSummary(
      circuitCount: (json['circuit_count'] as num?)?.toInt() ?? 2,
      componentDetectionStatus:
          json['component_detection_status'] as String? ?? 'completed',
      componentCounts: countsMap,
      missingComponents: missing,
    );
  }
}

class Tower {
  final String towerId;
  final String towerName;
  final TowerLocation location;
  final TowerDetection towerDetection;
  final TowerSummary summary;
  final List<Circuit> circuits;

  Tower({
    required this.towerId,
    required this.towerName,
    required this.location,
    required this.towerDetection,
    required this.summary,
    required this.circuits,
  });

  factory Tower.fromJson(Map<String, dynamic> json) {
    final circuitsList = <Circuit>[];
    if (json['circuits'] is List) {
      for (final c in json['circuits']) {
        if (c is Map<String, dynamic>) {
          circuitsList.add(Circuit.fromJson(c));
        }
      }
    }

    return Tower(
      towerId: json['tower_id'] as String? ?? '400KV_Tower_1_Site_B',
      towerName: json['tower_name'] as String? ?? '400KV Tower 1 (Site B)',
      location: TowerLocation.fromJson(
          json['tower_location'] as Map<String, dynamic>? ?? {}),
      towerDetection: TowerDetection.fromJson(
          json['tower_detection'] as Map<String, dynamic>? ?? {}),
      summary:
          TowerSummary.fromJson(json['summary'] as Map<String, dynamic>? ?? {}),
      circuits: circuitsList,
    );
  }
}

class Circuit {
  final String circuitId;
  final double confidence;
  final List<double> bbox;
  final Map<String, Phase> phases; // 'R', 'Y', 'B'

  Circuit({
    required this.circuitId,
    required this.confidence,
    required this.bbox,
    required this.phases,
  });

  factory Circuit.fromJson(Map<String, dynamic> json) {
    final cd = json['circuit_detection'] as Map<String, dynamic>? ?? {};
    final phasesMap = <String, Phase>{};
    final pJson = json['phases'] as Map<String, dynamic>?;
    if (pJson != null) {
      pJson.forEach((k, v) {
        if (v is Map<String, dynamic>) {
          phasesMap[k] = Phase.fromJson(k, v);
        }
      });
    }

    return Circuit(
      circuitId: json['circuit_id'] as String? ?? 'Circuit_SW',
      confidence: (cd['confidence'] as num?)?.toDouble() ?? 0.0,
      bbox: (cd['bbox'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      phases: phasesMap,
    );
  }
}

class PhaseKeypoint {
  final double x;
  final double y;
  final double? confidence;

  PhaseKeypoint({required this.x, required this.y, this.confidence});

  factory PhaseKeypoint.fromJson(Map<String, dynamic> json) {
    return PhaseKeypoint(
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      confidence: (json['confidence'] as num?)?.toDouble(),
    );
  }
}

class Phase {
  final String phaseName; // 'R', 'Y', 'B'
  final PhaseKeypoint? keypoint;
  final List<InspectionImage> images;

  Phase({
    required this.phaseName,
    required this.keypoint,
    required this.images,
  });

  factory Phase.fromJson(String name, Map<String, dynamic> json) {
    final imgList = <InspectionImage>[];
    if (json['images'] is List) {
      for (final im in json['images']) {
        if (im is Map<String, dynamic>) {
          imgList.add(InspectionImage.fromJson(im));
        }
      }
    }

    return Phase(
      phaseName: name,
      keypoint: json['keypoint'] is Map<String, dynamic>
          ? PhaseKeypoint.fromJson(json['keypoint'] as Map<String, dynamic>)
          : null,
      images: imgList,
    );
  }

  /// Total defects in this phase
  int get defectCount {
    int count = 0;
    for (final im in images) {
      count += im.missingCotterPinCount;
    }
    return count;
  }

  bool get isCritical => defectCount > 0;
}

class ImageTelemetry {
  final String capturedAt;
  final double latitude;
  final double longitude;
  final double absoluteAltitudeM;
  final double relativeAltitudeM;
  final double yawDeg;

  ImageTelemetry({
    required this.capturedAt,
    required this.latitude,
    required this.longitude,
    required this.absoluteAltitudeM,
    required this.relativeAltitudeM,
    required this.yawDeg,
  });

  factory ImageTelemetry.fromJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>? ?? {};
    final flight = json['flight'] as Map<String, dynamic>? ?? {};
    return ImageTelemetry(
      capturedAt: json['captured_at'] as String? ?? '',
      latitude: (loc['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (loc['longitude'] as num?)?.toDouble() ?? 0.0,
      absoluteAltitudeM:
          (loc['absolute_altitude_m'] as num?)?.toDouble() ?? 0.0,
      relativeAltitudeM:
          (loc['relative_altitude_m'] as num?)?.toDouble() ?? 0.0,
      yawDeg: (flight['yaw_deg'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class InspectionImage {
  final String imageId;
  final String imagePath;
  final int imageWidth;
  final int imageHeight;
  final double distanceToTowerM;
  final ImageTelemetry? telemetry;
  final Map<String, List<ComponentDetection>> componentDetections;

  InspectionImage({
    required this.imageId,
    required this.imagePath,
    required this.imageWidth,
    required this.imageHeight,
    required this.distanceToTowerM,
    required this.telemetry,
    required this.componentDetections,
  });

  factory InspectionImage.fromJson(Map<String, dynamic> json) {
    final detsMap = <String, List<ComponentDetection>>{};
    final cdJson = json['component_detections'] as Map<String, dynamic>?;
    if (cdJson != null) {
      cdJson.forEach((compType, dets) {
        if (dets is List) {
          final list = <ComponentDetection>[];
          for (final d in dets) {
            if (d is Map<String, dynamic>) {
              list.add(ComponentDetection.fromJson(compType, d));
            }
          }
          if (list.isNotEmpty) {
            detsMap[compType] = list;
          }
        }
      });
    }

    return InspectionImage(
      imageId: json['image_id'] as String? ?? '',
      imagePath: json['image_path'] as String? ?? '',
      imageWidth: (json['image_width'] as num?)?.toInt() ?? 5184,
      imageHeight: (json['image_height'] as num?)?.toInt() ?? 3888,
      distanceToTowerM: (json['distance_to_tower_m'] as num?)?.toDouble() ?? 0.0,
      telemetry: json['telemetry'] is Map<String, dynamic>
          ? ImageTelemetry.fromJson(json['telemetry'] as Map<String, dynamic>)
          : null,
      componentDetections: detsMap,
    );
  }

  /// Flat list of all detections in this image
  List<ComponentDetection> get allDetections {
    final list = <ComponentDetection>[];
    componentDetections.values.forEach(list.addAll);
    return list;
  }

  int get missingCotterPinCount =>
      componentDetections['cotter_pin_missing']?.length ?? 0;

  bool get hasDefect => missingCotterPinCount > 0;

  /// Returns the corresponding thermal image path (if DJI zoom shot _Z.JPG)
  String get thermalImagePath {
    if (imagePath.contains('_Z.JPG')) {
      return imagePath.replaceAll('_Z.JPG', '_T.JPG').replaceAll('/image/', '/thermal/');
    }
    return '';
  }

  String get filename {
    return imagePath.split('/').last.split('\\').last;
  }
}

class ComponentDetection {
  final String detectionId;
  final String componentType;
  final double confidence;
  final List<double> bbox; // [x, y, w, h]
  final String status; // 'normal', 'not_assessed', 'defect'
  final dynamic defect;

  ComponentDetection({
    required this.detectionId,
    required this.componentType,
    required this.confidence,
    required this.bbox,
    required this.status,
    required this.defect,
  });

  factory ComponentDetection.fromJson(
      String compType, Map<String, dynamic> json) {
    return ComponentDetection(
      detectionId: json['detection_id'] as String? ?? '',
      componentType: compType,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      bbox: (json['bbox'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [0.0, 0.0, 100.0, 100.0],
      status: json['status'] as String? ?? 'not_assessed',
      defect: json['defect'],
    );
  }

  Rect get rect {
    if (bbox.length >= 4) {
      return Rect.fromLTWH(bbox[0], bbox[1], bbox[2], bbox[3]);
    }
    return Rect.zero;
  }

  bool get isDefect =>
      componentType == 'cotter_pin_missing' ||
      status == 'defect' ||
      defect != null;

  String get displayName {
    switch (componentType) {
      case 'arcing_horn':
        return 'Arcing Horn';
      case 'conductor':
        return 'Conductor';
      case 'corona_ring':
        return 'Corona Ring';
      case 'cotter_pin':
        return 'Cotter Pin';
      case 'cotter_pin_missing':
        return 'Cotter Pin Missing';
      case 'earthing_wire':
        return 'Earthing Wire';
      case 'insulator':
        return 'Insulator';
      case 'jumper_cable':
        return 'Jumper Cable';
      case 'pg_clamp':
        return 'PG Clamp';
      case 'vibration_damper':
        return 'Vibration Damper';
      default:
        return componentType.replaceAll('_', ' ');
    }
  }
}
