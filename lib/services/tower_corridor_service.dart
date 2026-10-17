import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'file_reader_stub.dart'
    if (dart.library.io) 'file_reader_desktop.dart'
    if (dart.library.html) 'file_reader_web.dart';

/// Model representing a tower's transmission corridor endpoints from CSV/Excel
class TowerCorridorInfo {
  final String towerName;
  final String fromSubstation;
  final String fromVillage;
  final String toSubstation;
  final String toVillage;
  final String corridorArrow; // "Meramundali → Mendhasal"
  final String corridorDash;  // "Meramundali – Mendhasal"
  final String fromRaw;
  final String toRaw;

  const TowerCorridorInfo({
    required this.towerName,
    required this.fromSubstation,
    required this.fromVillage,
    required this.toSubstation,
    required this.toVillage,
    required this.corridorArrow,
    required this.corridorDash,
    required this.fromRaw,
    required this.toRaw,
  });
}

/// Service to load and parse C:\flutter_power\tower_from_to.csv
class TowerCorridorService {
  static const String csvPath = r'C:\flutter_power\tower_from_to.csv';
  static const String assetCsvPath = 'assets/data/tower_from_to.csv';

  static const String _defaultCsvContent = '''Tower,From,To
135KV Tower 1,"Meramundali substation - Joragadia village, Anugul","132kV substation (unnamed) - Gundicha Pada village, Dhenkanal"
135KV Tower 2,"Meramundali substation - Joragadia village, Anugul","132kV substation (unnamed) - Gundicha Pada village, Dhenkanal"
220KV Tower 1 (Site A),"Meramundali substation - Joragadia village, Anugul","Bhanjanagar 220/132kV substation - Badapada village, Ganjam"
220KV Tower 2 (Site A),"Meramundali substation - Joragadia village, Anugul","Bhanjanagar 220/132kV substation - Badapada village, Ganjam"
220KV Tower 1 (Site B),"Meramundali substation - Joragadia village, Anugul","Splits at Ambapalas (Dhenkanal): Joda substation, Kendujhar / Duburi (Old) 220/132kV - Gobarghati village, Jajapur"
220KV Tower 2 (Site B),"Meramundali substation - Joragadia village, Anugul","Splits at Ambapalas (Dhenkanal): Joda substation, Kendujhar / Duburi (Old) 220/132kV - Gobarghati village, Jajapur"
400KV Tower 1 (Site A),"Meramundali substation - Joragadia village, Anugul","Duburi (New) 400/220kV substation - Chandia village, Jajapur"
400KV Tower 2 (Site A),"Meramundali substation - Joragadia village, Anugul","Duburi (New) 400/220kV substation - Chandia village, Jajapur"
400KV Tower 1 (Site B),"Meramundali substation - Joragadia village, Anugul","Mendhasal 400/220/132kV substation - Mendhadsal village, Khordha"
400KV Tower 2 (Site B),"Meramundali substation - Joragadia village, Anugul","Mendhasal 400/220/132kV substation - Mendhadsal village, Khordha"''';

  static Map<String, TowerCorridorInfo> _cachedCorridors = parseCsv(_defaultCsvContent);

  /// Loads raw text content from local disk file path with asset fallback
  static Future<String> _loadFileString() async {
    try {
      final diskContent = await readLocalFile(csvPath);
      if (diskContent != null && diskContent.trim().isNotEmpty) {
        return diskContent;
      }
    } catch (e) {
      debugPrint('TowerCorridorService: Disk read error: $e');
    }
    return await rootBundle.loadString(assetCsvPath);
  }

  /// Loads and parses tower_from_to.csv
  static Future<Map<String, TowerCorridorInfo>> loadCorridors() async {
    try {
      final csvString = await _loadFileString();
      final freshMap = parseCsv(csvString);
      if (freshMap.isNotEmpty) {
        _cachedCorridors = freshMap;
      }
      return _cachedCorridors;
    } catch (e) {
      debugPrint('Error loading tower corridor data: $e');
      return _cachedCorridors;
    }
  }

