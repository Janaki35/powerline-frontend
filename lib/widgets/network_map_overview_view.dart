import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../models/inspection_model.dart';
import '../services/data_service.dart';
import '../services/image_service.dart';
import '../services/grid_data_service.dart';
import '../services/tower_corridor_service.dart';
import '../services/tower_registry.dart';
import 'transmission_tower_icon.dart';

/// Lightweight representation of a Transmission Tower mapped from KML
class MapTower {
  final String id;
  final String name;
  final String voltage;
  final String lineName;
  final String site;
  final int towerNumber;
  final LatLng location;
  final double altitude;
  final String spanToNext;
  final String partnerTowerId;
  final LatLng partnerLocation;
  final String segmentLabel;
  final bool isCritical;
  final bool isInspected;
  final String surveyDate;
  final DateTime surveyDateTime;
  final int defectCount;

  const MapTower({
    required this.id,
    required this.name,
    required this.voltage,
    required this.lineName,
    required this.site,
    required this.towerNumber,
    required this.location,
    required this.altitude,
    required this.spanToNext,
    required this.partnerTowerId,
    required this.partnerLocation,
    required this.segmentLabel,
    this.isCritical = false,
    this.isInspected = false,
    required this.surveyDate,
    required this.surveyDateTime,
    this.defectCount = 0,
  });

  bool get isNormal => isInspected && !isCritical;
  String get conditionText {
    if (!isInspected) return 'Not inspected';
    if (isCritical) return 'Critical condition';
    return 'Normal condition';
  }
}

class NetworkMapOverviewView extends StatefulWidget {
  final Tower tower;
  final VoidCallback onLogout;
  final Function(Circuit? circuit, Phase? phase, [String? towerId]) onOpenInspection;
  final String? initialDate;
  final String? initialVoltage;
  final String? initialTowerId;
  final String? initialCorridorTop;
  final String? initialCorridorBottom;
  final ValueChanged<String>? onDateChanged;
  final ValueChanged<String>? onVoltageChanged;
  final ValueChanged<String>? onTowerChanged;
  final void Function(String? top, String? bottom)? onCorridorChanged;
  final bool returnFromInspection;

  const NetworkMapOverviewView({
    super.key,
    required this.tower,
    required this.onLogout,
    required this.onOpenInspection,
    this.initialDate,
    this.initialVoltage,
    this.initialTowerId,
    this.initialCorridorTop,
    this.initialCorridorBottom,
    this.returnFromInspection = false,
    this.onDateChanged,
    this.onVoltageChanged,
    this.onTowerChanged,
    this.onCorridorChanged,
  });

  @override
  State<NetworkMapOverviewView> createState() => _NetworkMapOverviewViewState();
}

class _NetworkMapOverviewViewState extends State<NetworkMapOverviewView> {
  final GlobalKey _mapKey = GlobalKey();
  final MapController _mapController = MapController();

  // 10 Towers from transmission_towers.kml matching Penpot dates and corridors
  static final List<MapTower> _allMapTowers = [
    // 1. 400KV Line - Site A (Surveyed on latest date 20 Apr 2026 · Not inspected · 2.png)
    MapTower(
      id: 'T01-400KV-SA',
      name: '400KV Tower 1 (Site A)',
      voltage: '400 kV',
      lineName: '400 kV line',
      site: 'Site A',
      towerNumber: 1,
      location: const LatLng(20.824616, 85.267662),
      altitude: 87.607,
      spanToNext: '284 m to T02',
      partnerTowerId: 'T02-400KV-SA',
      partnerLocation: const LatLng(20.822193, 85.268523),
      segmentLabel: '400 kV · Site A · 284 m',
      isCritical: false,
      isInspected: false,
      surveyDate: '20 Apr 2026',
      surveyDateTime: DateTime(2026, 4, 20),
      defectCount: 0,
    ),
    MapTower(
      id: 'T02-400KV-SA',
      name: '400KV Tower 2 (Site A)',
      voltage: '400 kV',
      lineName: '400 kV line',
      site: 'Site A',
      towerNumber: 2,
      location: const LatLng(20.822193, 85.268523),
      altitude: 64.243,
      spanToNext: '284 m to T01',
      partnerTowerId: 'T01-400KV-SA',
      partnerLocation: const LatLng(20.824616, 85.267662),
      segmentLabel: '400 kV · Site A · 284 m',
      isCritical: false,
      isInspected: false,
      surveyDate: '20 Apr 2026',
      surveyDateTime: DateTime(2026, 4, 20),
      defectCount: 0,
    ),

    // 2. 29 Mar 2026 Survey: 135KV Line Site A, 220KV Line Site A & Site B (6 inspected towers · 0 defects / Normal)
    MapTower(
      id: 'T01-135KV-SA',
      name: '135KV Tower 1',
      voltage: '135 kV',
      lineName: '135 kV line',
      site: 'Site A',
      towerNumber: 1,
      location: const LatLng(20.8258324, 85.2636364),
      altitude: 66.332,
      spanToNext: '330 m to T02',
      partnerTowerId: 'T02-135KV-SA',
      partnerLocation: const LatLng(20.8236093, 85.2655857),
      segmentLabel: '135 kV · 330 m',
      isCritical: false,
      isInspected: true,
      surveyDate: '29 Mar 2026',
      surveyDateTime: DateTime(2026, 3, 29),
      defectCount: 0,
    ),
    MapTower(
      id: 'T02-135KV-SA',
      name: '135KV Tower 2',
      voltage: '135 kV',
      lineName: '135 kV line',
      site: 'Site A',
      towerNumber: 2,
      location: const LatLng(20.8236093, 85.2655857),
      altitude: 79.012,
      spanToNext: '330 m to T01',
      partnerTowerId: 'T01-135KV-SA',
      partnerLocation: const LatLng(20.8258324, 85.2636364),
      segmentLabel: '135 kV · 330 m',
      isCritical: false,
      isInspected: true,
      surveyDate: '29 Mar 2026',
      surveyDateTime: DateTime(2026, 3, 29),
      defectCount: 0,
    ),
    MapTower(
      id: 'T01-220KV-SA',
      name: '220KV Tower 1 (Site A)',
      voltage: '220 kV',
      lineName: '220 kV line',
      site: 'Site A',
      towerNumber: 1,
      location: const LatLng(20.8047414, 85.2087025),
      altitude: 42.254,
      spanToNext: '363 m to T02',
      partnerTowerId: 'T02-220KV-SA',
      partnerLocation: const LatLng(20.801557, 85.2082728),
      segmentLabel: '220 kV · Site A · 363 m',
      isCritical: false,
      isInspected: true,
      surveyDate: '29 Mar 2026',
      surveyDateTime: DateTime(2026, 3, 29),
      defectCount: 0,
    ),
    MapTower(
      id: 'T02-220KV-SA',
      name: '220KV Tower 2 (Site A)',
      voltage: '220 kV',
      lineName: '220 kV line',
      site: 'Site A',
      towerNumber: 2,
      location: const LatLng(20.801557, 85.2082728),
      altitude: 53.802,
      spanToNext: '363 m to T01',
      partnerTowerId: 'T01-220KV-SA',
      partnerLocation: const LatLng(20.8047414, 85.2087025),
      segmentLabel: '220 kV · Site A · 363 m',
      isCritical: false,
      isInspected: true,
      surveyDate: '29 Mar 2026',
      surveyDateTime: DateTime(2026, 3, 29),
      defectCount: 0,
    ),
    MapTower(
      id: 'T01-220KV-SB',
      name: '220KV Tower 1 (Site B)',
      voltage: '220 kV',
      lineName: '220 kV line',
      site: 'Site B',
      towerNumber: 1,
      location: const LatLng(20.8359774, 85.258130),
      altitude: 27.787,
      spanToNext: '400 m to T02',
      partnerTowerId: 'T02-220KV-SB',
      partnerLocation: const LatLng(20.8333576, 85.2554527),
      segmentLabel: '220 kV · Site B · 400 m',
      isCritical: false,
      isInspected: true,
      surveyDate: '29 Mar 2026',
      surveyDateTime: DateTime(2026, 3, 29),
      defectCount: 0,
    ),
    MapTower(
      id: 'T02-220KV-SB',
      name: '220KV Tower 2 (Site B)',
      voltage: '220 kV',
      lineName: '220 kV line',
      site: 'Site B',
      towerNumber: 2,
      location: const LatLng(20.8333576, 85.2554527),
      altitude: 50.102,
      spanToNext: '400 m to T01',
      partnerTowerId: 'T01-220KV-SB',
      partnerLocation: const LatLng(20.8359774, 85.258130),
      segmentLabel: '220 kV · Site B · 400 m',
      isCritical: false,
      isInspected: true,
      surveyDate: '29 Mar 2026',
      surveyDateTime: DateTime(2026, 3, 29),
      defectCount: 0,
    ),

    // 3. 28 Mar 2026 Survey: 400KV Line Site B (T01 Critical Red & T02 Uninspected Grey · 2_sidebar.png)
    MapTower(
      id: 'T01-400KV-SB',
      name: '400KV Tower 1 (Site B)',
      voltage: '400 kV',
      lineName: '400 kV line',
      site: 'Site B',
      towerNumber: 1,
      location: const LatLng(20.805013, 85.284934),
      altitude: 43.881,
      spanToNext: '442 m to T02',
      partnerTowerId: 'T02-400KV-SB',
      partnerLocation: const LatLng(20.802656, 85.288363),
      segmentLabel: '400 kV · Site B · 442 m',
      isCritical: true,
      isInspected: true,
      surveyDate: '28 Mar 2026',
      surveyDateTime: DateTime(2026, 3, 28),
      defectCount: 9,
    ),
    MapTower(
      id: 'T02-400KV-SB',
      name: '400KV Tower 2 (Site B)',
      voltage: '400 kV',
      lineName: '400 kV line',
      site: 'Site B',
      towerNumber: 2,
      location: const LatLng(20.802656, 85.288363),
      altitude: 49.841,
      spanToNext: '442 m to T01',
      partnerTowerId: 'T01-400KV-SB',
      partnerLocation: const LatLng(20.805013, 85.284934),
      segmentLabel: '400 kV · Site B · 442 m',
      isCritical: false,
      isInspected: false,
      surveyDate: '28 Mar 2026',
      surveyDateTime: DateTime(2026, 3, 28),
      defectCount: 0,
    ),
  ];

  // Initial Default: 20 Apr 2026 (Latest date towers displayed after login)
  String _selectedDate = '20 Apr 2026';
  String _selectedVoltage = 'All voltages';
  String? _selectedCorridorTop;
  String? _selectedCorridorBottom;
  LatLng _currentCenter = const LatLng(20.823400, 85.268100);
  double _currentZoom = 16.5;
  double _currentRotation = 0.0;

  Offset? _mouseRotateStartPos;
  double _mouseRotateStartAngle = 0.0;

  bool _isTableView = false;
  bool _isSidebarOpen = false;
  int _activeTab = 0; // 0: Overview, 1: Defects, 2: History

  late MapTower _selectedTower;

  bool _isSatellite = false;
  bool _showBaseMapPopover = false;
  bool _showInfoPopover = false;

  bool _isGridActive = false;
  bool _isLoadingGrid = false;
  GridData? _gridData;
  GridRoute? _selectedGridRoute;
  GridSubstation? _selectedGridSubstation;

  bool _showCalendarDropdown = false;
  bool _showVoltageDropdown = false;
  String? _expandedVoltageCategory;
  DateTime _calendarDisplayMonth = DateTime(2026, 4, 1);
  bool _showYearDropdown = false;
  StreamSubscription<MapEvent>? _mapEventSub;

  final GlobalKey _calendarPopoverKey = GlobalKey();
  final GlobalKey _calendarButtonKey = GlobalKey();
  final GlobalKey _voltagePopoverKey = GlobalKey();
  final GlobalKey _voltageButtonKey = GlobalKey();
  final GlobalKey _baseMapPopoverKey = GlobalKey();
  final GlobalKey _baseMapButtonKey = GlobalKey();
  final GlobalKey _infoPopoverKey = GlobalKey();
  final GlobalKey _infoButtonKey = GlobalKey();

  bool _isPointerInsideKey(GlobalKey? key, Offset position) {
    if (key == null) return false;
    final ctx = key.currentContext;
    if (ctx == null || !ctx.mounted) return false;
    final box = ctx.findRenderObject();
    if (box is RenderBox && box.hasSize && box.attached) {
      try {
        final origin = box.localToGlobal(Offset.zero);
        final rect = origin & box.size;
        return rect.contains(position);
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  void _handleGlobalPointerDown(PointerDownEvent event) {
    bool stateChanged = false;

    if (_showCalendarDropdown) {
      final insideCalendar = _isPointerInsideKey(_calendarPopoverKey, event.position);
      final insideButton = _isPointerInsideKey(_calendarButtonKey, event.position);
      if (!insideCalendar && !insideButton) {
        _showCalendarDropdown = false;
        _showYearDropdown = false;
        stateChanged = true;
      }
    }

    if (_showVoltageDropdown) {
      final insideVoltage = _isPointerInsideKey(_voltagePopoverKey, event.position);
      final insideButton = _isPointerInsideKey(_voltageButtonKey, event.position);
      if (!insideVoltage && !insideButton) {
        _showVoltageDropdown = false;
        stateChanged = true;
      }
    }

    if (_showBaseMapPopover) {
      final insidePopover = _isPointerInsideKey(_baseMapPopoverKey, event.position);
      final insideButton = _isPointerInsideKey(_baseMapButtonKey, event.position);
      if (!insidePopover && !insideButton) {
        _showBaseMapPopover = false;
        stateChanged = true;
      }
    }

    if (_showInfoPopover) {
      final insidePopover = _isPointerInsideKey(_infoPopoverKey, event.position);
      final insideButton = _isPointerInsideKey(_infoButtonKey, event.position);
      if (!insidePopover && !insideButton) {
        _showInfoPopover = false;
        stateChanged = true;
      }
    }

    if (stateChanged) {
      setState(() {});
    }
  }

  Future<void> _toggleGrid() async {
    if (!_isGridActive) {
      setState(() {
        _isLoadingGrid = true;
      });
      try {
        final data = await GridDataService.loadGridData();
        setState(() {
          _gridData = data;
          _isGridActive = true;
          _isLoadingGrid = false;
          _showCalendarDropdown = false;
          _showVoltageDropdown = false;
          // Do NOT reset zoom level or move map - remain at the current tower zoom level and position
        });
      } catch (e) {
        setState(() {
          _isLoadingGrid = false;
        });
        debugPrint('Error loading grid data: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load grid data: $e')),
          );
        }
      }
    } else {
      setState(() {
        _isGridActive = false;
        _selectedGridRoute = null;
        _selectedGridSubstation = null;
        _showCalendarDropdown = false;
        _showVoltageDropdown = false;
      });
      // Do NOT change zoom level or move map when toggling OFF - remain at the current zoom level
    }
  }

