import '../models/food.dart';
import 'database_service.dart';
import '../data/starter_foods.dart';

class FoodService {
  static Future<void> seedDatabase() async {
    final count = await DatabaseService.getFoodCount();

    if (count > 0) return;

    for (final food in starterFoods) {
      await DatabaseService.insertFood(food);
    }
  }

  static Future<void> addFood(Food food) async {
    await DatabaseService.insertFood(food);
  }

  static Future<void> updateFood(Food food) async {
    await DatabaseService.updateFood(food);
  }

  static Future<void> deleteFood(int id) async {
    await DatabaseService.deleteFood(id);
  }

  static Future<List<Food>> getFoods() async {
    return await DatabaseService.getFoods();
  }

  static Future<bool> foodExists(String name, {int? excludeId}) async {
    return await DatabaseService.foodExists(name, excludeId: excludeId);
  }

  static Future<Food?> getFoodByBarcode(String barcode) async {
    return await DatabaseService.getFoodByBarcode(barcode);
  }
}
