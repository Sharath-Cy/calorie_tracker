import 'package:flutter/material.dart';
import '../widgets/nutrition_card.dart';
import '../widgets/meal_summary_card.dart';
import '../models/nutrition_result.dart';
import '../models/goals.dart';
import 'settings_screen.dart';
import 'meal_detail_screen.dart';
import '../services/today_meal_service.dart';
import '../services/goals_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Goals goals = Goals(calories: 1700, protein: 130, carbs: 150, fat: 55);

  List<dynamic> todaysMeals = [];

  @override
  void initState() {
    super.initState();
    loadGoals();
    loadMeals();
  }

  Future<void> loadGoals() async {
    goals = await GoalsService.loadGoals();
    setState(() {});
  }

  Future<void> loadMeals() async {
    await TodayMealService.clearOldMeals();

    final savedMeals = await TodayMealService.getMeals();

    setState(() {
      todaysMeals = savedMeals;
    });
  }

  List<dynamic> getMealsByType(String mealType) {
    return todaysMeals.where((meal) => meal.mealType == mealType).toList();
  }

  double get totalCalories {
    double total = 0;

    for (final meal in todaysMeals) {
      total += meal.calories;
    }

    return total;
  }

  double get totalProtein {
    double total = 0;

    for (final meal in todaysMeals) {
      total += meal.protein;
    }

    return total;
  }

  double get totalCarbs {
    double total = 0;

    for (final meal in todaysMeals) {
      total += meal.carbs;
    }

    return total;
  }

  double get totalFat {
    double total = 0;

    for (final meal in todaysMeals) {
      total += meal.fat;
    }

    return total;
  }

  double mealCalories(String mealType) {
    return getMealsByType(mealType).fold(0, (sum, meal) => sum + meal.calories);
  }

  double mealProtein(String mealType) {
    return getMealsByType(mealType).fold(0, (sum, meal) => sum + meal.protein);
  }

  double mealCarbs(String mealType) {
    return getMealsByType(mealType).fold(0, (sum, meal) => sum + meal.carbs);
  }

  double mealFat(String mealType) {
    return getMealsByType(mealType).fold(0, (sum, meal) => sum + meal.fat);
  }

  Future<void> openMeal(String mealType) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MealDetailScreen(mealType: mealType),
      ),
    );

    await loadMeals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🔥 Calorie Tracker"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              Goals? updatedGoals = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(goals: goals),
                ),
              );

              if (updatedGoals == null) return;

              setState(() {
                goals = updatedGoals;
              });
            },
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: loadMeals,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            NutritionCard(
              title: "Calories",
              value:
                  "${totalCalories.toStringAsFixed(0)} / ${goals.calories} kcal",
              progress: totalCalories / goals.calories,
            ),

            NutritionCard(
              title: "Protein",
              value: "${totalProtein.toStringAsFixed(1)} / ${goals.protein} g",
              progress: totalProtein / goals.protein,
            ),

            NutritionCard(
              title: "Carbs",
              value: "${totalCarbs.toStringAsFixed(1)} / ${goals.carbs} g",
              progress: totalCarbs / goals.carbs,
            ),

            NutritionCard(
              title: "Fat",
              value: "${totalFat.toStringAsFixed(1)} / ${goals.fat} g",
              progress: totalFat / goals.fat,
            ),

            const SizedBox(height: 20),

            MealSummaryCard(
              title: "Breakfast",
              icon: Icons.free_breakfast,
              calories: mealCalories("Breakfast"),
              protein: mealProtein("Breakfast"),
              carbs: mealCarbs("Breakfast"),
              fat: mealFat("Breakfast"),
              onTap: () => openMeal("Breakfast"),
            ),

            MealSummaryCard(
              title: "Lunch",
              icon: Icons.lunch_dining,
              calories: mealCalories("Lunch"),
              protein: mealProtein("Lunch"),
              carbs: mealCarbs("Lunch"),
              fat: mealFat("Lunch"),
              onTap: () => openMeal("Lunch"),
            ),

            MealSummaryCard(
              title: "Snacks",
              icon: Icons.apple,
              calories: mealCalories("Snack"),
              protein: mealProtein("Snack"),
              carbs: mealCarbs("Snack"),
              fat: mealFat("Snack"),
              onTap: () => openMeal("Snack"),
            ),

            MealSummaryCard(
              title: "Dinner",
              icon: Icons.dinner_dining,
              calories: mealCalories("Dinner"),
              protein: mealProtein("Dinner"),
              carbs: mealCarbs("Dinner"),
              fat: mealFat("Dinner"),
              onTap: () => openMeal("Dinner"),
            ),
          ],
        ),
      ),
    );
  }
}
