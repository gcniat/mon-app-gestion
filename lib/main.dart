import 'package:flutter/material.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'features/vehicles/screens/vehicle_list_screen.dart';

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
      home: const VehicleListScreen(),
    );
  }
}