  @override
  void initState() {
    super.initState();
    TowerCorridorService.loadCorridors().then((_) {
      if (mounted) setState(() {});
    });
    // Synchronize active inspected tower (T01-400KV-SB) from JSON inspection data safely
    _syncTowerStatus();

    // Restore preserved date, voltage, and tower selections from AppState
    if (widget.initialDate != null && widget.initialDate!.isNotEmpty) {
      _selectedDate = widget.initialDate!;
    }
    if (widget.initialVoltage != null && widget.initialVoltage!.isNotEmpty) {
      _selectedVoltage = widget.initialVoltage!;
    }
    if (widget.initialCorridorTop != null) {
      _selectedCorridorTop = widget.initialCorridorTop;
    }
    if (widget.initialCorridorBottom != null) {
      _selectedCorridorBottom = widget.initialCorridorBottom;
    }

    if (widget.returnFromInspection && widget.initialTowerId != null && widget.initialTowerId!.isNotEmpty) {
      _focusOnTower(widget.initialTowerId!);
    } else {
      // Find towers matching the initial active date and voltage
      final matchingTowers = _allMapTowers.where((t) =>
          (_selectedDate == 'All dates' || t.surveyDate == _selectedDate) &&
          (_selectedVoltage == 'All voltages' || t.voltage == _selectedVoltage)).toList();

      if (widget.initialTowerId != null && widget.initialTowerId!.isNotEmpty) {
        final match = matchingTowers.where((t) => t.id == widget.initialTowerId);
        if (match.isNotEmpty) {
          _selectedTower = match.first;
        } else if (matchingTowers.isNotEmpty) {
          _selectedTower = matchingTowers.first;
        } else {
          _selectedTower = _allMapTowers.firstWhere((t) => t.id == 'T01-400KV-SB');
        }
      } else if (matchingTowers.isNotEmpty) {
        _selectedTower = matchingTowers.firstWhere((t) => t.isInspected, orElse: () => matchingTowers.first);
      } else {
        _selectedTower = _allMapTowers.firstWhere((t) => t.id == 'T01-400KV-SB');
      }

      // Set camera center and zoom based on the active selected voltage and date
      if (_selectedVoltage != 'All voltages') {
        if (_selectedVoltage == '135 kV') {
          _currentCenter = const LatLng(20.824721, 85.264611);
          _currentZoom = 16.2;
        } else if (_selectedVoltage == '400 kV') {
          final isSiteAOnly = matchingTowers.every((t) => t.site == 'Site A' || t.id.contains('SA'));
          final isSiteBOnly = matchingTowers.every((t) => t.site == 'Site B' || t.id.contains('SB'));
          if (isSiteAOnly || _selectedDate == '20 Apr 2026') {
            _currentCenter = const LatLng(20.823400, 85.268100);
            _currentZoom = 16.5;
          } else if (isSiteBOnly || _selectedDate == '28 Mar 2026') {
            _currentCenter = const LatLng(20.803800, 85.286600);
            _currentZoom = 16.0;
          } else {
            _currentCenter = const LatLng(20.813600, 85.277300);
            _currentZoom = 14.5;
          }
        } else if (_selectedVoltage == '220 kV') {
          final isSiteAOnly = matchingTowers.every((t) => t.site == 'Site A' || t.id.contains('SA'));
          final isSiteBOnly = matchingTowers.every((t) => t.site == 'Site B' || t.id.contains('SB'));
          if (isSiteAOnly) {
            _currentCenter = const LatLng(20.803149, 85.208488);
            _currentZoom = 16.0;
          } else if (isSiteBOnly) {
            _currentCenter = const LatLng(20.834668, 85.256791);
            _currentZoom = 16.0;
          } else {
            _currentCenter = const LatLng(20.823800, 85.267000);
            _currentZoom = 15.0;
          }
        } else if (matchingTowers.isNotEmpty) {
          _currentCenter = matchingTowers.first.location;
          _currentZoom = 16.0;
        }
        if (matchingTowers.isNotEmpty) {
          final info = TowerCorridorService.getInfo(matchingTowers.first.name);
          final arrow = info?.corridorArrow ?? '${matchingTowers.first.site} Line';
          final from = arrow.contains(' → ') ? arrow.split(' → ').first.trim() : (info?.fromSubstation ?? 'Meramundali');
          final to = arrow.contains(' → ') ? arrow.split(' → ').last.trim() : (info?.toSubstation ?? matchingTowers.first.site);
          _selectedCorridorTop = '$_selectedVoltage · $from →';
          _selectedCorridorBottom = to;
        }
      } else if (_selectedDate == '20 Apr 2026') {
        _currentCenter = const LatLng(20.823400, 85.268100);
        _currentZoom = 16.5;
      } else if (_selectedDate == '16 Apr 2026') {
        _currentCenter = const LatLng(20.829000, 85.259000);
        _currentZoom = 15.0;
      } else if (_selectedDate == '28 Mar 2026') {
        _currentCenter = const LatLng(20.803800, 85.286600);
        _currentZoom = 16.0;
      } else if (_selectedDate == '29 Mar 2026') {
        _currentCenter = const LatLng(20.817900, 85.235900);
        _currentZoom = 14.0;
      } else if (_selectedDate == '12 Apr 2026') {
        _currentCenter = const LatLng(20.803100, 85.208485);
        _currentZoom = 16.5;
      } else {
        _currentCenter = const LatLng(20.817900, 85.235900);
        _currentZoom = 14.0;
      }
    }
    _mapEventSub = _mapController.mapEventStream.listen((event) {
      if (mounted && (event.camera.rotation - _currentRotation).abs() > 0.01) {
        setState(() {
          _currentRotation = event.camera.rotation;
        });
      }
    });
  }

