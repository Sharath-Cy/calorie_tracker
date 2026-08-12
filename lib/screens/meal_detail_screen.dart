import 'package:flutter/material.dart';
import '../models/today_meal.dart';
import '../services/today_meal_service.dart';
import '../models/food.dart';
import '../models/nutrition_result.dart';
import '../models/meal.dart';
import 'add_food_screen.dart';
import 'quantity_screen.dart';

class MealDetailScreen extends StatefulWidget {
  final String mealType;

  const MealDetailScreen({super.key, required this.mealType});

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  List<Meal> meals = [];

  @override
  void initState() {
    super.initState();
    loadMeals();
  }

  Future<void> loadMeals() async {
    final savedMeals = await TodayMealService.getMealsByType(widget.mealType);

    setState(() {
      meals = savedMeals.map((meal) {
        return Meal(
          id: meal.id,
          food: Food(
            id: meal.foodId,
            name: meal.foodName,
            calories: (meal.calories * 100 / meal.grams).round(),
            protein: meal.protein * 100 / meal.grams,
            carbs: meal.carbs * 100 / meal.grams,
            fat: meal.fat * 100 / meal.grams,
          ),
          nutrition: NutritionResult(
            calories: meal.calories,
            protein: meal.protein,
            carbs: meal.carbs,
            fat: meal.fat,
            grams: meal.grams,
          ),
        );
      }).toList();
    });
  }

  double get totalCalories =>
      meals.fold(0, (sum, meal) => sum + meal.nutrition.calories);

  double get totalProtein =>
      meals.fold(0, (sum, meal) => sum + meal.nutrition.protein);

  double get totalCarbs =>
      meals.fold(0, (sum, meal) => sum + meal.nutrition.carbs);

  double get totalFat => meals.fold(0, (sum, meal) => sum + meal.nutrition.fat);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.mealType)),

      floatingActionButton: FloatingActionButton(
        onPressed: addFood,
        child: const Icon(Icons.add),
      ),

      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    "${totalCalories.toStringAsFixed(0)} kcal",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "P ${totalProtein.toStringAsFixed(1)}g"
                    " • "
                    "C ${totalCarbs.toStringAsFixed(1)}g"
                    " • "
                    "F ${totalFat.toStringAsFixed(1)}g",
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: meals.isEmpty
                ? const Center(child: Text("No foods added yet."))
                : ListView.builder(
                    itemCount: meals.length,
                    itemBuilder: (context, index) {
                      final meal = meals[index];

                      return Dismissible(
                        key: ValueKey(meal.id),

                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),

                        onDismissed: (direction) async {
                          final id = meal.id;

                          setState(() {
                            meals.removeAt(index);
                          });

                          if (id != null) {
                            await TodayMealService.deleteMeal(id);
                          }
                        },

                        child: Card(
                          child: ListTile(
                            leading: const Icon(Icons.restaurant),

                            title: Text(meal.food.name),

                            subtitle: Text(
                              "${meal.nutrition.grams.toStringAsFixed(0)} g • "
                              "${meal.nutrition.calories.toStringAsFixed(0)} kcal\n"
                              "P ${meal.nutrition.protein.toStringAsFixed(1)}g"
                              " • "
                              "C ${meal.nutrition.carbs.toStringAsFixed(1)}g"
                              " • "
                              "F ${meal.nutrition.fat.toStringAsFixed(1)}g",
                            ),

                            onTap: () => editMeal(index),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> addFood() async {
    Food? selectedFood = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddFoodScreen()),
    );

    if (selectedFood == null) return;

    NutritionResult? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuantityScreen(food: selectedFood),
      ),
    );

    if (result == null) return;

    final id = await TodayMealService.addMeal(
      TodayMeal(
        foodId: selectedFood.id!,
        foodName: selectedFood.name,
        grams: result.grams,
        calories: result.calories,
        protein: result.protein,
        carbs: result.carbs,
        fat: result.fat,
        date: DateTime.now().toIso8601String().split('T')[0],
        mealType: widget.mealType,
      ),
    );

    setState(() {
      meals.add(Meal(id: id, food: selectedFood!, nutrition: result));
    });
  }

  Future<void> editMeal(int index) async {
    final meal = meals[index];

    NutritionResult? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuantityScreen(
          food: meal.food,
          initialGrams: meal.nutrition.grams,
          buttonText: "Save",
        ),
      ),
    );

    if (result == null) return;

    await TodayMealService.updateMeal(
      TodayMeal(
        id: meal.id,
        foodId: meal.food.id!,
        foodName: meal.food.name,
        grams: result.grams,
        calories: result.calories,
        protein: result.protein,
        carbs: result.carbs,
        fat: result.fat,
        date: DateTime.now().toIso8601String().split('T')[0],
        mealType: widget.mealType,
      ),
    );

    setState(() {
      meals[index] = Meal(id: meal.id, food: meal.food, nutrition: result);
    });
  }
}
