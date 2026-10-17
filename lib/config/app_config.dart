import 'package:flutter/foundation.dart';

/// Configuration for KnoGrid application.
/// Allows setting local data paths and server URLs easily.
class AppConfig {
  /// Base local directory where RAW inspection data resides on Windows
  static const String rawDataLocalPath = r'c:\flutter_power\data';

  /// Base URL of the local image server (used for Flutter Web and optional fast crops)
  static const String imageServerBaseUrl = 'http://localhost:8085';

  /// Relative path to inspection JSON inside Flutter assets
  static const String assetInspectionJsonPath =
      'assets/data/inspection_1_s3.json';

  /// Relative path to tower info JSON inside Flutter assets
  static const String assetTowerInfoPath = 'assets/data/tower_info.json';

  /// Active Tower ID for this release
  static const String defaultTowerId = '400KV_Tower_1_Site_B';
  static const String defaultTowerCode = 'T01-400KV-SB';

  /// Asset path for base tower structure image (bundled for reliable deployment)
  static const String baseTowerImageAsset =
      'assets/images/DJI_20260328161505_0088_S_seg01_frame_01180.jpg';
  static const String baseTowerImageFilename =
      'DJI_20260328161505_0088_S_seg01_frame_01180.jpg';

  /// Check whether we are running on web
  static bool get isWeb => kIsWeb;
}