  @override
  void dispose() {
    _mapEventSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(NetworkMapOverviewView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTowerStatus();
    if (widget.returnFromInspection &&
        widget.initialTowerId != null &&
        widget.initialTowerId!.isNotEmpty &&
        (!oldWidget.returnFromInspection || widget.initialTowerId != oldWidget.initialTowerId)) {
      _focusOnTower(widget.initialTowerId!);
    }
  }

  void _focusOnTower(String towerId) {
    final towerDef = TowerRegistry.getTower(towerId);
    final match = _allMapTowers.firstWhere(
      (t) => t.id == towerId ||
          (towerDef != null && (t.id == towerDef.displayCode || t.name == towerDef.name)),
      orElse: () => _allMapTowers.firstWhere((t) => t.id == 'T01-400KV-SB'),
    );
    _selectedTower = match;
    _selectedDate = match.surveyDate;

    // If a voltage/corridor was selected before going to inspection, preserve it!
    final preservedVoltage = (widget.initialVoltage != null && widget.initialVoltage!.isNotEmpty)
        ? widget.initialVoltage!
        : _selectedVoltage;
    if (preservedVoltage != 'All voltages') {
      _selectedVoltage = preservedVoltage;
      if (widget.initialCorridorTop != null && widget.initialCorridorBottom != null) {
        _selectedCorridorTop = widget.initialCorridorTop;
        _selectedCorridorBottom = widget.initialCorridorBottom;
      } else if (_selectedCorridorTop == null || _selectedCorridorBottom == null) {
        final info = TowerCorridorService.getInfo(match.name);
        final arrow = info?.corridorArrow ?? '${match.site} Line';
        final from = arrow.contains(' → ') ? arrow.split(' → ').first.trim() : (info?.fromSubstation ?? 'Meramundali');
        final to = arrow.contains(' → ') ? arrow.split(' → ').last.trim() : (info?.toSubstation ?? match.site);
        _selectedCorridorTop = '$_selectedVoltage · $from →';
        _selectedCorridorBottom = to;
      }
    } else {
      _selectedVoltage = 'All voltages';
      _selectedCorridorTop = null;
      _selectedCorridorBottom = null;
    }
    _isSidebarOpen = false; // Right bar CLOSED as requested

    final partner = _allMapTowers.firstWhere(
      (t) => t.id == match.partnerTowerId,
      orElse: () => match,
    );
    final midLat = (match.location.latitude + partner.location.latitude) / 2.0;
    final midLng = (match.location.longitude + partner.location.longitude) / 2.0;
    _currentCenter = LatLng(midLat, midLng);
    _currentZoom = match.voltage == '135 kV' ? 16.2 : 16.0;

    try {
      _mapController.move(_currentCenter, _currentZoom);
    } catch (_) {}

    widget.onDateChanged?.call(_selectedDate);
    widget.onVoltageChanged?.call(_selectedVoltage);
    widget.onTowerChanged?.call(_selectedTower.id);
    widget.onCorridorChanged?.call(_selectedCorridorTop, _selectedCorridorBottom);
  }

  void _syncTowerStatus() {
    final t01Index = _allMapTowers.indexWhere((t) => t.id == 'T01-400KV-SB');
    if (t01Index != -1) {
      final old = _allMapTowers[t01Index];
      // Only read defects from widget.tower if it is actually the 400KV tower
      final is400Kv = widget.tower.towerId == '400KV_Tower_1_Site_B' ||
          widget.tower.towerId == 'T01-400KV-SB' ||
          widget.tower.towerName.contains('400KV');
      final actualDefects = is400Kv
          ? (widget.tower.summary.componentCounts['cotter_pin_missing'] ?? 9)
          : 9;
      _allMapTowers[t01Index] = MapTower(
        id: old.id,
        name: old.name,
        voltage: old.voltage,
        lineName: old.lineName,
        site: old.site,
        towerNumber: old.towerNumber,
        location: old.location,
        altitude: (is400Kv && widget.tower.location.altitudeM > 0)
            ? widget.tower.location.altitudeM
            : (old.altitude > 0 ? old.altitude : 43.881),
        spanToNext: old.spanToNext,
        partnerTowerId: old.partnerTowerId,
        partnerLocation: old.partnerLocation,
        segmentLabel: old.segmentLabel,
        isCritical: true, // T01-400KV-SB is permanently the critical tower with defects
        isInspected: true,
        surveyDate: old.surveyDate,
        surveyDateTime: old.surveyDateTime,
        defectCount: actualDefects,
      );
    }
  }

  void _zoomIn() {
    final nextZoom = (_currentZoom + 1.0).clamp(4.0, 19.0);
    _mapController.move(_currentCenter, nextZoom);
  }

  void _zoomOut() {
    final nextZoom = (_currentZoom - 1.0).clamp(4.0, 19.0);
    _mapController.move(_currentCenter, nextZoom);
  }

  void _resetNorth() {
    _mapController.rotate(0.0);
    setState(() {
      _currentRotation = 0.0;
    });
  }

  List<MapTower> get _filteredTowers {
    final list = _allMapTowers.where((tower) {
      if (_selectedDate != 'All dates' && tower.surveyDate != _selectedDate) {
        return false;
      }
      if (_selectedVoltage != 'All voltages' && tower.voltage != _selectedVoltage) {
        return false;
      }
      return true;
    }).toList();
    list.sort((a, b) {
      if (a.isCritical != b.isCritical) {
        return a.isCritical ? -1 : 1;
      }
      if (a.defectCount != b.defectCount) {
        return b.defectCount.compareTo(a.defectCount);
      }
      return a.towerNumber.compareTo(b.towerNumber);
    });
    return list;
  }

  void _selectVoltage(String voltage, [List<MapTower>? towers, String? corridorArrow, String? corridorTo]) {
    setState(() {
      _selectedVoltage = voltage;
      _showVoltageDropdown = false;
      _showCalendarDropdown = false;
      _expandedVoltageCategory = null;

      if (voltage == 'All voltages') {
        _selectedCorridorTop = null;
        _selectedCorridorBottom = null;
      } else if (towers != null && towers.isNotEmpty) {
        final info = TowerCorridorService.getInfo(towers.first.name);
        final arrow = corridorArrow ?? info?.corridorArrow ?? '${towers.first.site} Line';
        final from = arrow.contains(' → ') ? arrow.split(' → ').first.trim() : (info?.fromSubstation ?? 'Meramundali');
        final to = corridorTo ?? (arrow.contains(' → ') ? arrow.split(' → ').last.trim() : (info?.toSubstation ?? towers.first.site));
        _selectedCorridorTop = '$voltage · $from →';
        _selectedCorridorBottom = to;
      } else {
        _selectedCorridorTop = 'Voltage';
        _selectedCorridorBottom = voltage;
      }

      final targetTowers = (towers != null && towers.isNotEmpty)
          ? towers
          : (voltage == 'All voltages'
              ? ((_selectedDate == 'All dates')
                  ? _allMapTowers
                  : _allMapTowers.where((t) => t.surveyDate == _selectedDate).toList())
              : _allMapTowers.where((t) =>
                  (_selectedDate == 'All dates' || t.surveyDate == _selectedDate) &&
                  t.voltage == voltage).toList());

      if (targetTowers.isNotEmpty) {
        _selectedTower = targetTowers.first;
        if (voltage == '135 kV') {
          // Midpoint of 135 kV line (Screenshot 3) - individual pins without tooltips
          _currentCenter = const LatLng(20.824721, 85.264611);
          _currentZoom = 16.2;
        } else if (voltage == '400 kV') {
          final isSiteAOnly = targetTowers.every((t) => t.site == 'Site A' || t.id.contains('SA'));
          final isSiteBOnly = targetTowers.every((t) => t.site == 'Site B' || t.id.contains('SB'));
          if (isSiteAOnly || _selectedDate == '20 Apr 2026') {
            _currentCenter = const LatLng(20.823400, 85.268100);
            _currentZoom = 16.5;
          } else if (isSiteBOnly || _selectedDate == '28 Mar 2026') {
            _currentCenter = const LatLng(20.803800, 85.286600);
            _currentZoom = 16.0;
          } else {
            double sumLat = 0;
            double sumLng = 0;
            for (final t in targetTowers) {
              sumLat += t.location.latitude;
              sumLng += t.location.longitude;
            }
            _currentCenter = LatLng(sumLat / targetTowers.length, sumLng / targetTowers.length);
            _currentZoom = 14.5;
          }
        } else if (voltage == '220 kV') {
          final isSiteAOnly = targetTowers.every((t) => t.site == 'Site A' || t.id.contains('SA'));
          final isSiteBOnly = targetTowers.every((t) => t.site == 'Site B' || t.id.contains('SB'));
          if (isSiteAOnly) {
            _currentCenter = const LatLng(20.803149, 85.208488);
            _currentZoom = 16.0;
          } else if (isSiteBOnly) {
            _currentCenter = const LatLng(20.834668, 85.256791);
            _currentZoom = 16.0;
          } else {
            double sumLat = 0;
            double sumLng = 0;
            for (final t in targetTowers) {
              sumLat += t.location.latitude;
              sumLng += t.location.longitude;
            }
            _currentCenter = LatLng(sumLat / targetTowers.length, sumLng / targetTowers.length);
            _currentZoom = 15.0;
          }
        } else if (voltage == 'All voltages') {
          if (_selectedDate == '20 Apr 2026') {
            _currentCenter = const LatLng(20.823400, 85.268100);
            _currentZoom = 16.5;
          } else if (_selectedDate == '28 Mar 2026') {
            _currentCenter = const LatLng(20.803800, 85.286600);
            _currentZoom = 16.0;
          } else if (_selectedDate == '29 Mar 2026') {
            _currentCenter = const LatLng(20.817900, 85.235900);
            _currentZoom = 14.0;
          } else {
            _currentCenter = const LatLng(20.817900, 85.235900);
            _currentZoom = 14.0;
          }
        } else {
          _currentCenter = _selectedTower.location;
          _currentZoom = 16.0;
        }
        _mapController.move(_currentCenter, _currentZoom);
      } else if (voltage == 'All voltages') {
        _currentCenter = const LatLng(20.817900, 85.235900);
        _currentZoom = 14.0;
        _mapController.move(_currentCenter, _currentZoom);
      }
      widget.onVoltageChanged?.call(voltage);
      widget.onTowerChanged?.call(_selectedTower.id);
      widget.onCorridorChanged?.call(_selectedCorridorTop, _selectedCorridorBottom);
    });
  }

  void _onDateSelected(String date) {
    setState(() {
      _selectedDate = date;
      _showCalendarDropdown = false;
      _showVoltageDropdown = false;
      _expandedVoltageCategory = null;
      _selectedVoltage = 'All voltages';
      _selectedCorridorTop = null;
      _selectedCorridorBottom = null;
      _isSidebarOpen = false; // Close right sidebar so only map page stays
      widget.onCorridorChanged?.call(null, null);

      // Center map on the towers for this date
      final dateTowers = (date == 'All dates')
          ? _allMapTowers
          : _allMapTowers.where((t) => t.surveyDate == date).toList();

      if (dateTowers.isNotEmpty) {
        _selectedTower = dateTowers.first;
        if (date == '20 Apr 2026') {
          _currentCenter = const LatLng(20.823400, 85.268100);
          _currentZoom = 16.5;
        } else if (date == '16 Apr 2026') {
          _currentCenter = const LatLng(20.829000, 85.259000);
          _currentZoom = 15.0;
        } else if (date == '28 Mar 2026') {
          _currentCenter = const LatLng(20.803800, 85.286600);
          _currentZoom = 16.0;
        } else if (date == '29 Mar 2026') {
          _currentCenter = const LatLng(20.817900, 85.235900);
          _currentZoom = 14.0;
        } else if (date == '12 Apr 2026') {
          _currentCenter = const LatLng(20.803100, 85.208485);
          _currentZoom = 16.5;
        } else {
          _currentCenter = const LatLng(20.817900, 85.235900);
          _currentZoom = 14.0;
        }
        _mapController.move(_currentCenter, _currentZoom);
      }
      widget.onDateChanged?.call(date);
      widget.onVoltageChanged?.call('All voltages');
      widget.onTowerChanged?.call(_selectedTower.id);
    });
  }

  int _calculateScaleMeters() {
    const double initialResolution = 156543.03392;
    final double rad = _currentCenter.latitude * math.pi / 180.0;
    final double resolution = (initialResolution * math.cos(rad)) / math.pow(2, _currentZoom);
    final double groundMeters = 80.0 * resolution;
    if (groundMeters >= 1000) {
      return (groundMeters / 500).round() * 500;
    } else if (groundMeters >= 200) {
      return (groundMeters / 100).round() * 100;
    } else if (groundMeters >= 50) {
      return (groundMeters / 25).round() * 25;
    } else {
      return (groundMeters / 10).round() * 10;
    }
  }

  @override
  Widget build(BuildContext context) {
    final circuitSW = widget.tower.circuits.firstWhere(
      (c) => c.circuitId == 'Circuit_SW',
      orElse: () => widget.tower.circuits.first,
    );
    final phaseR = circuitSW.phases['Phase_R'] ??
        (circuitSW.phases.isNotEmpty ? circuitSW.phases.values.first : null);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 900;
    final sidebarWidth = math.min(410.0, screenWidth);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _handleGlobalPointerDown,
        child: Stack(
          children: [
            // 1. BASE VIEW: Interactive Map or Table View
            Positioned.fill(
              child: _isTableView
                  ? _buildTableView(circuitSW, phaseR)
                  : _buildRealOpenStreetMap(),
            ),

            // 2. FLOATING TOP HEADER
            Positioned(
              top: 16,
              left: screenWidth < 600 ? 12 : 20,
              right: screenWidth < 600 ? 12 : 20,
              child: _buildTopFloatingHeader(screenWidth),
            ),

            // 3. CALENDAR DROPDOWN OVERLAY
            if (_showCalendarDropdown)
              Positioned(
                top: 72,
                left: math.max(12.0, math.min(250.0, screenWidth - 266.0)),
                child: KeyedSubtree(
                  key: _calendarPopoverKey,
                  child: _buildCalendarPopover(screenWidth),
                ),
              ),

            // 4. VOLTAGE DROPDOWN OVERLAY
            if (_showVoltageDropdown)
              Positioned(
                top: 72,
                left: math.max(12.0, math.min(365.0, screenWidth - 306.0)),
                child: KeyedSubtree(
                  key: _voltagePopoverKey,
                  child: _buildVoltagePopover(screenWidth),
                ),
              ),

            // 5. BASEMAP SWITCHER POPOVER
            if (_showBaseMapPopover && !_isTableView)
              Positioned(
                right: (_isSidebarOpen && !isMobile) ? 490 : 80,
                top: 200,
                child: KeyedSubtree(
                  key: _baseMapPopoverKey,
                  child: _buildBaseMapPopover(),
                ),
              ),

            // 6. ABOUT THIS MAP POPOVER
            if (_showInfoPopover && !_isTableView)
              Positioned(
                right: (_isSidebarOpen && !isMobile) ? 490 : 80,
                top: 250,
                child: KeyedSubtree(
                  key: _infoPopoverKey,
                  child: _buildAboutThisMapPopover(),
                ),
              ),

            // 7. GRID ROUTE DETAIL POPOVER
            if (_selectedGridRoute != null && !_isTableView && _isGridActive)
              Positioned(
                top: 80,
                right: (_isSidebarOpen && !isMobile) ? 430 : 80,
                child: _buildRouteDetailPopup(_selectedGridRoute!),
              ),

            // 8. GRID SUBSTATION DETAIL POPOVER
            if (_selectedGridSubstation != null && !_isTableView)
              Positioned(
                top: 80,
                right: (_isSidebarOpen && !isMobile) ? 430 : 80,
                child: _buildSubstationDetailPopup(_selectedGridSubstation!),
              ),

            // 9. RIGHT SIDEBAR (When opened via Tower pin tap)
            if (_isSidebarOpen)
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: sidebarWidth,
                child: _buildRightSidebar(circuitSW, phaseR),
              ),
          ],
        ),
      ),
    );
  }

  // --- 1. REAL OPENSTREETMAP / SATELLITE VIEW ---
  Widget _buildRealOpenStreetMap() {
    final scaleMeters = _calculateScaleMeters();
    final visibleTowers = _filteredTowers;
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Distinct line segments among visible towers
    final polylines = <Polyline>[];
    final spanMidpointMarkers = <Marker>[];
    // 1. Grid polylines from osm_power_routes.geojson
    if (_isGridActive && _gridData != null) {
      for (final route in _gridData!.routes) {
        polylines.add(
          Polyline(
            points: route.points,
            color: route.color,
            strokeWidth: route.strokeWidth,
          ),
        );
      }
    }

    // 2. Tower connecting line segment
    // Connecting lines for all visible tower pairs matching active date & voltage filters
    final towersForConnectingLines = visibleTowers;
    final processedPairs = <String>{};

    for (final tower in towersForConnectingLines) {
      final pairKey = [tower.id, tower.partnerTowerId]..sort();
      final key = pairKey.join('_');
      if (processedPairs.contains(key)) continue;
      processedPairs.add(key);

      final partner = _allMapTowers.firstWhere(
        (t) => t.id == tower.partnerTowerId,
        orElse: () => tower,
      );

      if (partner.id != tower.id) {
        double towerSegWidth = 2.0;
        if (tower.voltage.contains('400')) {
          towerSegWidth = 4.2;
        } else if (tower.voltage.contains('220')) {
          towerSegWidth = 2.8;
        } else if (tower.voltage.contains('132') || tower.voltage.contains('135')) {
          towerSegWidth = 1.6;
        }

        // Draw connecting line between tower pair
        polylines.add(
          Polyline(
            points: [tower.location, partner.location],
            color: const Color(0xFF1E293B),
            strokeWidth: towerSegWidth,
          ),
        );

        // Span corridor label pill alongside the connecting line (when zoomed in)
        if (!_isGridActive || _currentZoom >= 14.5) {
          // Sort north-to-south for consistent offset and orientation
          final topPoint = tower.location.latitude >= partner.location.latitude
              ? tower.location
              : partner.location;
          final bottomPoint = tower.location.latitude < partner.location.latitude
              ? tower.location
              : partner.location;

          // Position exactly at the center (50% midpoint) along the span
          final midLat = (topPoint.latitude + bottomPoint.latitude) / 2.0;
          final midLng = (topPoint.longitude + bottomPoint.longitude) / 2.0;

          // Compute angle of the line in screen space
          final deltaLat = bottomPoint.latitude - topPoint.latitude;
          final deltaLng = bottomPoint.longitude - topPoint.longitude;
          final dy = -deltaLat; // screen Y increases downwards
          final dx = deltaLng * math.cos(((topPoint.latitude + bottomPoint.latitude) / 2) * math.pi / 180.0);
          double lineAngle = math.atan2(dy, dx);

          // Correct for map camera rotation
          double effectiveAngle = lineAngle + (_currentRotation * math.pi / 180.0);
          // Normalize to [-pi/2, pi/2] so text is always right-side up
          while (effectiveAngle > math.pi / 2) {
            effectiveAngle -= math.pi;
          }
          while (effectiveAngle < -math.pi / 2) {
            effectiveAngle += math.pi;
          }

          // Fetch corridor from CSV dynamically (e.g. "Meramundali – Mendhasal")
          final corridorInfo = TowerCorridorService.getInfo(tower.name) ??
              TowerCorridorService.getInfo(partner.name);
          final labelText = corridorInfo?.corridorDash ?? tower.segmentLabel;

          spanMidpointMarkers.add(
            Marker(
              point: LatLng(midLat, midLng),
              width: 220,
              height: 24,
              alignment: Alignment.center,
              child: Transform.rotate(
                angle: effectiveAngle,
                child: Transform.translate(
                  offset: const Offset(0, -8),
                  child: Center(
                    child: Text(
                      labelText,
                      style: const TextStyle(
                        fontSize: 9.0,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                        letterSpacing: 0.2,
                        shadows: [
                          Shadow(color: Colors.white, blurRadius: 3),
                          Shadow(color: Colors.white, blurRadius: 3),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    // 3. Grid substation polygons (footprint)
    final polygons = <Polygon>[];
    if (_isGridActive && _gridData != null) {
      for (final sub in _gridData!.substations) {
        if (sub.polygonPoints.isNotEmpty) {
          polygons.add(
            Polygon(
              points: sub.polygonPoints,
              borderColor: sub.name.contains('Meramundali')
                  ? const Color(0xFF7631EC)
                  : const Color(0xFFA855F7),
              borderStrokeWidth: 1.8,
              color: const Color(0x28A855F7),
            ),
          );
        }
      }
    }

    final markers = <Marker>[];

    // 4. Grid markers (Substations & Route callout pills with zoom-adaptive de-cluttering)
    if (_isGridActive && _gridData != null) {
      // Substation markers (Always styled with iconic [⚡] + [Name Substation] chip matching reference)
      for (final sub in _gridData!.substations) {
        if (sub.isPrimary) {
          final isSelected = _selectedGridSubstation?.id == sub.id;

          markers.add(
            Marker(
              point: sub.location,
              width: 260,
              height: 38,
              alignment: const Alignment(0.875, 0.0),
              child: _buildSubstationBadge(sub, isSelected),
            ),
          );
        }
      }
    }

    if (_isGridActive && _gridData != null) {
      LatLngBounds? visibleBounds;
      try {
        visibleBounds = _mapController.camera.visibleBounds;
      } catch (_) {
        final latSpan = 180.0 / math.pow(2, _currentZoom);
        final lngSpan = 360.0 / math.pow(2, _currentZoom);
        visibleBounds = LatLngBounds(
          LatLng(_currentCenter.latitude - latSpan, _currentCenter.longitude - lngSpan),
          LatLng(_currentCenter.latitude + latSpan, _currentCenter.longitude + lngSpan),
        );
      }

      // Display circular legend marker for every power line in the current view
      final processedRouteNames = <String>{};
      for (final route in _gridData!.routes) {
        if (processedRouteNames.contains(route.name)) continue;

        final markerLoc = _findVisiblePointOnRoute(route, visibleBounds);
        if (markerLoc == null) continue;

        processedRouteNames.add(route.name);
        final isSelected = _selectedGridRoute?.id == route.id;

        markers.add(
          Marker(
            point: markerLoc,
            width: isSelected ? 300 : 22,
            height: isSelected ? 60 : 22,
            alignment: isSelected ? Alignment.bottomCenter : Alignment.center,
            child: _buildRouteMarker(route, isSelected),
          ),
        );
      }
    }

    // 5. Tower Markers & Zoom-Out Clusters (Matches reference cluster view when zoomed out)
    if (_currentZoom >= 14.5) {
      // Zoomed In: Individual pins and line span label
      for (final tower in visibleTowers) {
        final isSelected = _isSidebarOpen && _selectedTower.id == tower.id;
        markers.add(
          Marker(
            point: tower.location,
            width: 26,
            height: 36,
            alignment: Alignment.topCenter,
            child: TowerPinWidget(
              label: tower.isCritical ? '✕' : (tower.isInspected ? '✓' : '-'),
              fillColor: tower.isCritical
                  ? const Color(0xFFDB322E)
                  : (tower.isInspected ? const Color(0xFF2E9D57) : const Color(0xFF707E94)),
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedTower = tower;
                  _isSidebarOpen = true;
                  _showBaseMapPopover = false;
                  _showInfoPopover = false;
                  _showCalendarDropdown = false;
                  _showVoltageDropdown = false;
                });
              },
            ),
          ),
        );
      }
      markers.addAll(spanMidpointMarkers);
    } else {
      // Zoomed Out: Cluster card and dual-colored donut ring matching reference image
      final groups = <String, List<MapTower>>{};
      for (final t in visibleTowers) {
        final key = '${t.voltage}_${t.site}';
        groups.putIfAbsent(key, () => []).add(t);
      }

      for (final entry in groups.entries) {
        final tList = entry.value;
        if (tList.isEmpty) continue;

        double sumLat = 0;
        double sumLng = 0;
        for (final t in tList) {
          sumLat += t.location.latitude;
          sumLng += t.location.longitude;
        }
        final clusterCenter = LatLng(sumLat / tList.length, sumLng / tList.length);
        final cCritical = tList.where((t) => t.isCritical).length;
        final cNormal = tList.where((t) => t.isNormal).length;
        final cUninspected = tList.where((t) => !t.isInspected).length;
        final clusterTitle = '${tList.length} towers · ${tList.first.voltage} ${tList.first.site}';

        markers.add(
          Marker(
            point: clusterCenter,
            width: 210,
            height: 115,
            alignment: const Alignment(0.0, 0.67),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentZoom = 16.0;
                  _currentCenter = clusterCenter;
                  _showCalendarDropdown = false;
                  _showVoltageDropdown = false;
                  _showBaseMapPopover = false;
                  _showInfoPopover = false;
                });
                _mapController.move(clusterCenter, 16.0);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Callout card matching user reference image
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          clusterTitle,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (cCritical > 0) ...[
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFDB322E),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$cCritical Critical',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            if (cCritical > 0 && (cNormal > 0 || cUninspected > 0))
                              const SizedBox(width: 8),
                            if (cNormal > 0) ...[
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2E9D57),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$cNormal Normal',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            if (cNormal > 0 && cUninspected > 0)
                              const SizedBox(width: 8),
                            if (cUninspected > 0) ...[
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF707E94),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$cUninspected Not inspected',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Click to zoom in',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1967D2),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Donut ring with count inside
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CustomPaint(
                      size: const Size(36, 36),
                      painter: _ClusterDonutPainter(
                        totalCount: tList.length,
                        criticalCount: cCritical,
                        normalCount: cNormal,
                        uninspectedCount: cUninspected,
                      ),
                      child: Center(
                        child: Text(
                          '${tList.length}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    final criticalCount = visibleTowers.where((t) => t.isCritical).length;
    final normalCount = visibleTowers.where((t) => t.isNormal).length;
    final uninspectedCount = visibleTowers.where((t) => !t.isInspected).length;

    final scaleDisplayString = scaleMeters >= 1000
        ? '${(scaleMeters / 1000).toStringAsFixed(scaleMeters % 1000 == 0 ? 0 : 1)} km'
        : '$scaleMeters m';

    return Stack(
      children: [
        // Interactive FlutterMap with rotation support
        Listener(
          key: _mapKey,
          onPointerDown: (event) {
            final isMouseOrTrackpad = event.kind == PointerDeviceKind.mouse ||
                event.kind == PointerDeviceKind.trackpad;
            final isSecondary = (event.buttons & kSecondaryMouseButton) != 0;
            final isMiddle = (event.buttons & kMiddleMouseButton) != 0;
            final isPrimaryWithModifier = (event.buttons & kPrimaryMouseButton) != 0 &&
                (HardwareKeyboard.instance.isControlPressed ||
                 HardwareKeyboard.instance.isShiftPressed ||
                 HardwareKeyboard.instance.isAltPressed);

            if (isMouseOrTrackpad && (isSecondary || isMiddle || isPrimaryWithModifier)) {
              final RenderBox? box = _mapKey.currentContext?.findRenderObject() as RenderBox?;
              if (box != null) {
                _mouseRotateStartPos = box.globalToLocal(event.position);
                _mouseRotateStartAngle = _currentRotation;
              }
            }
          },
          onPointerMove: (event) {
            if (_mouseRotateStartPos != null) {
              final RenderBox? box = _mapKey.currentContext?.findRenderObject() as RenderBox?;
              if (box != null) {
                final currentPos = box.globalToLocal(event.position);
                final mapCenter = Offset(box.size.width / 2, box.size.height / 2);
                final v1 = _mouseRotateStartPos! - mapCenter;
                final v2 = currentPos - mapCenter;
                if (v1.distance > 8 && v2.distance > 8) {
                  final a1 = math.atan2(v1.dy, v1.dx);
                  final a2 = math.atan2(v2.dy, v2.dx);
                  final deltaDeg = (a2 - a1) * 180.0 / math.pi;
                  final newRotation = ((_mouseRotateStartAngle + deltaDeg) % 360.0 + 360.0) % 360.0;
                  _mapController.rotate(newRotation);
                  setState(() {
                    _currentRotation = newRotation;
                  });
                }
              }
            }
          },
          onPointerUp: (_) => _mouseRotateStartPos = null,
          onPointerCancel: (_) => _mouseRotateStartPos = null,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: _currentZoom,
              initialRotation: _currentRotation,
              minZoom: 4.0,
              maxZoom: 19.0,
              onTap: (tapPosition, point) {
                if (_showCalendarDropdown ||
                    _showVoltageDropdown ||
                    _showBaseMapPopover ||
                    _showInfoPopover) {
                  setState(() {
                    _showCalendarDropdown = false;
                    _showVoltageDropdown = false;
                    _showBaseMapPopover = false;
                    _showInfoPopover = false;
                  });
                }
              },
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all,
                cursorKeyboardRotationOptions: CursorKeyboardRotationOptions(
                  behaviour: CursorRotationBehaviour.offset,
                  setNorthOnClick: false,
                  isKeyTrigger: (key) =>
                      key == LogicalKeyboardKey.shift ||
                      key == LogicalKeyboardKey.shiftLeft ||
                      key == LogicalKeyboardKey.shiftRight ||
                      key == LogicalKeyboardKey.control ||
                      key == LogicalKeyboardKey.controlLeft ||
                      key == LogicalKeyboardKey.controlRight ||
                      key == LogicalKeyboardKey.alt ||
                      key == LogicalKeyboardKey.altLeft ||
                      key == LogicalKeyboardKey.altRight,
                ),
              ),
              onMapEvent: (event) {
                if ((event.camera.rotation - _currentRotation).abs() > 0.01) {
                  setState(() {
                    _currentRotation = event.camera.rotation;
                  });
                }
              },
              onPositionChanged: (camera, hasGesture) {
                setState(() {
                  _currentCenter = camera.center;
                  _currentZoom = camera.zoom;
                  _currentRotation = camera.rotation;
                });
              },
            ),
            children: [
              TileLayer(
                key: ValueKey(_isSatellite ? 'satellite' : 'streets'),
                urlTemplate: _isSatellite
                    ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.towerlens.app',
                maxZoom: 19,
              ),
              if (_isGridActive && polygons.isNotEmpty)
                PolygonLayer(polygons: polygons),
              PolylineLayer(polylines: polylines),
              MarkerLayer(markers: markers),
            ],
          ),
        ),

        // Floating Bottom-Left Cards (CONDITION and POWER NETWORK)
        Positioned(
          left: screenWidth < 600 ? 12 : 20,
          bottom: screenWidth < 600 ? 16 : 24,
          child: screenWidth < 680
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildConditionCard(visibleTowers, criticalCount, normalCount, uninspectedCount),
                    if (_isGridActive) ...[
                      const SizedBox(height: 8),
                      _buildPowerNetworkLegendCard(),
                    ],
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildConditionCard(visibleTowers, criticalCount, normalCount, uninspectedCount),
                    if (_isGridActive) ...[
                      const SizedBox(width: 12),
                      _buildPowerNetworkLegendCard(),
                    ],
                  ],
                ),
        ),

        // Floating Right Controls (North, Zoom +, Zoom -, Layers, Info) matching Penpot exactly
        Positioned(
          right: (_isSidebarOpen && screenWidth >= 900) ? 430 : 16,
          top: 90,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTrueNorthButton(),
              const SizedBox(height: 12),
              _buildZoomFrame(),
              const SizedBox(height: 12),
              _buildBaseMapButton(),
              const SizedBox(height: 12),
              _buildAboutThisMapButton(),
            ],
          ),
        ),

        // Floating Bottom-Right Scale and Dynamic Coordinates
        Positioned(
          right: (_isSidebarOpen && screenWidth >= 900) ? 430 : 16,
          bottom: screenWidth < 600 ? 16 : 24,
          child: screenWidth < 520
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x14101828), blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_currentCenter.latitude.toStringAsFixed(4)}° N,  ${_currentCenter.longitude.toStringAsFixed(4)}° E',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            scaleDisplayString,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          CustomPaint(
                            size: const Size(22, 6),
                            painter: _ScaleBracketPainter(color: const Color(0xFF475569)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '© OpenStreetMap contributors',
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // --- TRUE NORTH COMPASS BUTTON (Rotates dynamically with map rotation) ---
  Widget _buildTrueNorthButton() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x14101828), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _resetNorth,
            onPanUpdate: (details) {
              final v = details.localPosition - const Offset(24, 24);
              if (v.distance > 4) {
                final angle = (math.atan2(v.dy, v.dx) * 180.0 / math.pi) + 90.0;
                final rot = (angle % 360.0 + 360.0) % 360.0;
                _mapController.rotate(rot);
                setState(() {
                  _currentRotation = rot;
                });
              }
            },
            child: Tooltip(
              message: _currentRotation.abs() > 0.5
                  ? 'Reset to North (${_currentRotation.round()}°)'
                  : 'True North (Right-click drag or Shift+drag map to rotate)',
              child: Center(
                child: Transform.rotate(
                  angle: _currentRotation * math.pi / 180.0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'N',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          height: 1.0,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      CustomPaint(
                        size: const Size(12, 16),
                        painter: _NorthNeedlePainter(color: const Color(0xFF1E60B5)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomFrame() {
    return Container(
      width: 48,
      height: 97,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x14101828), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: InkWell(
              onTap: _zoomIn,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              child: const Center(
                child: Icon(Icons.add, size: 20, color: Color(0xFF18212B)),
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
          Expanded(
            child: InkWell(
              onTap: _zoomOut,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
              child: const Center(
                child: Icon(Icons.remove, size: 20, color: Color(0xFF18212B)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaseMapButton() {
    return Container(
      key: _baseMapButtonKey,
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _showBaseMapPopover ? const Color(0xFFE8F0FE) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _showBaseMapPopover ? const Color(0xFF1E60B5) : const Color(0xFFE2E8F0),
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x14101828), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            setState(() {
              _showBaseMapPopover = !_showBaseMapPopover;
              _showInfoPopover = false;
              _showCalendarDropdown = false;
              _showVoltageDropdown = false;
            });
          },
          child: Center(
            child: CustomPaint(
              size: const Size(20, 20),
              painter: _LayersIconPainter(
                color: _showBaseMapPopover ? const Color(0xFF1E60B5) : const Color(0xFF18212B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAboutThisMapButton() {
    return Container(
      key: _infoButtonKey,
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _showInfoPopover ? const Color(0xFFE8F0FE) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _showInfoPopover ? const Color(0xFF1E60B5) : const Color(0xFFE2E8F0),
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x14101828), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            setState(() {
              _showInfoPopover = !_showInfoPopover;
              _showBaseMapPopover = false;
              _showCalendarDropdown = false;
              _showVoltageDropdown = false;
            });
          },
          child: Center(
            child: Icon(
              Icons.info_outline,
              size: 20,
              color: _showInfoPopover ? const Color(0xFF1E60B5) : const Color(0xFF18212B),
            ),
          ),
        ),
      ),
    );
  }

  // --- BASE MAP POPOVER ---
  Widget _buildBaseMapPopover() {
    return Container(
      width: 275,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x14101828), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Base map',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isSatellite = false;
                      _showBaseMapPopover = false;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: !_isSatellite ? const Color(0xFFE8F0FE) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: !_isSatellite ? const Color(0xFF1E60B5) : const Color(0xFFCBD5E1),
                        width: !_isSatellite ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            height: 60,
                            width: double.infinity,
                            child: CustomPaint(painter: _StreetMapThumbnailPainter()),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              'Street map',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: !_isSatellite ? FontWeight.bold : FontWeight.w500,
                                color: !_isSatellite ? const Color(0xFF1E60B5) : const Color(0xFF1E293B),
                              ),
                            ),
                            if (!_isSatellite) ...[
                              const Spacer(),
                              const Icon(Icons.check_circle, size: 14, color: Color(0xFF1E60B5)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isSatellite = true;
                      _showBaseMapPopover = false;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _isSatellite ? const Color(0xFFE8F0FE) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isSatellite ? const Color(0xFF1E60B5) : const Color(0xFFCBD5E1),
                        width: _isSatellite ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(
                            height: 60,
                            width: double.infinity,
                            child: CustomPaint(painter: _SatelliteThumbnailPainter()),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              'Satellite',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: _isSatellite ? FontWeight.bold : FontWeight.w500,
                                color: _isSatellite ? const Color(0xFF1E60B5) : const Color(0xFF1E293B),
                              ),
                            ),
                            if (_isSatellite) ...[
                              const Spacer(),
                              const Icon(Icons.check_circle, size: 14, color: Color(0xFF1E60B5)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- ABOUT THIS MAP POPOVER (Matching Penpot / Screenshot 2) ---
  Widget _buildAboutThisMapPopover() {
    return Container(
      width: 285,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title: About this map
          const Text(
            'About this map',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          // Section 1: How to use
          const Text(
            'How to use',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'The map opens on the latest survey. Pick another date to load its towers, then narrow them by voltage or by tapping a condition in the legend.',
            style: TextStyle(
              fontSize: 11.5,
              color: Color(0xFF334155),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),

          // Section 2: Reading a tower ID
          const Text(
            'Reading a tower ID',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              // Pill 1: T01 (blue)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text(
                  'T01',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1967D2),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: Text(
                  '–',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Pill 2: 400KV (grey)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text(
                  '400KV',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: Text(
                  '–',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Pill 3: SA (grey)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text(
                  'SA',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          const Text(
            'Tower number, then voltage, then site (SA = Site A).',
            style: TextStyle(
              fontSize: 11.5,
              color: Color(0xFF475569),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),

          // Divider and OSM attribution
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          const Text(
            'Map data © OpenStreetMap contributors',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. FLOATING TOP HEADER PILLS ---
  Widget _buildTopFloatingHeader([double? screenWidth]) {
    final isNarrow = (screenWidth ?? 1200) < 960;
    final headerRow = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: isNarrow ? MainAxisSize.min : MainAxisSize.max,
      children: [
        // Pill 1: TowerLens Intelligence Logo
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const TowerLensLogo(
            iconSize: 28,
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 12),

        // Pill 2: Filters (Survey Date & Voltage)
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Survey Date Filter Button
              InkWell(
                key: _calendarButtonKey,
                onTap: () {
                  setState(() {
                    _showCalendarDropdown = !_showCalendarDropdown;
                    _showVoltageDropdown = false;
                    if (_showCalendarDropdown) {
                      if (_selectedDate.contains('Apr')) {
                        _calendarDisplayMonth = DateTime(2026, 4, 1);
                      } else {
                        // Default to latest surveyed month (March 2026)
                        _calendarDisplayMonth = DateTime(2026, 3, 1);
                      }
                    }
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E60B5),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '1',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Survey date',
                            style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                          Row(
                            children: [
                              Text(
                                _selectedDate,
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              if (_selectedDate == '20 Apr 2026') ...[
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text(
                                    'Latest',
                                    style: TextStyle(color: Color(0xFF2E7D32), fontSize: 9.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _showCalendarDropdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 18,
                        color: const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 16, color: Color(0xFFCBD5E1)),
              const SizedBox(width: 8),

              // Voltage Filter Button (Flow depends on selected date)
              InkWell(
                key: _voltageButtonKey,
                onTap: () {
                  setState(() {
                    _showVoltageDropdown = !_showVoltageDropdown;
                    _showCalendarDropdown = false;
                    _expandedVoltageCategory = _showVoltageDropdown && _selectedVoltage != 'All voltages'
                        ? _selectedVoltage
                        : null;
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E60B5),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '2',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _selectedCorridorTop ?? 'Voltage',
                            style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                          Text(
                            _selectedCorridorBottom ?? _selectedVoltage,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _showVoltageDropdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 18,
                        color: const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Pill 3: Map / Table View Segmented Switch
        Container(
          height: 46,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => setState(() {
                  _isTableView = false;
                  _showCalendarDropdown = false;
                  _showVoltageDropdown = false;
                  _showBaseMapPopover = false;
                  _showInfoPopover = false;
                }),
                borderRadius: BorderRadius.circular(7),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: !_isTableView ? const Color(0xFFE8F0FE) : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 16,
                        color: !_isTableView ? const Color(0xFF1E60B5) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Map',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: !_isTableView ? FontWeight.bold : FontWeight.w500,
                          color: !_isTableView ? const Color(0xFF1E60B5) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: () => setState(() {
                  _isTableView = true;
                  _showCalendarDropdown = false;
                  _showVoltageDropdown = false;
                  _showBaseMapPopover = false;
                  _showInfoPopover = false;
                }),
                borderRadius: BorderRadius.circular(7),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: _isTableView ? const Color(0xFFE8F0FE) : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.table_chart_outlined,
                        size: 16,
                        color: _isTableView ? const Color(0xFF1E60B5) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Table',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: _isTableView ? FontWeight.bold : FontWeight.w500,
                          color: _isTableView ? const Color(0xFF1E60B5) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        if (!isNarrow) const Spacer() else const SizedBox(width: 12),

        // Grid Button (beside Log out - visible only in Map View)
        if (!_isTableView) ...[
          _buildGridButton(),
          const SizedBox(width: 12),
        ],

        // Pill 4: Log out Button
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onLogout,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.logout, size: 16, color: Color(0xFF1E293B)),
                    SizedBox(width: 8),
                    Text(
                      'Log out',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );

    if (isNarrow) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: headerRow,
      );
    }
    return headerRow;
  }

  // --- 3. DYNAMIC CALENDAR POPOVER (Supports all months and years) ---
  Widget _buildCalendarPopover([double? screenWidth]) {
    final year = _calendarDisplayMonth.year;
    final month = _calendarDisplayMonth.month;
    final monthName = DateFormat('MMMM yyyy').format(_calendarDisplayMonth);

    final firstDay = DateTime(year, month, 1);
    final firstWeekday = firstDay.weekday % 7; // Sunday = 0
    final daysInMonth = DateTime(year, month + 1, 0).day;

    final calendarSlots = <int?>[];
    for (int i = 0; i < firstWeekday; i++) {
      calendarSlots.add(null);
    }
    for (int d = 1; d <= daysInMonth; d++) {
      calendarSlots.add(d);
    }
    while (calendarSlots.length % 7 != 0) {
      calendarSlots.add(null);
    }

    final popoverWidth = screenWidth != null ? math.min(250.0, screenWidth - 24.0) : 250.0;

    return Container(
      width: popoverWidth,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Highlighted days have surveyed towers.',
            style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),

          // Month & Year Switcher with Fast Year Navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 18),
                onPressed: () {
                  setState(() {
                    _calendarDisplayMonth = DateTime(year, month - 1, 1);
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              InkWell(
                onTap: () => setState(() => _showYearDropdown = !_showYearDropdown),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  child: Row(
                    children: [
                      Text(
                        monthName,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        _showYearDropdown ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        size: 16,
                        color: const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 18),
                onPressed: () {
                  setState(() {
                    _calendarDisplayMonth = DateTime(year, month + 1, 1);
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          // Year Quick Picker dropdown
          if (_showYearDropdown) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.center,
                children: [2024, 2025, 2026, 2027, 2028].map((y) {
                  final isCurrentYear = y == year;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _calendarDisplayMonth = DateTime(y, month, 1);
                        _showYearDropdown = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isCurrentYear ? const Color(0xFF1E60B5) : Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: isCurrentYear ? const Color(0xFF1E60B5) : const Color(0xFFCBD5E1)),
                      ),
                      child: Text(
                        '$y',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: isCurrentYear ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Days of week header (S M T W T F S)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _CalendarDayHeader('S'),
              _CalendarDayHeader('M'),
              _CalendarDayHeader('T'),
              _CalendarDayHeader('W'),
              _CalendarDayHeader('T'),
              _CalendarDayHeader('F'),
              _CalendarDayHeader('S'),
            ],
          ),
          const SizedBox(height: 4),

          // Dynamic Calendar Days Grid
          for (int row = 0; row < calendarSlots.length; row += 7)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: calendarSlots.sublist(row, row + 7).map((d) {
                  if (d == null) return const SizedBox(width: 24, height: 24);

                  final slotDate = DateTime(year, month, d);
                  final formattedDate = DateFormat('d MMM yyyy').format(slotDate);
                  final isSelected = _selectedDate == formattedDate;

                  final towersOnDay = _allMapTowers.where((t) =>
                      t.surveyDateTime.year == year &&
                      t.surveyDateTime.month == month &&
                      t.surveyDateTime.day == d).toList();

                  final hasSurvey = towersOnDay.isNotEmpty;
                  final hasCritical = towersOnDay.any((t) => t.isCritical) ||
                      (year == 2026 && month == 3 && d == 28);

                  return InkWell(
                    onTap: () => _onDateSelected(formattedDate),
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF1967D2)
                                  : (hasSurvey ? const Color(0xFFE8F0FE) : Colors.transparent),
                              shape: BoxShape.circle,
                              border: hasSurvey && !isSelected
                                  ? Border.all(
                                      color: hasCritical
                                          ? const Color(0xFFDB322E)
                                          : (year == 2026 && month == 3 && d == 29
                                              ? const Color(0xFF2E9D57)
                                              : const Color(0xFF1967D2)),
                                      width: 1.3,
                                    )
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$d',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: (hasSurvey || isSelected) ? FontWeight.bold : FontWeight.normal,
                                color: isSelected
                                    ? Colors.white
                                    : (hasSurvey ? const Color(0xFF1967D2) : const Color(0xFF334155)),
                              ),
                            ),
                          ),
                          // Small red mark to show importance on March 28, 2026 (critical survey date)
                          if (hasCritical)
                            Positioned(
                              top: -1,
                              right: -1,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDB322E),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Small green mark on March 29, 2026 (all 6 towers normal condition / 0 defects)
                          if (year == 2026 && month == 3 && d == 29)
                            Positioned(
                              top: -1,
                              right: -1,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E9D57),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 6),

          // Show All Dates Button (Optional for viewing all 10 towers at once)
          InkWell(
            onTap: () => _onDateSelected('All dates'),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _selectedDate == 'All dates' ? const Color(0xFFE8F0FE) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _selectedDate == 'All dates' ? const Color(0xFF1967D2) : const Color(0xFFCBD5E1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.layers_outlined,
                    size: 14,
                    color: _selectedDate == 'All dates' ? const Color(0xFF1967D2) : const Color(0xFF475569),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Show all survey dates (10 towers)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _selectedDate == 'All dates' ? const Color(0xFF1967D2) : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. VOLTAGE POPOVER OVERLAY (Matches reference design with corridor subcards) ---
  Widget _buildVoltagePopover([double? screenWidth]) {
    // Get towers surveyed on this specific date
    final dateTowers = (_selectedDate == 'All dates')
        ? _allMapTowers
        : _allMapTowers.where((t) => t.surveyDate == _selectedDate).toList();

    // Distinct voltages present for this survey date
    final voltagesOnDate = <String>[];
    for (final t in dateTowers) {
      if (!voltagesOnDate.contains(t.voltage)) {
        voltagesOnDate.add(t.voltage);
      }
    }
    if (_selectedDate == 'All dates') {
      for (final v in ['400 kV', '220 kV', '135 kV']) {
        if (!voltagesOnDate.contains(v)) voltagesOnDate.add(v);
      }
    }
    // Sort highest voltage first (e.g. 400 kV > 220 kV > 135 kV)
    voltagesOnDate.sort((a, b) {
      final aVal = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final bVal = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return bVal.compareTo(aVal);
    });

    final popoverWidth = screenWidth != null ? math.min(290.0, screenWidth - 24.0) : 290.0;

    return Container(
      width: popoverWidth,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Lines surveyed on [date]
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Text(
              _selectedDate == 'All dates'
                  ? 'All transmission lines (${dateTowers.length} towers)'
                  : 'Lines surveyed on $_selectedDate',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),

          // Option: All voltages
          InkWell(
            onTap: () => _selectVoltage('All voltages'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              color: _selectedVoltage == 'All voltages' ? const Color(0xFFF8FAFC) : Colors.transparent,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'All voltages',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: _selectedVoltage == 'All voltages' ? FontWeight.bold : FontWeight.w500,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Text(
                    '${dateTowers.length} towers',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  if (_selectedVoltage == 'All voltages') ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.check, size: 14, color: Color(0xFF1E60B5)),
                  ],
                ],
              ),
            ),
          ),

          // Voltage items with dynamic corridor subcards from CSV
          for (final v in voltagesOnDate)
            _buildVoltageItemWithCorridors(v, dateTowers),
        ],
      ),
    );
  }

  Widget _buildVoltageItemWithCorridors(String voltage, List<MapTower> dateTowers) {
    final vTowers = dateTowers.where((t) => t.voltage == voltage).toList();
    final count = vTowers.length;
    final isSelected = _selectedVoltage == voltage;

    // Build unique corridor groups from the CSV service
    final corridorCards = <Widget>[];
    if (vTowers.isNotEmpty) {
      final groups = <String, List<MapTower>>{};
      for (final t in vTowers) {
        final groupKey = t.site;
        groups.putIfAbsent(groupKey, () => []).add(t);
      }

      for (final entry in groups.entries) {
        final towers = entry.value;
        final info = TowerCorridorService.getInfo(towers.first.name);
        final arrow = info?.corridorArrow ?? '${towers.first.site} Line';
        final site = towers.first.site;
        final subtitle = '$site · ${towers.length} towers';
        final toName = arrow.contains(' → ') ? arrow.split(' → ').last.trim() : (info?.toSubstation ?? site);

        corridorCards.add(
          Padding(
            padding: const EdgeInsets.only(left: 38, top: 2, bottom: 6, right: 14),
            child: InkWell(
              onTap: () => _selectVoltage(voltage, towers, arrow, toName),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      arrow,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    final isExpanded = _expandedVoltageCategory == voltage;

    if (isSelected) {
      // Selected state: Light blue pill, checkmark, dark dash, bold blue text, blue count, chevron (up when expanded, down when collapsed)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF5FD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: () {
                setState(() {
                  _expandedVoltageCategory = isExpanded ? null : voltage;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Row(
                  children: [
                    const Icon(Icons.check, size: 14, color: Color(0xFF1E60B5)),
                    const SizedBox(width: 8),
                    Container(
                      width: 14,
                      height: 2.2,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        voltage,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E60B5),
                        ),
                      ),
                    ),
                    Text(
                      '$count towers',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E60B5),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 16,
                      color: const Color(0xFF1E60B5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded) ...corridorCards,
        ],
      );
    } else {
      // Unselected state: aligned grey dash, dark text, count, chevron (up when expanded, down when collapsed)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: InkWell(
              onTap: () {
                setState(() {
                  _expandedVoltageCategory = isExpanded ? null : voltage;
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: Row(
                  children: [
                    const SizedBox(width: 22),
                    Container(
                      width: 14,
                      height: 2.2,
                      decoration: BoxDecoration(
                        color: const Color(0xFF64748B),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        voltage,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Text(
                      '$count towers',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 16,
                      color: const Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded) ...corridorCards,
        ],
      );
    }
  }

  // --- 5. RIGHT SIDEBAR ---
  Widget _buildRightSidebar(Circuit circuitSW, Phase? phaseR) {
    final tower = _selectedTower;
    final isCritical = tower.isCritical;
    final towerDef = TowerRegistry.getTower(tower.id);
    final isInspected = tower.isInspected || (towerDef?.hasInspectionData ?? false);
    final isSingleCircuit = tower.id.contains('135KV');
    final baseAsset = towerDef?.baseImageAsset ?? (tower.id == 'T01-400KV-SB' ? AppConfig.baseTowerImageAsset : null);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          left: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(-6, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sidebar Header: Back link & Close button matching Penpot
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => setState(() {
                    _isSidebarOpen = false;
                    _showCalendarDropdown = false;
                    _showVoltageDropdown = false;
                  }),
                  child: Row(
                    children: [
                      const Icon(Icons.chevron_left, size: 18, color: Color(0xFF1E60B5)),
                      Text(
                        '${_filteredTowers.length} towers · ${tower.surveyDate}',
                        style: const TextStyle(
                          color: Color(0xFF1E60B5),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Color(0xFF64748B)),
                    onPressed: () => setState(() {
                      _isSidebarOpen = false;
                      _showCalendarDropdown = false;
                      _showVoltageDropdown = false;
                    }),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),

          // Tower Name and Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tower.id,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${tower.lineName} · ${tower.site} · Tower ${tower.towerNumber} of 2',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 14),

                // Capacity, Tower Type & Aerial Thumbnail Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Capacity',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F0FE),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tower.voltage,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1967D2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (isInspected) ...[
                            const Text(
                              'Tower type',
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                _buildPillTag(isSingleCircuit ? 'Single circuit' : 'Double circuit'),
                                _buildPillTag(tower.voltage.contains('135') || tower.id.contains('135KV') ? 'Tension' : 'Suspension'),
                              ],
                            ),
                          ] else ...[
                            const Text(
                              'Tower type · not available',
                              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Aerial Photo Thumbnail (accurately zoomed into tower structure with high clarity)
                    if (isInspected && baseAsset != null)
                      _buildTowerThumbnail(tower, baseAsset)
                    else
                      Container(
                        width: 96,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.photo_camera_outlined, size: 20, color: Color(0xFF94A3B8)),
                            SizedBox(height: 4),
                            Text(
                              'No photo',
                              style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Segmented Tabs: Overview, Defects, History
          Container(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            child: Row(
              children: [
                _buildSidebarTab('Overview', 0),
                _buildSidebarTab(
                  'Defects',
                  1,
                  count: isCritical ? '${tower.defectCount}' : (isInspected ? '0' : null),
                  isRed: isCritical,
                ),
                _buildSidebarTab(
                  'History',
                  2,
                  count: isInspected ? '1' : null,
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: _activeTab == 0
                ? _buildOverviewTabContent(tower)
                : _activeTab == 1
                    ? _buildDefectsTabContent(tower)
                    : _buildHistoryTabContent(tower),
          ),

          // Bottom Section:
          // Show button for all inspected towers!
          if (isInspected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      widget.onOpenInspection(null, null, _selectedTower.id);
                    },
                    icon: const Icon(Icons.description_outlined, size: 16),
                    label: const Text(
                      'Open inspection details',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1967D2),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  Text(
                    'Surveyed ${tower.surveyDate}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF94A3B8),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Not inspected · ${tower.surveyDate}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // --- OVERVIEW TAB CONTENT (strictly matching user reference) ---
  Widget _buildOverviewTabContent(MapTower tower) {
    final towerDef = TowerRegistry.getTower(tower.id);
    final isInspected = tower.isInspected || (towerDef?.hasInspectionData ?? false);
    final isSingleCircuit = tower.id.contains('135KV');

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        // Status condition banner matching reference
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: tower.isCritical
                ? const Color(0xFFFDF2F2)
                : (isInspected ? const Color(0xFFF0FDF4) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: tower.isCritical
                  ? const Color(0xFFFEE2E2)
                  : (isInspected ? const Color(0xFFBBF7D0) : const Color(0xFFCBD5E1)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: tower.isCritical
                      ? const Color(0xFFDC2626)
                      : (isInspected ? const Color(0xFF16A34A) : const Color(0xFF707E94)),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  tower.isCritical ? Icons.close : (isInspected ? Icons.check : Icons.remove),
                  size: 15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tower.isCritical
                          ? 'Critical condition'
                          : (isInspected ? 'Normal condition' : 'Not inspected'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: tower.isCritical
                            ? const Color(0xFF991B1B)
                            : (isInspected ? const Color(0xFF166534) : const Color(0xFF334155)),
                      ),
                    ),
                    if (tower.isCritical || !isInspected) ...[
                      const SizedBox(height: 2),
                      Text(
                        tower.isCritical
                            ? '${tower.defectCount} cotter pins missing - first survey of this tower'
                            : 'No images of this tower in the ${tower.surveyDate} survey',
                        style: TextStyle(
                          fontSize: 12,
                          color: tower.isCritical
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Metadata rows with dividers matching user reference screenshot
        _buildOverviewMetaRow(
          icon: Icons.location_on_outlined,
          label: 'Coordinates',
          value: '${tower.location.latitude.toStringAsFixed(6)},  ${tower.location.longitude.toStringAsFixed(6)}',
          trailing: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () {
              Clipboard.setData(ClipboardData(
                text: '${tower.location.latitude.toStringAsFixed(6)}, ${tower.location.longitude.toStringAsFixed(6)}',
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coordinates copied to clipboard')),
              );
            },
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.copy_outlined, size: 16, color: Color(0xFF94A3B8)),
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

        _buildOverviewMetaRow(
          icon: Icons.terrain_outlined,
          label: 'Altitude',
          value: '${tower.altitude.toStringAsFixed(1)} m',
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

        _buildOverviewMetaRow(
          icon: Icons.calendar_today_outlined,
          label: 'Survey date',
          value: tower.surveyDate,
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

        _buildOverviewMetaRow(
          icon: Icons.grid_view_outlined,
          label: 'Circuit & phase',
          value: isInspected
              ? (isSingleCircuit ? '1 circuit · 3 phases' : '2 circuits · 6 phases')
              : 'Not available',
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

        _buildOverviewMetaRow(
          icon: Icons.straighten_outlined,
          label: 'Span',
          value: tower.spanToNext,
          isLink: true,
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

        _buildOverviewMetaRow(
          icon: Icons.warning_amber_rounded,
          label: 'Defects detected',
          value: '',
          valueWidget: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: tower.isCritical
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tower.isCritical ? '${tower.defectCount} Critical' : '0 Critical',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: tower.isCritical ? FontWeight.bold : FontWeight.w600,
                    color: tower.isCritical ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '0 Major',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '0 Minor',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewMetaRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? valueWidget,
    Widget? trailing,
    bool isLink = false,
  }) {
    Widget content;
    if (valueWidget != null) {
      content = valueWidget;
    } else if (isLink && value.contains(' to ')) {
      final parts = value.split(' to ');
      content = RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${parts[0]} to ',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            TextSpan(
              text: parts[1],
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1967D2),
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      );
    } else {
      content = Text(
        value,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isLink ? const Color(0xFF1967D2) : AppColors.textPrimary,
          decoration: isLink ? TextDecoration.underline : null,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 17, color: const Color(0xFF64748B)),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ),
          Expanded(child: content),
          ?trailing,
        ],
      ),
    );
  }

  // --- DEFECTS TAB CONTENT ---
  Widget _buildDefectsTabContent(MapTower tower) {
    final towerDef = TowerRegistry.getTower(tower.id);
    final isInspected = tower.isInspected || (towerDef?.hasInspectionData ?? false);

    if (isInspected && !tower.isCritical) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF16A34A),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.check, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Normal condition',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF166534),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '0 defects detected',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (!isInspected) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.remove, size: 28, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              const Text(
                'Not inspected',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'No images of this tower in the ${tower.surveyDate} survey',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              const Text(
                'There are no defects to list. Defects appear here once the tower has been inspected.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        Text(
          '${tower.defectCount} cotter pins missing',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFFB91C1C),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Critical · remedy action to be decided by the line engineer.',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'DEFECTS BY PHASE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),

        ..._buildDefectPhaseRows(tower),
        const SizedBox(height: 14),
        const Text(
          'A phase is flagged Critical when it has more than 2 defects, or a defect where no cotter pin is seen.',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF94A3B8),
            fontStyle: FontStyle.italic,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDefectPhaseRows(MapTower tower) {
    final towerDef = TowerRegistry.getTower(tower.id);
    final Tower? activeTower = (widget.tower.towerId == tower.id || widget.tower.towerId == towerDef?.towerId)
        ? widget.tower
        : DataService.getCachedData(tower.id)?.tower;

    if (activeTower != null && activeTower.circuits.isNotEmpty) {
      final rows = <Widget>[];
      for (final circuit in activeTower.circuits) {
        for (final entry in circuit.phases.entries) {
          final phaseName = entry.key;
          final phase = entry.value;
          int phaseMissing = 0;
          final defectIndices = <int>[];
          final distances = <double>[];

          for (int i = 0; i < phase.images.length; i++) {
            final img = phase.images[i];
            if (img.distanceToTowerM > 0) {
              distances.add(img.distanceToTowerM);
            }
            final int missingCount = img.missingCotterPinCount;
            if (missingCount > 0) {
              phaseMissing += missingCount;
              defectIndices.add(i + 1);
            }
          }

          final String subtitle;
          final distStr = distances.isNotEmpty
              ? '${distances.reduce(math.min).toStringAsFixed(1)}–${distances.reduce(math.max).toStringAsFixed(1)} m'
              : '';
          if (defectIndices.isNotEmpty) {
            final imgLabel = defectIndices.length == 1
                ? 'Image ${defectIndices.first}'
                : 'Images ${defectIndices.join(', ')}';
            subtitle = '$imgLabel of ${phase.images.length}${distStr.isNotEmpty ? ' · $distStr' : ''}';
          } else {
            subtitle = '${phase.images.length} images';
          }

          final bool isCritical = phaseMissing > 2 || (phaseMissing == 1 && (circuit.circuitId.contains('NE') && phaseName == 'R'));
          final bool isNormal = phaseMissing == 0;

          rows.add(
            _buildDefectPhaseRow(
              title: '${circuit.circuitId.replaceAll('_', ' ')} · Phase $phaseName',
              subtitle: subtitle,
              count: '$phaseMissing',
              isCritical: isCritical,
              isNormal: isNormal,
            ),
          );
        }
      }

      // Earth peaks SW · NE
      if (tower.id.contains('400KV')) {
        rows.add(
          _buildDefectPhaseRow(
            title: 'Earth peaks SW · NE',
            subtitle: '6 images',
            count: '0',
            isNormal: true,
          ),
        );
      }

      return rows;
    }

    return [
      _buildDefectPhaseRow(
        title: 'Earth peaks SW · NE',
        subtitle: '6 images',
        count: '0',
        isNormal: true,
      ),
    ];
  }

  // --- HISTORY TAB CONTENT ---
  Widget _buildHistoryTabContent(MapTower tower) {
    if (!tower.isInspected) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No previous inspection history recorded for this tower.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ),
      );
    }

    final isCritical = tower.isCritical;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Text(
                    tower.surveyDate,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: isCritical ? const Color(0xFFFDE8E8) : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isCritical ? 'Critical condition' : 'Normal condition',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isCritical ? const Color(0xFFDC2626) : const Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- TABLE VIEW (strictly matching user reference) ---
  Widget _buildTableView(Circuit circuitSW, Phase? phaseR) {
    final visibleTowers = _filteredTowers;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 900;
    final rightMargin = (_isSidebarOpen && !isMobile) ? 430.0 : (screenWidth < 600 ? 12.0 : 24.0);
    final leftMargin = screenWidth < 600 ? 12.0 : 24.0;

    return Center(
      child: Container(
        margin: EdgeInsets.fromLTRB(leftMargin, 84, rightMargin, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Table Header Title matching reference image
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Text(
                    '$_selectedDate · ${visibleTowers.length} ${visibleTowers.length == 1 ? 'tower' : 'towers'}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.swap_vert, size: 16, color: Color(0xFF64748B)),
                      SizedBox(width: 4),
                      Text(
                        'Worst first',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Horizontal scroll container for table grid (columns + rows)
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tableWidth = math.max(constraints.maxWidth, 920.0);
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: tableWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Columns Header: TOWER, CONDITION, VOLTAGE, SITE, COORDINATES, FROM, TO, ACTION
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            color: const Color(0xFFF8FAFC),
                            child: Row(
                              children: const [
                                Expanded(flex: 4, child: Text('TOWER', style: _tableHeaderStyle)),
                                Expanded(flex: 2, child: Text('CONDITION', style: _tableHeaderStyle)),
                                Expanded(flex: 2, child: Text('VOLTAGE', style: _tableHeaderStyle)),
                                Expanded(flex: 2, child: Text('SITE', style: _tableHeaderStyle)),
                                Expanded(flex: 3, child: Text('COORDINATES', style: _tableHeaderStyle)),
                                Expanded(flex: 3, child: Text('FROM', style: _tableHeaderStyle)),
                                Expanded(flex: 3, child: Text('TO', style: _tableHeaderStyle)),
                                SizedBox(width: 75),
                              ],
                            ),
                          ),
                          const Divider(height: 1),

                          // Dynamic Rows for Visible Towers
                          Expanded(
                            child: ListView.separated(
                              primary: false,
                              itemCount: visibleTowers.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final tower = visibleTowers[index];
                  final isSelected = _isSidebarOpen && _selectedTower.id == tower.id;
                  final corridorInfo = TowerCorridorService.getInfo(tower.name) ??
                      TowerCorridorService.getInfo(tower.id);
                  final fromSub = corridorInfo?.fromSubstation ?? 'Meramundali';
                  final fromVillage = corridorInfo?.fromVillage ?? 'Joragadia, Anugul';
                  final toSub = corridorInfo?.toSubstation ?? 'Mendhasal';
                  final toVillage = corridorInfo?.toVillage ?? 'Mendhadsal, Khordha';

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTower = tower;
                        _isSidebarOpen = true;
                        _showCalendarDropdown = false;
                        _showVoltageDropdown = false;
                        _showBaseMapPopover = false;
                        _showInfoPopover = false;
                      });
                    },
                    child: Container(
                      color: isSelected ? const Color(0xFFF0F6FF) : Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Row(
                        children: [
                          // 1. Tower ID + circle icon + subtitle
                          Expanded(
                            flex: 4,
                            child: Row(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: tower.isCritical
                                        ? const Color(0xFFDB322E)
                                        : (tower.isInspected ? const Color(0xFF2E9D57) : const Color(0xFF707E94)),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    tower.isCritical
                                        ? Icons.close
                                        : (tower.isInspected ? Icons.check : Icons.remove),
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        tower.id,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Tower ${tower.towerNumber} · ${tower.voltage} line',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 2. Condition badge
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: tower.isCritical
                                      ? const Color(0xFFFDE8E8)
                                      : (tower.isInspected ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  tower.isCritical
                                      ? 'Critical'
                                      : (tower.isInspected ? 'Normal' : 'Not inspected'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: tower.isCritical
                                        ? const Color(0xFFB91C1C)
                                        : (tower.isInspected ? const Color(0xFF166534) : const Color(0xFF475569)),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // 3. Voltage
                          Expanded(
                            flex: 2,
                            child: Text(
                              tower.voltage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                            ),
                          ),

                          // 4. Site
                          Expanded(
                            flex: 2,
                            child: Text(
                              tower.site,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                            ),
                          ),

                          // 5. Coordinates
                          Expanded(
                            flex: 3,
                            child: Text(
                              '${tower.location.latitude.toStringAsFixed(6)},  ${tower.location.longitude.toStringAsFixed(6)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                            ),
                          ),

                          // 6. FROM Substation & Village
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  fromSub,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                if (fromVillage.isNotEmpty)
                                  Text(
                                    fromVillage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // 7. TO Substation & Village
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  toSub,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                if (toVillage.isNotEmpty)
                                  Text(
                                    toVillage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // 8. Action: Details >
                          SizedBox(
                            width: 75,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedTower = tower;
                                    _isSidebarOpen = true;
                                    _showCalendarDropdown = false;
                                    _showVoltageDropdown = false;
                                    _showBaseMapPopover = false;
                                    _showInfoPopover = false;
                                  });
                                },
                                child: const Text(
                                  'Details >',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1967D2),
                                  ),
                                ),
                              ),
                            ),
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
),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widgets
  _TowerCropInfo? _getTowerCropInfo(String towerId) {
    if (towerId.contains('400KV') || towerId.contains('400')) {
      return const _TowerCropInfo(rawW: 1920, rawH: 1080, bx: 761.7, by: 177.4, bw: 337.4, bh: 725.9);
    }
    if (towerId.contains('135KV') || towerId.contains('135')) {
      if (towerId.contains('T02') || towerId.contains('Tower 2') || towerId.contains('Tower_2')) {
        return const _TowerCropInfo(rawW: 1920, rawH: 1080, bx: 771.7, by: 12.7, bw: 414.0, bh: 1060.8);
      }
      return const _TowerCropInfo(rawW: 1920, rawH: 1080, bx: 794.3, by: 28.7, bw: 322.2, bh: 992.3);
    }
    if (towerId.contains('220KV-SA') || (towerId.contains('220') && towerId.contains('SA'))) {
      if (towerId.contains('T02') || towerId.contains('Tower 2') || towerId.contains('Tower_2')) {
        return const _TowerCropInfo(rawW: 3840, rawH: 2160, bx: 1656.7, by: 740.2, bw: 531.3, bh: 1413.9);
      }
      return const _TowerCropInfo(rawW: 3840, rawH: 2160, bx: 1050.6, by: 569.9, bw: 876.1, bh: 1565.4);
    }
    if (towerId.contains('220KV-SB') || (towerId.contains('220') && towerId.contains('SB'))) {
      if (towerId.contains('T02') || towerId.contains('Tower 2') || towerId.contains('Tower_2')) {
        return const _TowerCropInfo(rawW: 3840, rawH: 2160, bx: 1538.9, by: 271.5, bw: 892.0, bh: 1711.1);
      }
      return const _TowerCropInfo(rawW: 3840, rawH: 2160, bx: 1657.1, by: 774.4, bw: 433.0, bh: 1084.3);
    }
    return null;
  }

  Widget _buildTowerThumbnail(MapTower tower, String imagePath) {
    const double thumbW = 96.0;
    const double thumbH = 80.0;
    final crop = _getTowerCropInfo(tower.id) ?? _getTowerCropInfo(tower.name);

    if (crop != null) {
      final double padH = (crop.bw * 0.35).clamp(30.0, crop.rawW);
      final double padV = (crop.bh * 0.08).clamp(20.0, crop.rawH);
      final double cropLeft = (crop.bx - padH).clamp(0.0, crop.rawW);
      final double cropTop = (crop.by - padV).clamp(0.0, crop.rawH);
      final double cropW = (crop.bw + 2 * padH).clamp(50.0, crop.rawW - cropLeft);
      final double cropH = (crop.bh + 2 * padV).clamp(50.0, crop.rawH - cropTop);

      final double scaleX = thumbW / cropW;
      final double scaleY = thumbH / cropH;
      final double scale = math.max(scaleX, scaleY);

      final double renderImgW = crop.rawW * scale;
      final double renderImgH = crop.rawH * scale;

      final double cropCenterInRenderX = (cropLeft + cropW / 2) * scale;
      final double cropCenterInRenderY = (cropTop + cropH / 2) * scale;

      final double leftOffset = (thumbW / 2) - cropCenterInRenderX;
      final double topOffset = (thumbH / 2) - cropCenterInRenderY;

      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: thumbW,
          height: thumbH,
          color: const Color(0xFF0F172A),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: leftOffset,
                top: topOffset,
                width: renderImgW,
                height: renderImgH,
                child: ImageService.buildImage(
                  imagePath: imagePath,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: thumbW,
        height: thumbH,
        child: Transform.scale(
          scale: 1.8,
          child: ImageService.buildImage(
            imagePath: imagePath,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }

  Widget _buildPillTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
      ),
    );
  }

  Widget _buildSidebarTab(String label, int index, {String? count, bool isRed = false}) {
    final isSelected = _activeTab == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? const Color(0xFF1967D2) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF1967D2) : const Color(0xFF64748B),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isRed ? const Color(0xFFFDE8E8) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isRed ? const Color(0xFFB91C1C) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridButton() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isGridActive ? const Color(0xFF1E60B5).withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: _isGridActive
                ? const Color(0xFF1E60B5).withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoadingGrid ? null : _toggleGrid,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoadingGrid)
                  const SizedBox(
                    width: 32,
                    height: 18,
                    child: Center(
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E60B5)),
                      ),
                    ),
                  )
                else
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: 36,
                    height: 20,
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: _isGridActive ? const Color(0xFF1E60B5) : const Color(0xFFCBD5E1),
                    ),
                    alignment: _isGridActive ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(width: 10),
                Text(
                  'Grid',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: _isGridActive ? const Color(0xFF1E60B5) : const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConditionCard(List<MapTower> visibleTowers, int criticalCount, int normalCount, int uninspectedCount) {
    return Container(
      width: 165,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CONDITION',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${visibleTowers.length} ${visibleTowers.length == 1 ? 'tower' : 'towers'}',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildConditionRow(const Color(0xFFDB322E), Icons.close, 'Critical', '$criticalCount'),
          const SizedBox(height: 4),
          _buildConditionRow(const Color(0xFFF97316), Icons.priority_high, 'Major', '0'),
          const SizedBox(height: 4),
          _buildConditionRow(const Color(0xFFFBBF24), Icons.priority_high, 'Minor', '0'),
          const SizedBox(height: 4),
          _buildConditionRow(const Color(0xFF22C55E), Icons.check, 'Normal', '$normalCount'),
          const SizedBox(height: 4),
          _buildConditionRow(const Color(0xFF707E94), Icons.remove, 'Not inspected', '$uninspectedCount'),
        ],
      ),
    );
  }

  Widget _buildPowerNetworkLegendCard() {
    return Container(
      width: 325,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: const [
              Text(
                'POWER NETWORK',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569),
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lines from Meramundali · OpenStreetMap',
                  style: TextStyle(
                    fontSize: 8.5,
                    color: Color(0xFF94A3B8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column 1
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLegendLineItem(const Color(0xFF7631EC), 'Mendhasal 400 kV', strokeWidth: 4.0),
                    const SizedBox(height: 5),
                    _buildLegendLineItem(const Color(0xFF366FED), 'Bhanjanagar 220 kV', strokeWidth: 2.8),
                    const SizedBox(height: 5),
                    _buildLegendLineItem(const Color(0xFF47AEA5), 'Gundicha Pada 132 kV', strokeWidth: 1.6),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                          child: const Center(
                            child: Icon(Icons.flash_on, size: 9, color: Color(0xFFFBBF24)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Source',
                          style: TextStyle(fontSize: 10, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Column 2
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLegendLineItem(const Color(0xFFD91D71), 'Duburi (New) 400 kV', strokeWidth: 4.0),
                    const SizedBox(height: 5),
                    _buildLegendLineItem(const Color(0xFF19BCD7), 'Joda / Duburi (Old) 220 kV', strokeWidth: 2.8),
                    const SizedBox(height: 5),
                    _buildLegendLineItem(const Color(0xFFA78565), 'Charagadia 132 kV', strokeWidth: 1.6),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendLineItem(Color color, String label, {double strokeWidth = 3.0}) {
    return Row(
      children: [
        Container(
          width: 14,
          height: strokeWidth,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(strokeWidth / 2),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF334155),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  LatLng? _findVisiblePointOnRoute(GridRoute route, LatLngBounds bounds) {
    if (route.points.isEmpty) return null;

    final minLat = math.min(bounds.southWest.latitude, bounds.northEast.latitude);
    final maxLat = math.max(bounds.southWest.latitude, bounds.northEast.latitude);
    final minLng = math.min(bounds.southWest.longitude, bounds.northEast.longitude);
    final maxLng = math.max(bounds.southWest.longitude, bounds.northEast.longitude);

    // 1. Check if any route points are inside the current visible bounds
    final insidePoints = <LatLng>[];
    for (final pt in route.points) {
      if (pt.latitude >= minLat && pt.latitude <= maxLat && pt.longitude >= minLng && pt.longitude <= maxLng) {
        insidePoints.add(pt);
      }
    }

    if (insidePoints.isNotEmpty) {
      return insidePoints[insidePoints.length ~/ 2];
    }

    // 2. If no discrete vertex is inside, check if any line segment crosses the viewport
    for (int i = 0; i < route.points.length - 1; i++) {
      final p1 = route.points[i];
      final p2 = route.points[i + 1];
      final segMinLat = math.min(p1.latitude, p2.latitude);
      final segMaxLat = math.max(p1.latitude, p2.latitude);
      final segMinLng = math.min(p1.longitude, p2.longitude);
      final segMaxLng = math.max(p1.longitude, p2.longitude);

      if (segMaxLat >= minLat && segMinLat <= maxLat && segMaxLng >= minLng && segMinLng <= maxLng) {
        final midLat = ((p1.latitude + p2.latitude) / 2.0).clamp(
          minLat + (maxLat - minLat) * 0.2,
          maxLat - (maxLat - minLat) * 0.2,
        );
        final midLng = ((p1.longitude + p2.longitude) / 2.0).clamp(
          minLng + (maxLng - minLng) * 0.2,
          maxLng - (maxLng - minLng) * 0.2,
        );
        return LatLng(midLat, midLng);
      }
    }

    return null;
  }

  Widget _buildRouteMarker(GridRoute route, bool isSelected) {
    if (isSelected) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pop-up bubble with route text and close button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: route.color, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: route.color, width: 1.2),
                  ),
                  child: Center(
                    child: _ItalicInfoIcon(
                      size: 9.0,
                      color: route.color,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  route.calloutLabel.isNotEmpty ? route.calloutLabel : route.name,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    setState(() {
                      _selectedGridRoute = null;
                    });
                  },
                  child: const Icon(Icons.close, size: 14, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          CustomPaint(
            size: const Size(10, 5),
            painter: _TrianglePainter(color: route.color),
          ),
          const SizedBox(height: 2),
          _buildCircleLegend(route, isSelected: true),
        ],
      );
    }

    // Normal state: Legend with circle around it (no text on the map until clicked)
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedGridRoute = route;
            _selectedGridSubstation = null;
          });
        },
        child: Tooltip(
          message: route.calloutLabel.isNotEmpty ? route.calloutLabel : route.name,
          child: _buildCircleLegend(route, isSelected: false),
        ),
      ),
    );
  }

  Widget _buildCircleLegend(GridRoute route, {required bool isSelected}) {
    return Container(
      width: isSelected ? 20 : 17,
      height: isSelected ? 20 : 17,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: route.color,
          width: isSelected ? 1.8 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: _ItalicInfoIcon(
          size: isSelected ? 12.5 : 10.5,
          color: route.color,
        ),
      ),
    );
  }

  Widget _buildRouteDetailPopup(GridRoute route) {
    return Container(
      width: 290,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: route.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  route.name,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () => setState(() => _selectedGridRoute = null),
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close, size: 16, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: route.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${route.voltage} Transmission Corridor · ${route.lengthKm.toStringAsFixed(1)} km',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: route.color,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildPopupRow(Icons.radio_button_checked, 'From', route.fromSubstation.isNotEmpty ? route.fromSubstation : 'Meramundali'),
          const SizedBox(height: 5),
          _buildPopupRow(Icons.location_on_outlined, 'To', route.toSubstation.isNotEmpty ? route.toSubstation : route.toVillage),
          if (route.toVillage.isNotEmpty) ...[
            const SizedBox(height: 5),
            _buildPopupRow(Icons.holiday_village_outlined, 'Destination Village', route.toVillage),
          ],
        ],
      ),
    );
  }

  Widget _buildSubstationBadge(GridSubstation sub, bool isSelected) {
    final displayName = sub.name.toLowerCase().endsWith('substation')
        ? sub.name
        : '${sub.name} substation';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _selectedGridSubstation = sub;
          _selectedGridRoute = null;
        });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Black squircle badge with yellow lightning bolt & crisp white border
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF7631EC) : const Color(0xFF181B22),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFD8B4FE) : Colors.white,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.flash_on,
                    size: 17,
                    color: Color(0xFFFBBF24),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // 2. White rounded chip with dark substation text matching zoomed-out UI
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF3E8FF) : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF7631EC) : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                child: Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? const Color(0xFF7631EC) : const Color(0xFF1E293B),
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubstationDetailPopup(GridSubstation sub) {
    final title = sub.name.toLowerCase().endsWith('substation')
        ? sub.name
        : '${sub.name} Substation';

    return Container(
      width: 280,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFF181B22),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.flash_on, size: 15, color: Color(0xFFFBBF24)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              InkWell(
                onTap: () => setState(() => _selectedGridSubstation = null),
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close, size: 16, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF7631EC).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Voltage Levels: ${sub.voltage}',
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7631EC),
              ),
            ),
          ),
          if (sub.village.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildPopupRow(Icons.place_outlined, 'Location', sub.village),
          ],
          const SizedBox(height: 5),
          _buildPopupRow(Icons.grid_on_outlined, 'Status', 'Active Grid Substation'),
        ],
      ),
    );
  }

  Widget _buildPopupRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConditionRow(Color color, IconData icon, String label, String count) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 9, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
          ),
        ),
        Text(
          count,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
      ],
    );
  }

  Widget _buildDefectPhaseRow({
    required String title,
    required String subtitle,
    required String count,
    bool isCritical = false,
    bool isNormal = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Text(
            count,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isCritical
                  ? const Color(0xFFFDE8E8)
                  : isNormal
                      ? const Color(0xFFDEF7EC)
                      : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isCritical
                  ? 'CRITICAL'
                  : isNormal
                      ? 'NORMAL'
                      : 'NOT FLAGGED',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: isCritical
                    ? const Color(0xFFB91C1C)
                    : isNormal
                        ? const Color(0xFF03543F)
                        : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _tableHeaderStyle = TextStyle(
  fontSize: 11,
  fontWeight: FontWeight.bold,
  color: Color(0xFF64748B),
  letterSpacing: 0.5,
);

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) => oldDelegate.color != color;
}

class _CalendarDayHeader extends StatelessWidget {
  final String day;
  const _CalendarDayHeader(this.day);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      child: Center(
        child: Text(
          day,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// PENPOT REPLICATED CUSTOM WIDGETS & PAINTERS
// ==========================================

/// Teardrop Map Pin matching Penpot pin exactly (2.png and 2_sidebar.png)
class TowerPinWidget extends StatelessWidget {
  final String label;
  final Color fillColor;
  final bool isSelected;
  final VoidCallback? onTap;

  const TowerPinWidget({
    super.key,
    required this.label,
    required this.fillColor,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 26,
        height: 36,
        child: CustomPaint(
          size: const Size(26, 36),
          painter: _TowerPinPainter(
            fillColor: fillColor,
            symbol: label,
            isSelected: isSelected,
          ),
        ),
      ),
    );
  }
}

class _TowerPinPainter extends CustomPainter {
  final Color fillColor;
  final String symbol; // '-' or '✕'
  final bool isSelected;

  const _TowerPinPainter({
    required this.fillColor,
    required this.symbol,
    this.isSelected = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double r = w / 2;
    final double cx = w / 2;
    final double cy = r;

    // Smooth teardrop path: circular head at top, clean taper to bottom tip (cx, h)
    final path = Path()
      ..moveTo(cx, h)
      ..cubicTo(cx - 1.2, h - 7.5, 0, cy + 6.0, 0, cy)
      ..arcToPoint(
        Offset(w, cy),
        radius: Radius.circular(r),
        clockwise: true,
      )
      ..cubicTo(w, cy + 6.0, cx + 1.2, h - 7.5, cx, h)
      ..close();

    // Subtle outer halo when selected
    if (isSelected) {
      final glowPaint = Paint()
        ..color = const Color(0xFF3B82F6).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;
      canvas.drawPath(path, glowPaint);
    }

    // Drop shadow
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.32), 3.5, false);

    // Colored body fill
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Crisp white border
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, strokePaint);

    // Inner symbol strictly and perfectly centered at (cx, cy)
    final symbolPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    if (symbol == '-') {
      // Crisp horizontal minus bar
      const double halfWidth = 4.2;
      canvas.drawLine(
        Offset(cx - halfWidth, cy),
        Offset(cx + halfWidth, cy),
        symbolPaint,
      );
    } else if (symbol == '✓') {
      // Crisp check / tick mark centered at (cx, cy)
      final checkPath = Path()
        ..moveTo(cx - 3.8, cy + 0.2)
        ..lineTo(cx - 1.0, cy + 3.0)
        ..lineTo(cx + 4.2, cy - 2.8);
      canvas.drawPath(
        checkPath,
        symbolPaint
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    } else {
      // Crisp cross (✕) centered exactly at (cx, cy)
      const double arm = 3.5;
      canvas.drawLine(
        Offset(cx - arm, cy - arm),
        Offset(cx + arm, cy + arm),
        symbolPaint,
      );
      canvas.drawLine(
        Offset(cx - arm, cy + arm),
        Offset(cx + arm, cy - arm),
        symbolPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TowerPinPainter oldDelegate) =>
      oldDelegate.fillColor != fillColor || oldDelegate.symbol != symbol;
}

/// Donut Ring Painter for cluster count matching reference image
class _ClusterDonutPainter extends CustomPainter {
  final int totalCount;
  final int criticalCount;
  final int normalCount;
  final int uninspectedCount;

  const _ClusterDonutPainter({
    required this.totalCount,
    required this.criticalCount,
    this.normalCount = 0,
    required this.uninspectedCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 4.5;

    // Drop shadow
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Inner white disc
    canvas.drawCircle(
      center,
      radius - strokeWidth / 2,
      Paint()..color = Colors.white,
    );

    if (totalCount <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);
    final paintCritical = Paint()
      ..color = const Color(0xFFDB322E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final paintNormal = Paint()
      ..color = const Color(0xFF2E9D57)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final paintUninspected = Paint()
      ..color = const Color(0xFF707E94)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    double startAngle = -math.pi / 2;

    if (criticalCount > 0) {
      final sweep = (criticalCount / totalCount) * 2 * math.pi;
      canvas.drawArc(rect, startAngle, sweep, false, paintCritical);
      startAngle += sweep;
    }
    if (normalCount > 0) {
      final sweep = (normalCount / totalCount) * 2 * math.pi;
      canvas.drawArc(rect, startAngle, sweep, false, paintNormal);
      startAngle += sweep;
    }
    if (uninspectedCount > 0) {
      final sweep = (uninspectedCount / totalCount) * 2 * math.pi;
      canvas.drawArc(rect, startAngle, sweep, false, paintUninspected);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _ClusterDonutPainter oldDelegate) {
    return oldDelegate.totalCount != totalCount ||
        oldDelegate.criticalCount != criticalCount ||
        oldDelegate.normalCount != normalCount ||
        oldDelegate.uninspectedCount != uninspectedCount;
  }
}

/// Compass Arrow Needle pointing towards N (matching Penpot North up button)
class _NorthNeedlePainter extends CustomPainter {
  final Color color;
  const _NorthNeedlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Classic navigation arrowhead pointing UP
    final path = Path()
      ..moveTo(w / 2, 0)
      ..lineTo(w, h)
      ..lineTo(w / 2, h * 0.72)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _NorthNeedlePainter oldDelegate) => oldDelegate.color != color;
}

/// 3 Stacked Layers Icon (matching Penpot Base map button)
class _LayersIconPainter extends CustomPainter {
  final Color color;
  const _LayersIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    final top = Path()
      ..moveTo(w / 2, 1)
      ..lineTo(w - 1, h * 0.32)
      ..lineTo(w / 2, h * 0.60)
      ..lineTo(1, h * 0.32)
      ..close();
    canvas.drawPath(top, paint);

    final mid = Path()
      ..moveTo(1, h * 0.52)
      ..lineTo(w / 2, h * 0.80)
      ..lineTo(w - 1, h * 0.52);
    canvas.drawPath(mid, paint);

    final bot = Path()
      ..moveTo(1, h * 0.72)
      ..lineTo(w / 2, h)
      ..lineTo(w - 1, h * 0.72);
    canvas.drawPath(bot, paint);
  }

  @override
  bool shouldRepaint(covariant _LayersIconPainter oldDelegate) => oldDelegate.color != color;
}

/// Scale bracket |____________| matching Penpot bottom scale bar
class _ScaleBracketPainter extends CustomPainter {
  final Color color;
  const _ScaleBracketPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.square;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ScaleBracketPainter oldDelegate) => oldDelegate.color != color;
}

/// Street Map Mini Graphic Thumbnail (matching Penpot Base map popup)
class _StreetMapThumbnailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = const Color(0xFFF4EFE1));

    final greenPaint = Paint()..color = const Color(0xFFCDE8B5);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.45, 0, size.width * 0.55, size.height * 0.45), const Radius.circular(8)), greenPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, size.height * 0.6, size.width * 0.35, size.height * 0.4), const Radius.circular(8)), greenPaint);

    final riverPaint = Paint()
      ..color = const Color(0xFFA7D5E8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final riverPath = Path()
      ..moveTo(0, size.height * 0.85)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.8, size.width, size.height * 0.82);
    canvas.drawPath(riverPath, riverPaint);

    final roadPaint = Paint()
      ..color = const Color(0xFFF9C86A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final roadPath = Path()
      ..moveTo(0, size.height * 0.42)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.4, size.width, size.height * 0.44);
    canvas.drawPath(roadPath, roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Satellite Aerial Mini Graphic Thumbnail (matching Penpot Base map popup)
class _SatelliteThumbnailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = const Color(0xFF4A5D3F));

    final plot1 = Paint()..color = const Color(0xFF384630);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width * 0.48, size.height * 0.5), plot1);

    final plot2 = Paint()..color = const Color(0xFF6B7B4B);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.52, 0, size.width * 0.48, size.height * 0.55), plot2);

    final plot3 = Paint()..color = const Color(0xFF566545);
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.55, size.width * 0.45, size.height * 0.45), plot3);

    final riverPaint = Paint()
      ..color = const Color(0xFF28363F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final riverPath = Path()
      ..moveTo(0, size.height * 0.82)
      ..lineTo(size.width, size.height * 0.80);
    canvas.drawPath(riverPath, riverPaint);

    final roadPaint = Paint()
      ..color = const Color(0xFF8E8876)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final roadPath = Path()
      ..moveTo(0, size.height * 0.45)
      ..lineTo(size.width, size.height * 0.46);
    canvas.drawPath(roadPath, roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Curved italic info "i" icon exactly replicating the user provided vector symbol
class _ItalicInfoIcon extends StatelessWidget {
  final double size;
  final Color color;

  const _ItalicInfoIcon({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final w = size * 0.54;
    return SizedBox(
      width: w,
      height: size,
      child: CustomPaint(
        size: Size(w, size),
        painter: _ItalicInfoPainter(color: color),
      ),
    );
  }
}

class _ItalicInfoPainter extends CustomPainter {
  final Color color;

  const _ItalicInfoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    // 1. Circular dot at the top
    final dotCenter = Offset(0.694 * w, 0.122 * h);
    final dotRadius = 0.122 * h;
    canvas.drawCircle(dotCenter, dotRadius, paint);

    // 2. Curved italic body path matching the exact user silhouette
    final path = Path();
    const pts = [
      Offset(0.5075, 0.2992),
      Offset(0.7164, 0.2992),
      Offset(0.791, 0.3307),
      Offset(0.791, 0.3937),
      Offset(0.7612, 0.4252),
      Offset(0.7015, 0.5669),
      Offset(0.6716, 0.5984),
      Offset(0.6269, 0.7165),
      Offset(0.5821, 0.7795),
      Offset(0.5672, 0.8425),
      Offset(0.6269, 0.8819),
      Offset(0.6716, 0.8898),
      Offset(0.8657, 0.8819),
      Offset(1.0, 0.8504),
      Offset(1.0, 0.8976),
      Offset(0.9403, 0.9213),
      Offset(0.7612, 0.9606),
      Offset(0.7164, 0.9606),
      Offset(0.6119, 0.9843),
      Offset(0.4925, 0.9921),
      Offset(0.4776, 1.0),
      Offset(0.2985, 1.0),
      Offset(0.2537, 0.9921),
      Offset(0.209, 0.9685),
      Offset(0.209, 0.9055),
      Offset(0.2388, 0.874),
      Offset(0.2836, 0.7559),
      Offset(0.3433, 0.6693),
      Offset(0.3881, 0.5512),
      Offset(0.4179, 0.5197),
      Offset(0.4328, 0.4567),
      Offset(0.4179, 0.4409),
      Offset(0.3433, 0.4094),
      Offset(0.194, 0.4094),
      Offset(0.0448, 0.4331),
      Offset(0.0, 0.4488),
      Offset(0.0, 0.4016),
      Offset(0.0597, 0.378),
      Offset(0.2388, 0.3386),
      Offset(0.4925, 0.3071),
    ];

    path.moveTo(pts[0].dx * w, pts[0].dy * h);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx * w, pts[i].dy * h);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ItalicInfoPainter oldDelegate) => oldDelegate.color != color;
}

class _TowerCropInfo {
  final double rawW;
  final double rawH;
  final double bx;
  final double by;
  final double bw;
  final double bh;

  const _TowerCropInfo({
    required this.rawW,
    required this.rawH,
    required this.bx,
    required this.by,
    required this.bw,
    required this.bh,
  });
}



