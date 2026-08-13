import 'package:flutter/material.dart';
import '../models/food.dart';
import '../widgets/goal_text_field.dart';
import '../services/food_service.dart';

class FoodFormScreen extends StatefulWidget {
  final Food? food;

  const FoodFormScreen({super.key, this.food});

  @override
  State<FoodFormScreen> createState() => _FoodFormScreenState();
}

class _FoodFormScreenState extends State<FoodFormScreen> {
  final nameController = TextEditingController();
  final caloriesController = TextEditingController();
  final proteinController = TextEditingController();
  final carbsController = TextEditingController();
  final fatController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.food != null) {
      nameController.text = widget.food!.name;
      caloriesController.text = widget.food!.calories.toString();
      proteinController.text = widget.food!.protein.toString();
      carbsController.text = widget.food!.carbs.toString();
      fatController.text = widget.food!.fat.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.food == null ? "Add Food" : "Edit Food"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GoalTextField(
              label: "Food Name",
              controller: nameController,
              keyboardType: TextInputType.text,
            ),

            GoalTextField(
              label: "Calories (per 100g)",
              controller: caloriesController,
            ),

            GoalTextField(label: "Protein (g)", controller: proteinController),

            GoalTextField(label: "Carbs (g)", controller: carbsController),

            GoalTextField(label: "Fat (g)", controller: fatController),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  String name = nameController.text.trim();

                  int? calories = int.tryParse(caloriesController.text);
                  double? protein = double.tryParse(proteinController.text);
                  double? carbs = double.tryParse(carbsController.text);
                  double? fat = double.tryParse(fatController.text);
                  if (name.length > 60) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Food name cannot exceed 60 characters."),
                      ),
                    );
                    return;
                  }
                  if (name.isEmpty ||
                      calories == null ||
                      protein == null ||
                      carbs == null ||
                      fat == null ||
                      calories <= 0 ||
                      protein < 0 ||
                      carbs < 0 ||
                      fat < 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please enter valid food details."),
                      ),
                    );
                    return;
                  }
                  bool foodExists = await FoodService.foodExists(
                    name,
                    excludeId: widget.food?.id,
                  );

                  if (foodExists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("A food with this name already exists."),
                      ),
                    );
                    return;
                  }
                  Food food = Food(
                    name: name,
                    calories: calories,
                    protein: protein,
                    carbs: carbs,
                    fat: fat,
                    isCustom: widget.food?.isCustom ?? true,
                  );

                  Navigator.pop(context, food);
                },
                child: Text(widget.food == null ? "Save Food" : "Update Food"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    caloriesController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatController.dispose();
    super.dispose();
  }
}
