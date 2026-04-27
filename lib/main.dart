import 'package:flutter/material.dart';
import 'app/home_screen.dart';
import 'core/constants.dart';
import 'core/services/preferences_service.dart';
import 'core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PreferencesService().init();
  runApp(const GallonManApp());
}

class GallonManApp extends StatelessWidget {
  const GallonManApp({super.key});

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
