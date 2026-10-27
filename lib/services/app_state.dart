import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Navigation views in TowerLens Intelligence
enum AppView {
  /// Screen 1: Sign in page
  signIn,

  /// Screen 2: Transmission network map & table view
  networkMap,

  /// Screen 3: Tower inspection, structure, and detailed crops
  inspection,
}

/// AppState: Centralized State Management & Session Persistence
///
/// Handles:
/// 1. Persistent User Login session (survives website reload/restart).
/// 2. Active Screen Persistence (reloading while on the 2nd page stays on the 2nd page).
/// 3. Cross-page State Synchronization (preserves selected tower, voltage, date
///    when navigating back and forth between Map and Inspection).
class AppState extends ChangeNotifier {
  // Storage keys for browser localStorage / SharedPreferences
  static const String _keyIsLoggedIn = 'towerlens_is_logged_in';
  static const String _keyLastScreen = 'towerlens_last_screen';
  static const String _keySelectedDate = 'towerlens_selected_date';
  static const String _keySelectedVoltage = 'towerlens_selected_voltage';
  static const String _keySelectedTowerId = 'towerlens_selected_tower_id';
  static const String _keySelectedCircuitId = 'towerlens_selected_circuit_id';
  static const String _keySelectedPhaseName = 'towerlens_selected_phase_name';
  static const String _keySelectedCorridorTop = 'towerlens_selected_corridor_top';
  static const String _keySelectedCorridorBottom = 'towerlens_selected_corridor_bottom';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  AppView _currentView = AppView.signIn;
  AppView get currentView => _currentView;

  String _selectedDate = '20 Apr 2026';
  String get selectedDate => _selectedDate;

  String _selectedVoltage = 'All voltages';
  String get selectedVoltage => _selectedVoltage;

  String _selectedTowerId = 'T01-400KV-SA';
  String get selectedTowerId => _selectedTowerId;

  String? _selectedCircuitId;
  String? get selectedCircuitId => _selectedCircuitId;

  String? _selectedPhaseName;
  String? get selectedPhaseName => _selectedPhaseName;

  String? _selectedCorridorTop;
  String? get selectedCorridorTop => _selectedCorridorTop;

  String? _selectedCorridorBottom;
  String? get selectedCorridorBottom => _selectedCorridorBottom;

