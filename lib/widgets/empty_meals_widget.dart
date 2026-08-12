import 'package:flutter/material.dart';

class EmptyMealsWidget extends StatelessWidget {
  const EmptyMealsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 70, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "No meals added today",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text("Tap + to start tracking", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
