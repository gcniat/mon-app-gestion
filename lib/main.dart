import 'package:flutter/material.dart';
import 'app/home_screen.dart';
import 'core/constants.dart';
import 'core/theme.dart';

void main() {
  runApp(const FuelTrackerApp());
}

class FuelTrackerApp extends StatelessWidget {
  const FuelTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
