import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_proj/services/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppState State Management & Website Restart Persistence Tests', () {
    test('Initial unauthenticated state defaults to signIn', () async {
      SharedPreferences.setMockInitialValues({});
      final state = AppState();
      await state.loadSavedSession();

      expect(state.isLoggedIn, false);
      expect(state.currentView, AppView.signIn);
      expect(state.isInitialized, true);
    });

    test('User login transitions to networkMap view', () async {
      SharedPreferences.setMockInitialValues({});
      final state = AppState();
      await state.loadSavedSession();

      await state.login();

      expect(state.isLoggedIn, true);
      expect(state.currentView, AppView.networkMap);
    });

    test('Simulate Browser Refresh (F5 / Restart) on 2nd Page (Inspection)', () async {
      // 1. User was on 2nd page with active circuit & phase before refreshing the browser
      SharedPreferences.setMockInitialValues({
        'towerlens_is_logged_in': true,
        'towerlens_last_screen': 'inspection',
        'towerlens_selected_tower_id': 'T01-400KV-SB',
        'towerlens_selected_voltage': '400 kV',
        'towerlens_selected_date': '20 Apr 2026',
        'towerlens_selected_circuit_id': 'Circuit_1',
        'towerlens_selected_phase_name': 'R',
      });

      // 2. Browser restarts/reloads: AppState initializes
      final state = AppState();
      await state.loadSavedSession();

      // 3. User remains on the 2nd page with selections fully intact
      expect(state.isLoggedIn, true);
      expect(state.currentView, AppView.inspection);
      expect(state.selectedTowerId, 'T01-400KV-SB');
      expect(state.selectedVoltage, '400 kV');
      expect(state.selectedDate, '20 Apr 2026');
      expect(state.selectedCircuitId, 'Circuit_1');
      expect(state.selectedPhaseName, 'R');
    });

    test('Navigating between Map and Inspection preserves active state', () async {
      SharedPreferences.setMockInitialValues({'towerlens_is_logged_in': true});
      final state = AppState();
      await state.loadSavedSession();

      // Set custom date and voltage on Map
      await state.setSelectedDate('15 May 2026');
      await state.setSelectedVoltage('220 kV');

      // Navigate to 2nd page
      await state.navigateToInspection(
        towerId: 'T01-400KV-SB',
        circuitId: 'Circuit_2',
        phaseName: 'Y',
      );

      expect(state.currentView, AppView.inspection);
      expect(state.selectedCircuitId, 'Circuit_2');
      expect(state.selectedPhaseName, 'Y');

      // Navigate back to 1st page (Map)
      await state.navigateToMap();
      expect(state.currentView, AppView.networkMap);
      // Verify date and voltage are preserved!
      expect(state.selectedDate, '15 May 2026');
      expect(state.selectedVoltage, '220 kV');
    });

    test('Logout clears session and returns to signIn view', () async {
      SharedPreferences.setMockInitialValues({
        'towerlens_is_logged_in': true,
        'towerlens_last_screen': 'inspection',
      });
      final state = AppState();
      await state.loadSavedSession();

      await state.logout();

      expect(state.isLoggedIn, false);
      expect(state.currentView, AppView.signIn);
    });
  });
}
