import 'package:flutter/material.dart';
import '../services/food_service.dart';
import 'food_form_screen.dart';
import '../models/food.dart';

class ManageFoodsScreen extends StatefulWidget {
  const ManageFoodsScreen({super.key});

  @override
  State<ManageFoodsScreen> createState() => _ManageFoodsScreenState();
}

class _ManageFoodsScreenState extends State<ManageFoodsScreen> {
  List<Food> foods = [];
  Future<void> loadFoods() async {
    foods = await FoodService.getFoods();

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    loadFoods();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          Food? newFood = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FoodFormScreen()),
          );

          if (newFood == null) return;

          await FoodService.addFood(newFood);

          await loadFoods();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${newFood.name} added successfully!")),
          );
        },
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(title: const Text("Manage Foods")),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 90),
        itemCount: foods.length,
        itemBuilder: (context, index) {
          final food = foods[index];

          return ListTile(
            leading: const Icon(Icons.restaurant),

            title: Text(food.name),

            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${food.calories} kcal /100g"),

                const SizedBox(height: 4),

                Text(
                  "P ${food.protein}g • C ${food.carbs}g • F ${food.fat}g",
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ],
            ),

            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    Food? updatedFood = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FoodFormScreen(food: food),
                      ),
                    );

                    if (updatedFood == null) return;
                    Food updated = Food(
                      id: food.id,
                      name: updatedFood.name,
                      calories: updatedFood.calories,
                      protein: updatedFood.protein,
                      carbs: updatedFood.carbs,
                      fat: updatedFood.fat,
                      isCustom: updatedFood.isCustom,
                    );

                    await FoodService.updateFood(updated);

                    await loadFoods();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "${updatedFood.name} updated successfully!",
                        ),
                      ),
                    );
                  },
                ),

                if (food.isCustom)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      bool? confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Delete Food"),
                          content: Text(
                            'Are you sure you want to delete "${food.name}"?\n\nThis action cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                "Delete",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirmed != true) return;
                      await FoodService.deleteFood(food.id!);

                      await loadFoods();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("${food.name} deleted.")),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
