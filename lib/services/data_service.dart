import 'dart:convert';
import 'package:flutter/services.dart';
import '../config/app_config.dart';
import '../models/inspection_model.dart';
import 'tower_registry.dart';

class DataService {
  static final Map<String, InspectionData> _cache = {};

  /// Loads the inspection JSON data for a specific tower (or active default)
  static Future<InspectionData> loadInspectionData([String? towerIdOrCode]) async {
    final def = TowerRegistry.getTower(towerIdOrCode);
    final towerKey = def?.towerId ?? AppConfig.defaultTowerId;

    if (_cache.containsKey(towerKey)) {
      return _cache[towerKey]!;
    }

    final assetPath = def?.jsonAssetPath ?? AppConfig.assetInspectionJsonPath;

    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final dynamic decoded = json.decode(jsonString);
      if (decoded is Map<String, dynamic>) {
        final data = InspectionData.fromJson(decoded);
        _cache[towerKey] = data;
        return data;
      }
      throw Exception('Unexpected JSON format in $assetPath');
    } catch (e) {
      throw Exception('Failed to load inspection data for $towerKey: $e');
    }
  }

  /// Synchronously returns cached data for the default tower or first loaded
  static InspectionData? get cachedData =>
      _cache[AppConfig.defaultTowerId] ?? (_cache.isNotEmpty ? _cache.values.first : null);

  /// Synchronously returns cached data for a specific tower
  static InspectionData? getCachedData(String? towerIdOrCode) {
    final def = TowerRegistry.getTower(towerIdOrCode);
    final towerKey = def?.towerId ?? AppConfig.defaultTowerId;
    return _cache[towerKey];
  }

  /// Preloads all available tower datasets in background
  static Future<void> preloadAll() async {
    for (final tower in TowerRegistry.towers) {
      if (tower.hasInspectionData && tower.jsonAssetPath != null) {
        try {
          await loadInspectionData(tower.towerId);
        } catch (_) {}
      }
    }
  }
}
