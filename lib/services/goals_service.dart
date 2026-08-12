import 'package:shared_preferences/shared_preferences.dart';
import '../models/goals.dart';

class GoalsService {
  static const _caloriesKey = 'goal_calories';
  static const _proteinKey = 'goal_protein';
  static const _carbsKey = 'goal_carbs';
  static const _fatKey = 'goal_fat';

  static Future<void> saveGoals(Goals goals) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_caloriesKey, goals.calories);
    await prefs.setDouble(_proteinKey, goals.protein);
    await prefs.setDouble(_carbsKey, goals.carbs);
    await prefs.setDouble(_fatKey, goals.fat);
  }

  static Future<Goals> loadGoals() async {
    final prefs = await SharedPreferences.getInstance();

    return Goals(
      calories: prefs.getInt(_caloriesKey) ?? 1700,
      protein: prefs.getDouble(_proteinKey) ?? 130,
      carbs: prefs.getDouble(_carbsKey) ?? 150,
      fat: prefs.getDouble(_fatKey) ?? 55,
    );
  }
}
