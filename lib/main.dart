import 'package:flutter/material.dart';
import 'config/app_theme.dart';
import 'screens/inspection_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TowerLensApp());
}

class TowerLensApp extends StatelessWidget {
  const TowerLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TowerLens',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const InspectionScreen(),
    );
  }
}

/// Backwards compatibility alias
typedef KnoGridApp = TowerLensApp;
