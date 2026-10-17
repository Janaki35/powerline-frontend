import 'dart:convert';
import 'package:flutter/services.dart';
import '../config/app_config.dart';
import '../models/inspection_model.dart';

class DataService {
  static InspectionData? _cachedData;

  /// Loads the inspection JSON data (from asset bundle or fallback)
  static Future<InspectionData> loadInspectionData() async {
    if (_cachedData != null) {
      return _cachedData!;
    }

    try {
      final jsonString =
          await rootBundle.loadString(AppConfig.assetInspectionJsonPath);
      final dynamic decoded = json.decode(jsonString);
      if (decoded is Map<String, dynamic>) {
        _cachedData = InspectionData.fromJson(decoded);
        return _cachedData!;
      }
      throw Exception('Unexpected JSON format');
    } catch (e) {
      throw Exception('Failed to load inspection data: $e');
    }
  }

  /// Synchronously returns cached data if already loaded
  static InspectionData? get cachedData => _cachedData;
}
