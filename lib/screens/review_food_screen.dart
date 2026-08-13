import 'package:flutter/material.dart';
import '../models/food.dart';

class ReviewFoodScreen extends StatefulWidget {
  final String name;
  final int? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final String? barcode;
  final String nutritionBasis;

  const ReviewFoodScreen({
    super.key,
    required this.name,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.barcode,
    this.nutritionBasis = '100g',
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
      text: widget.calories?.toString() ?? '',
    );

    proteinController = TextEditingController(
      text: widget.protein?.toString() ?? '',
    );

    carbsController = TextEditingController(
      text: widget.carbs?.toString() ?? '',
    );

    fatController = TextEditingController(text: widget.fat?.toString() ?? '');
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
      nutritionBasis: widget.nutritionBasis,
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
    final basisLabel = "/ ${widget.nutritionBasis}";

    return Scaffold(
      appBar: AppBar(title: const Text("Review Food")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (widget.calories == null ||
                widget.protein == null ||
                widget.carbs == null ||
                widget.fat == null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Some nutrition values couldn't be detected automatically. "
                        "Please check the values below and enter any missing values.",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
              suffix: "kcal $basisLabel",
              keyboardType: TextInputType.number,
            ),

            _nutritionField(
              label: "Protein",
              controller: proteinController,
              suffix: "g $basisLabel",
            ),

            _nutritionField(
              label: "Carbohydrates",
              controller: carbsController,
              suffix: "g $basisLabel",
            ),

            _nutritionField(
              label: "Fat",
              controller: fatController,
              suffix: "g $basisLabel",
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
