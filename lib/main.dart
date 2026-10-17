import 'package:flutter/material.dart';
import 'config/app_theme.dart';
import 'screens/inspection_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KnoGridApp());
}

class KnoGridApp extends StatelessWidget {
  const KnoGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KnoGrid — Transmission Infrastructure Intelligence',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const InspectionScreen(),
    );
  }
}
