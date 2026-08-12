import 'package:flutter/material.dart';
import '../services/food_service.dart';
import '../services/today_meal_service.dart';
import '../models/food.dart';

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  List<Food> foods = [];
  List<Food> recentlyUsedFoods = [];

  final TextEditingController searchController = TextEditingController();

  String searchText = "";
  bool showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    loadFoods();
  }

  Future<void> loadFoods() async {
    final allFoods = await FoodService.getFoods();
    final recentIds = await TodayMealService.getRecentlyUsedFoodIds();

    final recentFoods = <Food>[];

    for (final id in recentIds) {
      final match = allFoods.where((food) => food.id == id);

      if (match.isNotEmpty) {
        recentFoods.add(match.first);
      }
    }

    setState(() {
      foods = allFoods;
      recentlyUsedFoods = recentFoods;
    });
  }

  List<Food> get filteredFoods {
    List<Food> result = foods;

    if (showFavoritesOnly) {
      result = result.where((food) => food.isFavorite).toList();
    }

    if (searchText.isNotEmpty) {
      result = result.where((food) {
        return food.name.toLowerCase().contains(searchText.toLowerCase());
      }).toList();
    }

    return result;
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showRecentlyUsed =
        !showFavoritesOnly &&
        searchText.isEmpty &&
        recentlyUsedFoods.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text("Add Food")),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                hintText: "Search food...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text("All Foods"),
                    value: false,
                    groupValue: showFavoritesOnly,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setState(() {
                        showFavoritesOnly = value!;
                      });
                    },
                  ),
                ),

                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text("⭐ Favorites"),
                    value: true,
                    groupValue: showFavoritesOnly,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setState(() {
                        showFavoritesOnly = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                if (showRecentlyUsed) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      "🕐 Recently Used",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  ...recentlyUsedFoods.map((food) => buildFoodTile(food)),

                  const Divider(),

                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      "All Foods",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],

                if (filteredFoods.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: Column(
                      children: [
                        Icon(Icons.search_off, size: 70, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "No foods found",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Try a different search.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                else
                  ...filteredFoods.map((food) => buildFoodTile(food)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFoodTile(Food food) {
    return ListTile(
      leading: const Icon(Icons.restaurant),

      title: Text(food.name),

      subtitle: Text(
        "${food.calories} kcal | "
        "Protein ${food.protein}g | "
        "Carbs ${food.carbs}g | "
        "Fat ${food.fat}g",
      ),

      trailing: IconButton(
        icon: Icon(food.isFavorite ? Icons.star : Icons.star_border),
        onPressed: () async {
          final updatedFood = Food(
            id: food.id,
            name: food.name,
            calories: food.calories,
            protein: food.protein,
            carbs: food.carbs,
            fat: food.fat,
            isCustom: food.isCustom,
            isFavorite: !food.isFavorite,
          );

          await FoodService.updateFood(updatedFood);

          await loadFoods();
        },
      ),

      onTap: () {
        Navigator.pop(context, food);
      },
    );
  }
}
