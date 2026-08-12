import 'package:flutter/material.dart';
import '../models/food.dart';
import '../models/nutrition_result.dart';

class QuantityScreen extends StatefulWidget {
  final Food food;
  final double? initialGrams;
  final String buttonText;

  const QuantityScreen({
    super.key,
    required this.food,
    this.initialGrams,
    this.buttonText = "Add",
  });

  @override
  State<QuantityScreen> createState() => _QuantityScreenState();
}

class _QuantityScreenState extends State<QuantityScreen> {
  final TextEditingController quantityController = TextEditingController();
  @override
  void initState() {
    super.initState();

    quantityController.text = widget.initialGrams?.toStringAsFixed(0) ?? "100";
  }

  @override
  void dispose() {
    quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.food.name)),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.food.name,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Text("Calories : ${widget.food.calories} kcal /100g"),
            Text("Protein : ${widget.food.protein} g"),
            Text("Carbs : ${widget.food.carbs} g"),
            Text("Fat : ${widget.food.fat} g"),

            const SizedBox(height: 30),

            TextField(
              controller: quantityController,

              keyboardType: TextInputType.number,

              decoration: const InputDecoration(
                labelText: "Quantity (grams)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed: () {
                  double? grams = double.tryParse(quantityController.text);

                  if (grams == null || grams <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please enter a valid quantity."),
                      ),
                    );
                    return;
                  }
                  double factor = grams / 100;

                  double calories = widget.food.calories * factor;
                  double protein = widget.food.protein * factor;
                  double carbs = widget.food.carbs * factor;
                  double fat = widget.food.fat * factor;

                  NutritionResult result = NutritionResult(
                    calories: calories,
                    protein: protein,
                    carbs: carbs,
                    fat: fat,
                    grams: grams,
                  );
                  Navigator.pop(context, result);
                },
                child: Text(widget.buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