  /// Parses CSV string into a lookup map
  static Map<String, TowerCorridorInfo> parseCsv(String csvString) {
    final map = <String, TowerCorridorInfo>{};
    final lines = const LineSplitter().convert(csvString);
    if (lines.isEmpty) return map;

    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final cols = _splitCsvLine(line);
      if (cols.length >= 3) {
        final towerName = cols[0].trim();
        final fromRaw = cols[1].trim();
        final toRaw = cols[2].trim();

        final fromClean = cleanSubstationName(fromRaw);
        final fromVillage = extractVillageName(fromRaw);
        final toClean = cleanSubstationName(toRaw);
        final toVillage = extractVillageName(toRaw);

        final info = TowerCorridorInfo(
          towerName: towerName,
          fromSubstation: fromClean,
          fromVillage: fromVillage,
          toSubstation: toClean,
          toVillage: toVillage,
          corridorArrow: '$fromClean → $toClean',
          corridorDash: '$fromClean – $toClean',
          fromRaw: fromRaw,
          toRaw: toRaw,
        );

        map[towerName.toLowerCase()] = info;
        final normalized = towerName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
        map[normalized] = info;
      }
    }

    return map;
  }

  /// Robust CSV row tokenizer respecting quotes
  static List<String> _splitCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString());
    return result;
  }

  /// Extracts village and district location from CSV text
  static String extractVillageName(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return '';
    if (text.contains(' - ')) {
      final afterDash = text.split(' - ').last.trim();
      return afterDash.replaceAll(RegExp(r'\s+village\b', caseSensitive: false), '').trim();
    } else if (text.contains('-')) {
      final afterDash = text.split('-').last.trim();
      return afterDash.replaceAll(RegExp(r'\s+village\b', caseSensitive: false), '').trim();
    }
    return '';
  }

  /// Cleans raw text into concise substation name
  static String cleanSubstationName(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return '';

    // Specific well-known matches first
    if (text.contains('Mendhasal') || text.contains('Mendhadsal')) {
      return 'Mendhasal';
    }
    if (text.contains('Duburi (New)')) {
      return 'Duburi (New)';
    }
    if (text.contains('Bhanjanagar')) {
      return 'Bhanjanagar';
    }
    if (text.contains('132kV') || text.contains('unnamed') || text.contains('Gundicha Pada')) {
      return '132kV substation';
    }
    if (text.contains('Joda') || text.contains('Duburi (Old)')) {
      return 'Joda / Duburi (Old)';
    }
    if (text.contains('Meramundali')) {
      return 'Meramundali';
    }

    // Generic fallback for future added rows
    final subMatch = RegExp(
      r'^([A-Za-z0-9\s\(\)]+?)(?:\s+\d+[\/\d]*\s*kV)?\s+substation',
      caseSensitive: false,
    ).firstMatch(text);
    if (subMatch != null) {
      final name = subMatch.group(1)?.trim() ?? '';
      if (name.isNotEmpty && !name.toLowerCase().contains('unnamed')) {
        return name;
      }
    }

    if (text.contains('-')) {
      final afterDash = text.split('-').last.trim();
      final villageMatch = RegExp(
        r'^([A-Za-z0-9\s\(\)]+?)\s+village',
        caseSensitive: false,
      ).firstMatch(afterDash);
      if (villageMatch != null) {
        return villageMatch.group(1)?.trim() ?? afterDash;
      }
    }

    return text.split(' - ').first.replaceAll(RegExp(r'\s+substation.*$', caseSensitive: false), '').trim();
  }

  /// Get corridor info for a tower name or id
  static TowerCorridorInfo? getInfo(String towerNameOrId) {
    final lower = towerNameOrId.toLowerCase();
    if (_cachedCorridors.containsKey(lower)) {
      return _cachedCorridors[lower];
    }
    final normalized = lower.replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (_cachedCorridors.containsKey(normalized)) {
      return _cachedCorridors[normalized];
    }
    for (final entry in _cachedCorridors.entries) {
      if (entry.key.contains('site b') && (lower.contains('site b') || lower.contains('sb'))) {
        if (lower.contains('400') && entry.key.contains('400')) return entry.value;
        if (lower.contains('220') && entry.key.contains('220')) return entry.value;
      }
      if (entry.key.contains('site a') && (lower.contains('site a') || lower.contains('sa'))) {
        if (lower.contains('400') && entry.key.contains('400')) return entry.value;
        if (lower.contains('220') && entry.key.contains('220')) return entry.value;
      }
      if (lower.contains('135') && entry.key.contains('135')) return entry.value;
    }
    return null;
  }
}