  Future<void> setSelectedCorridor(String? top, String? bottom) async {
    _selectedCorridorTop = top;
    _selectedCorridorBottom = bottom;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      if (top != null) {
        await prefs.setString(_keySelectedCorridorTop, top);
      } else {
        await prefs.remove(_keySelectedCorridorTop);
      }
      if (bottom != null) {
        await prefs.setString(_keySelectedCorridorBottom, bottom);
      } else {
        await prefs.remove(_keySelectedCorridorBottom);
      }
    } catch (e) {
      debugPrint('Error saving selected corridor: $e');
    }
  }

  /// Loads the saved session when the website starts or refreshes (F5 / ↻).
  /// If the user was logged in and viewing the 2nd page (Inspection),
  /// they stay on the 2nd page with their selected tower!
  Future<void> loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;

      if (_isLoggedIn) {
        final lastScreen = prefs.getString(_keyLastScreen) ?? 'networkMap';
        // Restore the exact screen the user was on before restarting
        _currentView = (lastScreen == 'inspection')
            ? AppView.inspection
            : AppView.networkMap;

        // Restore saved map filters and tower selection (defaults to latest 20 Apr 2026)
        _selectedDate = prefs.getString(_keySelectedDate) ?? '20 Apr 2026';
        _selectedVoltage = prefs.getString(_keySelectedVoltage) ?? 'All voltages';
        _selectedTowerId = prefs.getString(_keySelectedTowerId) ?? 'T01-400KV-SA';
        _selectedCircuitId = prefs.getString(_keySelectedCircuitId);
        _selectedPhaseName = prefs.getString(_keySelectedPhaseName);
        _selectedCorridorTop = prefs.getString(_keySelectedCorridorTop);
        _selectedCorridorBottom = prefs.getString(_keySelectedCorridorBottom);
      } else {
        _currentView = AppView.signIn;
      }
    } catch (e) {
      debugPrint('Error loading saved session: $e');
      _currentView = AppView.signIn;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Logs the user in and saves session to browser storage
  Future<void> login() async {
    _isLoggedIn = true;
    _currentView = AppView.networkMap;
    // Always start with the latest date towers on initial login
    _selectedDate = '20 Apr 2026';
    _selectedVoltage = 'All voltages';
    _selectedTowerId = 'T01-400KV-SA';
    _selectedCorridorTop = null;
    _selectedCorridorBottom = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setString(_keyLastScreen, 'networkMap');
      await prefs.setString(_keySelectedDate, '20 Apr 2026');
      await prefs.setString(_keySelectedVoltage, 'All voltages');
      await prefs.setString(_keySelectedTowerId, 'T01-400KV-SA');
    } catch (e) {
      debugPrint('Error saving login session: $e');
    }
  }

  /// Logs out the user and clears the session
  Future<void> logout() async {
    _isLoggedIn = false;
    _currentView = AppView.signIn;
    _selectedDate = '20 Apr 2026';
    _selectedVoltage = 'All voltages';
    _selectedTowerId = 'T01-400KV-SA';
    _selectedCorridorTop = null;
    _selectedCorridorBottom = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, false);
      await prefs.remove(_keyLastScreen);
      await prefs.remove(_keySelectedDate);
      await prefs.remove(_keySelectedVoltage);
      await prefs.remove(_keySelectedTowerId);
    } catch (e) {
      debugPrint('Error clearing login session: $e');
    }
  }

  String? _returnFromInspectionTowerId;
  String? get returnFromInspectionTowerId => _returnFromInspectionTowerId;

  /// Navigates to the 1st page (Network Map), optionally focusing on the inspected tower
  Future<void> navigateToMap({String? returnTowerId}) async {
    _currentView = AppView.networkMap;
    if (returnTowerId != null && returnTowerId.isNotEmpty) {
      _returnFromInspectionTowerId = returnTowerId;
      _selectedTowerId = returnTowerId;
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastScreen, 'networkMap');
    } catch (e) {
      debugPrint('Error saving navigation state: $e');
    }
  }

  /// Clears the return focus once handled by the map
  void clearReturnFocus() {
    _returnFromInspectionTowerId = null;
  }

  /// Navigates to the 2nd page (Inspection) for a selected tower, circuit, and phase
  Future<void> navigateToInspection({
    String? towerId,
    String? circuitId,
    String? phaseName,
  }) async {
    _currentView = AppView.inspection;
    _returnFromInspectionTowerId = null;
    if (towerId != null && towerId.isNotEmpty) {
      _selectedTowerId = towerId;
    }
    _selectedCircuitId = circuitId;
    _selectedPhaseName = phaseName;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastScreen, 'inspection');
      if (towerId != null) {
        await prefs.setString(_keySelectedTowerId, towerId);
      }
      if (circuitId != null) {
        await prefs.setString(_keySelectedCircuitId, circuitId);
      } else {
        await prefs.remove(_keySelectedCircuitId);
      }
      if (phaseName != null) {
        await prefs.setString(_keySelectedPhaseName, phaseName);
      } else {
        await prefs.remove(_keySelectedPhaseName);
      }
    } catch (e) {
      debugPrint('Error saving inspection navigation state: $e');
    }
  }

  /// Updates map date filter and persists it
  Future<void> setSelectedDate(String date) async {
    if (_selectedDate == date) return;
    _selectedDate = date;
    _selectedVoltage = 'All voltages';
    _selectedCorridorTop = null;
    _selectedCorridorBottom = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySelectedDate, date);
      await prefs.setString(_keySelectedVoltage, 'All voltages');
      await prefs.remove(_keySelectedCorridorTop);
      await prefs.remove(_keySelectedCorridorBottom);
    } catch (e) {
      debugPrint('Error saving selected date: $e');
    }
  }

  /// Updates map voltage filter and persists it
  Future<void> setSelectedVoltage(String voltage) async {
    if (_selectedVoltage == voltage) return;
    _selectedVoltage = voltage;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySelectedVoltage, voltage);
    } catch (e) {
      debugPrint('Error saving selected voltage: $e');
    }
  }

  /// Updates active tower on map and persists it
  Future<void> setSelectedTowerId(String towerId) async {
    if (_selectedTowerId == towerId) return;
    _selectedTowerId = towerId;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySelectedTowerId, towerId);
    } catch (e) {
      debugPrint('Error saving selected tower: $e');
    }
  }
}
