import 'package:flutter/material.dart';
import '../models/food.dart';

class ReviewFoodScreen extends StatefulWidget {
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String? barcode;

  const ReviewFoodScreen({
    super.key,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.barcode,
  });

  @override
  State<ReviewFoodScreen> createState() => _ReviewFoodScreenState();
}

class _ReviewFoodScreenState extends State<ReviewFoodScreen> {
  late final TextEditingController nameController;
  late final TextEditingController caloriesController;
  late final TextEditingController proteinController;
  late final TextEditingController carbsController;
  late final TextEditingController fatController;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.name);
    caloriesController = TextEditingController(
      text: widget.calories.toString(),
    );
    proteinController = TextEditingController(text: widget.protein.toString());
    carbsController = TextEditingController(text: widget.carbs.toString());
    fatController = TextEditingController(text: widget.fat.toString());
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

  Food? _createFood() {
    final name = nameController.text.trim();

    final calories = int.tryParse(caloriesController.text.trim());

    final protein = double.tryParse(proteinController.text.trim());

    final carbs = double.tryParse(carbsController.text.trim());

    final fat = double.tryParse(fatController.text.trim());

    if (name.isEmpty ||
        calories == null ||
        protein == null ||
        carbs == null ||
        fat == null) {
      return null;
    }

    return Food(
      name: name,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      isCustom: true,
      barcode: widget.barcode,
    );
  }

  Widget _nutritionField({
    required String label,
    required TextEditingController controller,
    required String suffix,
    TextInputType keyboardType = const TextInputType.numberWithOptions(
      decimal: true,
    ),
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Review Food")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Food Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            _nutritionField(
              label: "Calories",
              controller: caloriesController,
              suffix: "kcal / 100g",
              keyboardType: TextInputType.number,
            ),

            _nutritionField(
              label: "Protein",
              controller: proteinController,
              suffix: "g / 100g",
            ),

            _nutritionField(
              label: "Carbohydrates",
              controller: carbsController,
              suffix: "g / 100g",
            ),

            _nutritionField(
              label: "Fat",
              controller: fatController,
              suffix: "g / 100g",
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Save Food", style: TextStyle(fontSize: 17)),
                onPressed: () {
                  final food = _createFood();

                  if (food == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Please enter valid food and nutrition values.",
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.pop(context, food);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
