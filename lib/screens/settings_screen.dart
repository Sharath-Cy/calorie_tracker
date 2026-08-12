import 'package:flutter/material.dart';
import '../models/goals.dart';
import '../widgets/goal_text_field.dart';
import 'manage_foods_screen.dart';
import '../services/goals_service.dart';
import '../services/theme_service.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  final Goals goals;

  const SettingsScreen({super.key, required this.goals});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController caloriesController = TextEditingController();
  final TextEditingController proteinController = TextEditingController();
  final TextEditingController carbsController = TextEditingController();
  final TextEditingController fatController = TextEditingController();

  ThemeMode _themeMode = ThemeMode.system;
  @override
  void initState() {
    super.initState();

    caloriesController.text = widget.goals.calories.toString();
    proteinController.text = widget.goals.protein.toString();
    carbsController.text = widget.goals.carbs.toString();
    fatController.text = widget.goals.fat.toString();
    loadTheme();
  }

  Future<void> loadTheme() async {
    _themeMode = await ThemeService.loadThemeMode();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            GoalTextField(
              label: "Calories Goal",
              controller: caloriesController,
            ),
            GoalTextField(label: "Protein Goal", controller: proteinController),

            GoalTextField(label: "Carbs Goal", controller: carbsController),

            GoalTextField(label: "Fat Goal", controller: fatController),
            const Divider(),

            ListTile(
              leading: const Icon(Icons.restaurant_menu),
              title: const Text("Manage Foods"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageFoodsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
            const SizedBox(height: 20),
            const Divider(),

            const SizedBox(height: 10),

            const Text(
              "Appearance",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            RadioListTile<ThemeMode>(
              title: const Text("System"),
              value: ThemeMode.system,
              groupValue: _themeMode,
              onChanged: (value) async {
                if (value == null) return;

                setState(() => _themeMode = value);

                if (!mounted) return;

                await CalorieTrackerApp.of(context).changeTheme(value);
              },
            ),

            RadioListTile<ThemeMode>(
              title: const Text("Light"),
              value: ThemeMode.light,
              groupValue: _themeMode,
              onChanged: (value) async {
                if (value == null) return;

                setState(() => _themeMode = value);

                if (!mounted) return;

                await CalorieTrackerApp.of(context).changeTheme(value);
              },
            ),

            RadioListTile<ThemeMode>(
              title: const Text("Dark"),
              value: ThemeMode.dark,
              groupValue: _themeMode,
              onChanged: (value) async {
                if (value == null) return;

                setState(() => _themeMode = value);

                if (!mounted) return;

                await CalorieTrackerApp.of(context).changeTheme(value);
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  int? calories = int.tryParse(caloriesController.text);
                  double? protein = double.tryParse(proteinController.text);
                  double? carbs = double.tryParse(carbsController.text);
                  double? fat = double.tryParse(fatController.text);

                  if (calories == null ||
                      protein == null ||
                      carbs == null ||
                      fat == null ||
                      calories <= 0 ||
                      protein <= 0 ||
                      carbs <= 0 ||
                      fat <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Please enter valid values greater than 0.",
                        ),
                      ),
                    );
                    return;
                  }

                  final goals = Goals(
                    calories: calories,
                    protein: protein,
                    carbs: carbs,
                    fat: fat,
                  );

                  await GoalsService.saveGoals(goals);

                  Navigator.pop(context, goals);
                },
                child: const Text("Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    caloriesController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatController.dispose();
    super.dispose();
  }
}
