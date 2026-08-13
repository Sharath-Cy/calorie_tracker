import 'package:flutter/material.dart';
import '../services/food_service.dart';
import 'food_form_screen.dart';
import '../models/food.dart';
import 'scanner_screen.dart';

class ManageFoodsScreen extends StatefulWidget {
  const ManageFoodsScreen({super.key});

  @override
  State<ManageFoodsScreen> createState() => _ManageFoodsScreenState();
}

class _ManageFoodsScreenState extends State<ManageFoodsScreen> {
  List<Food> foods = [];

  bool isSearching = false;
  final TextEditingController searchController = TextEditingController();

  Future<void> loadFoods() async {
    foods = await FoodService.getFoods();

    setState(() {});
  }

  List<Food> get filteredFoods {
    final query = searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      return foods;
    }

    return foods.where((food) {
      return food.name.toLowerCase().contains(query);
    }).toList();
  }

  void startSearch() {
    setState(() {
      isSearching = true;
    });
  }

  void stopSearch() {
    searchController.clear();

    setState(() {
      isSearching = false;
    });
  }

  @override
  void initState() {
    super.initState();

    searchController.addListener(() {
      setState(() {});
    });

    loadFoods();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayedFoods = filteredFoods;

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

      appBar: AppBar(
        title: isSearching
            ? TextField(
                controller: searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Search foods...",
                  border: InputBorder.none,
                ),
                textInputAction: TextInputAction.search,
              )
            : const Text("Manage Foods"),

        actions: [
          if (isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: "Clear search",
              onPressed: stopSearch,
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: "Search foods",
              onPressed: startSearch,
            ),

          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: "Scan Food",
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ScannerScreen()),
              );

              await loadFoods();
            },
          ),
        ],
      ),

      body: displayedFoods.isEmpty
          ? Center(
              child: Text(
                searchController.text.trim().isEmpty
                    ? "No foods added yet."
                    : "No foods found.",
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 90),
              itemCount: displayedFoods.length,
              itemBuilder: (context, index) {
                final food = displayedFoods[index];

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
                            barcode: food.barcode,
                            nutritionBasis: food.nutritionBasis,
                            isFavorite: food.isFavorite,
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
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
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
