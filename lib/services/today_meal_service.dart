import '../models/today_meal.dart';
import 'database_service.dart';

class TodayMealService {
  static Future<int> addMeal(TodayMeal meal) async {
    return await DatabaseService.insertTodayMeal(meal);
  }

  static Future<List<TodayMeal>> getMeals() async {
    return await DatabaseService.getTodayMeals();
  }

  static Future<void> updateMeal(TodayMeal meal) async {
    await DatabaseService.updateTodayMeal(meal);
  }

  static Future<void> clearOldMeals() async {
    await DatabaseService.clearOldMeals();
  }

  static Future<void> deleteMeal(int id) async {
    await DatabaseService.deleteTodayMeal(id);
  }

  static Future<void> clearMeals() async {
    await DatabaseService.clearTodayMeals();
  }

  static Future<List<TodayMeal>> getMealsByType(String mealType) async {
    final meals = await DatabaseService.getTodayMeals();

    return meals.where((meal) => meal.mealType == mealType).toList();
  }

  static Future<List<int>> getRecentlyUsedFoodIds({int limit = 5}) async {
    return await DatabaseService.getRecentlyUsedFoodIds(limit: limit);
  }
}
