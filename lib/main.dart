import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'screens/inspection_screen.dart';
import 'services/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TowerLensApp());
}

class TowerLensApp extends StatelessWidget {
  const TowerLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provide AppState across the whole app for session and screen state persistence
    return ChangeNotifierProvider(
      create: (_) => AppState()..loadSavedSession(),
      child: MaterialApp(
        title: 'TowerLens',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const InspectionScreen(),
      ),
    );
  }
}

/// Backwards compatibility alias
typedef KnoGridApp = TowerLensApp;
