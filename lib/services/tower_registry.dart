/// Tower registry providing unified metadata for all transmission towers.
/// Supports both full tower IDs (e.g. '135KV_Tower_1') and display codes (e.g. 'T01-135KV-SA').
library;

class TowerDefinition {
  final String towerId;
  final String displayCode;
  final String name;
  final String voltage;
  final String lineName;
  final String site;
  final int towerNumber;
  final String surveyDate;
  final DateTime surveyDateTime;
  final String? jsonAssetPath;
  final String? baseImageAsset;
  final String? baseImageFilename;
  final String? frameShownFilename;
  final String? pdfS3Url;
  final double latitude;
  final double longitude;
  final double altitude;
  final int defectCount;
  final bool isCritical;
  final bool hasInspectionData;

  const TowerDefinition({
    required this.towerId,
    required this.displayCode,
    required this.name,
    required this.voltage,
    required this.lineName,
    required this.site,
    required this.towerNumber,
    required this.surveyDate,
    required this.surveyDateTime,
    this.jsonAssetPath,
    this.baseImageAsset,
    this.baseImageFilename,
    this.frameShownFilename,
    this.pdfS3Url,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.defectCount,
    required this.isCritical,
    required this.hasInspectionData,
  });
}

class TowerRegistry {
  static final List<TowerDefinition> towers = [
    // 1. Active Inspected Tower: 400KV Tower 1 (Site B) · 28 Mar 2026 · 9 Critical Deficiencies
    TowerDefinition(
      towerId: '400KV_Tower_1_Site_B',
      displayCode: 'T01-400KV-SB',
      name: '400KV Tower 1 (Site B)',
      voltage: '400 kV',
      lineName: '400 kV line',
      site: 'Site B',
      towerNumber: 1,
      surveyDate: '28 Mar 2026',
      surveyDateTime: DateTime(2026, 3, 28),
      jsonAssetPath: 'assets/data/inspection_1_s3.json',
      baseImageAsset: 'assets/images/DJI_20260328161505_0088_S_seg01_frame_01180.jpg',
      baseImageFilename: 'DJI_20260328161505_0088_S_seg01_frame_01180.jpg',
      frameShownFilename: 'DJI_20260328161505_0088_S_seg01_frame_01180.jpg',
      pdfS3Url:
          'https://powerlinee.s3.ap-south-1.amazonaws.com/data/400KV_Tower_1_Site_B_inspection_report_reviewed+1.pdf',
      latitude: 20.805013,
      longitude: 85.284934,
      altitude: 43.881,
      defectCount: 9,
      isCritical: true,
      hasInspectionData: true,
    ),

    // 2. 135KV Tower 1 (Site A) · 29 Mar 2026 · 0 Defects
    TowerDefinition(
      towerId: '135KV_Tower_1',
      displayCode: 'T01-135KV-SA',
      name: '135KV Tower 1',
      voltage: '135 kV',
      lineName: '135 kV line',
      site: 'Site A',
      towerNumber: 1,
      surveyDate: '29 Mar 2026',
      surveyDateTime: DateTime(2026, 3, 29),
      jsonAssetPath: 'assets/data/inspection_t1_135kv.json',
      baseImageAsset: 'assets/images/135_t1.jpg',
      baseImageFilename: '135_t1.jpg',
      frameShownFilename: 'frame_00969.jpg',
      pdfS3Url:
          'https://powerlinee.s3.ap-south-1.amazonaws.com/data/RAW/135KV_Tower_1/135KV_Tower_1_inspection_report_inline.pdf',
      latitude: 20.8258324,
      longitude: 85.2636364,
      altitude: 66.332,
      defectCount: 0,
      isCritical: false,
      hasInspectionData: true,
    ),

    // 3. 135KV Tower 2 (Site A) · 29 Mar 2026 · 0 Defects
    TowerDefinition(
      towerId: '135KV_Tower_2',
      displayCode: 'T02-135KV-SA',
      name: '135KV Tower 2',
      voltage: '135 kV',
      lineName: '135 kV line',
      site: 'Site A',
      towerNumber: 2,
      surveyDate: '29 Mar 2026',
      surveyDateTime: DateTime(2026, 3, 29),
      jsonAssetPath: 'assets/data/inspection_t2_135kv.json',
      baseImageAsset: 'assets/images/135t2.jpg',
      baseImageFilename: '135t2.jpg',
      frameShownFilename: 'frame_00063.jpg',
      pdfS3Url:
          'https://powerlinee.s3.ap-south-1.amazonaws.com/data/RAW/135KV_Tower_2/135KV_Tower_2_inspection_report_inline.pdf',
      latitude: 20.8236093,
      longitude: 85.2655857,
      altitude: 79.012,
      defectCount: 0,
      isCritical: false,
      hasInspectionData: true,
    ),

    // 4. 220KV Tower 1 (Site A) · 29 Mar 2026 · 0 Defects
    TowerDefinition(
      towerId: '220KV_Tower_1_Site_A',
      displayCode: 'T01-220KV-SA',
      name: '220KV Tower 1 (Site A)',
      voltage: '220 kV',
      lineName: '220 kV line',
      site: 'Site A',
      towerNumber: 1,
      surveyDate: '29 Mar 2026',
      surveyDateTime: DateTime(2026, 3, 29),
      jsonAssetPath: 'assets/data/inspection_t1_sa_220kv.json',
      baseImageAsset: 'assets/images/220t1sa.jpg',
      baseImageFilename: '220t1sa.jpg',
      frameShownFilename: 'frame_00506.jpg',
      pdfS3Url:
          'https://powerlinee.s3.ap-south-1.amazonaws.com/data/RAW/220KV_Tower_1_Site_A/220KV_Tower_1_Site_A_inspection_report_inline.pdf',
      latitude: 20.8047414,
      longitude: 85.2087025,
      altitude: 42.254,
      defectCount: 0,
      isCritical: false,
      hasInspectionData: true,
    ),

    // 5. 220KV Tower 2 (Site A) · 29 Mar 2026 · 0 Defects
    TowerDefinition(
      towerId: '220KV_Tower_2_Site_A',
      displayCode: 'T02-220KV-SA',
      name: '220KV Tower 2 (Site A)',
      voltage: '220 kV',
      lineName: '220 kV line',
      site: 'Site A',
      towerNumber: 2,
      surveyDate: '29 Mar 2026',
      surveyDateTime: DateTime(2026, 3, 29),
      jsonAssetPath: 'assets/data/inspection_t2_sa_220kv.json',
      baseImageAsset: 'assets/images/220t2sa.jpg',
      baseImageFilename: '220t2sa.jpg',
      frameShownFilename: 'frame_00946.jpg',
      pdfS3Url:
          'https://powerlinee.s3.ap-south-1.amazonaws.com/data/RAW/220KV_Tower_2_Site_A/220KV_Tower_2_Site_A_inspection_report_inline.pdf',
      latitude: 20.801557,
      longitude: 85.2082728,
      altitude: 53.802,
      defectCount: 0,
      isCritical: false,
      hasInspectionData: true,
    ),

    // 6. 220KV Tower 1 (Site B) · 29 Mar 2026 · 0 Defects
    TowerDefinition(
      towerId: '220KV_Tower_1_Site_B',
      displayCode: 'T01-220KV-SB',
      name: '220KV Tower 1 (Site B)',
      voltage: '220 kV',
      lineName: '220 kV line',
      site: 'Site B',
      towerNumber: 1,
      surveyDate: '29 Mar 2026',
      surveyDateTime: DateTime(2026, 3, 29),
      jsonAssetPath: 'assets/data/inspection_t1_sb_220kv.json',
      baseImageAsset: 'assets/images/220t1sb.jpg',
      baseImageFilename: '220t1sb.jpg',
      frameShownFilename: 'frame_01342.jpg',
      pdfS3Url:
          'https://powerlinee.s3.ap-south-1.amazonaws.com/data/RAW/220KV_Tower_1_Site_B/220KV_Tower_1_Site_B_inspection_report_inline.pdf',
      latitude: 20.8359774,
      longitude: 85.25813,
      altitude: 27.787,
      defectCount: 0,
      isCritical: false,
      hasInspectionData: true,
    ),

    // 7. 220KV Tower 2 (Site B) · 29 Mar 2026 · 0 Defects
    TowerDefinition(
      towerId: '220KV_Tower_2_Site_B',
      displayCode: 'T02-220KV-SB',
      name: '220KV Tower 2 (Site B)',
      voltage: '220 kV',
      lineName: '220 kV line',
      site: 'Site B',
      towerNumber: 2,
      surveyDate: '29 Mar 2026',
      surveyDateTime: DateTime(2026, 3, 29),
      jsonAssetPath: 'assets/data/inspection_t2_sb_220kv.json',
      baseImageAsset: 'assets/images/220t2sb.jpg',
      baseImageFilename: '220t2sb.jpg',
      frameShownFilename: 'frame_00138.jpg',
      pdfS3Url:
          'https://powerlinee.s3.ap-south-1.amazonaws.com/data/RAW/220KV_Tower_2_Site_B/220KV_Tower_2_Site_B_inspection_report_inline.pdf',
      latitude: 20.8333576,
      longitude: 85.2554527,
      altitude: 50.102,
      defectCount: 0,
      isCritical: false,
      hasInspectionData: true,
    ),

    // 8. 400KV Tower 1 (Site A) · 20 Apr 2026 · Not inspected
    TowerDefinition(
      towerId: '400KV_Tower_1_Site_A',
      displayCode: 'T01-400KV-SA',
      name: '400KV Tower 1 (Site A)',
      voltage: '400 kV',
      lineName: '400 kV line',
      site: 'Site A',
      towerNumber: 1,
      surveyDate: '20 Apr 2026',
      surveyDateTime: DateTime(2026, 4, 20),
      latitude: 20.824616,
      longitude: 85.267662,
      altitude: 87.607,
      defectCount: 0,
      isCritical: false,
      hasInspectionData: false,
    ),

    // 9. 400KV Tower 2 (Site A) · 20 Apr 2026 · Not inspected
    TowerDefinition(
      towerId: '400KV_Tower_2_Site_A',
      displayCode: 'T02-400KV-SA',
      name: '400KV Tower 2 (Site A)',
      voltage: '400 kV',
      lineName: '400 kV line',
      site: 'Site A',
      towerNumber: 2,
      surveyDate: '20 Apr 2026',
      surveyDateTime: DateTime(2026, 4, 20),
      latitude: 20.822193,
      longitude: 85.268523,
      altitude: 64.243,
      defectCount: 0,
      isCritical: false,
      hasInspectionData: false,
    ),

    // 10. 400KV Tower 2 (Site B) · 28 Mar 2026 · Not inspected
    TowerDefinition(
      towerId: '400KV_Tower_2_Site_B',
      displayCode: 'T02-400KV-SB',
      name: '400KV Tower 2 (Site B)',
      voltage: '400 kV',
      lineName: '400 kV line',
      site: 'Site B',
      towerNumber: 2,
      surveyDate: '28 Mar 2026',
      surveyDateTime: DateTime(2026, 3, 28),
      latitude: 20.802656,
      longitude: 85.288363,
      altitude: 49.841,
      defectCount: 0,
      isCritical: false,
      hasInspectionData: false,
    ),
  ];

  /// Look up a tower definition by its ID or display code
  static TowerDefinition? getTower(String? idOrCode) {
    if (idOrCode == null || idOrCode.isEmpty) {
      return towers.firstWhere((t) => t.towerId == '400KV_Tower_1_Site_B');
    }
    final normalized = idOrCode.trim();
    for (final t in towers) {
      if (t.towerId.toLowerCase() == normalized.toLowerCase() ||
          t.displayCode.toLowerCase() == normalized.toLowerCase() ||
          t.name.toLowerCase() == normalized.toLowerCase()) {
        return t;
      }
    }
    return null;
  }

  /// Check whether a tower has an inspection JSON dataset bundled
  static bool hasData(String? idOrCode) {
    final t = getTower(idOrCode);
    return t != null && t.hasInspectionData;
  }

  /// All base tower overview image asset paths
  static List<String> get baseImageFilenames => [
        'DJI_20260328161505_0088_S_seg01_frame_01180.jpg',
        '135_t1.jpg',
        '135t2.jpg',
        '220t1sa.jpg',
        '220t2sa.jpg',
        '220t1sb.jpg',
        '220t2sb.jpg',
      ];
}
