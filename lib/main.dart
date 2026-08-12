import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';
import 'services/food_service.dart';
import 'theme/app_theme.dart';
import 'services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseService.database;
  await FoodService.seedDatabase();

  runApp(const CalorieTrackerApp());
}

class CalorieTrackerApp extends StatefulWidget {
  const CalorieTrackerApp({super.key});

  @override
  State<CalorieTrackerApp> createState() => _CalorieTrackerAppState();

  static _CalorieTrackerAppState of(BuildContext context) {
    return context.findAncestorStateOfType<_CalorieTrackerAppState>()!;
  }
}

class _CalorieTrackerAppState extends State<CalorieTrackerApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    loadTheme();
  }

  Future<void> loadTheme() async {
    _themeMode = await ThemeService.loadThemeMode();
    setState(() {});
  }

  Future<void> changeTheme(ThemeMode mode) async {
    await ThemeService.saveThemeMode(mode);

    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Calorie Tracker',

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,

      home: const HomeScreen(),
    );
  }
}
