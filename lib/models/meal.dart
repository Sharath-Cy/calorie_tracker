import 'food.dart';
import 'nutrition_result.dart';

class Meal {
  final int? id;
  final Food food;
  final NutritionResult nutrition;

  const Meal({this.id, required this.food, required this.nutrition});
}
