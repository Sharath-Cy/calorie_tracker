import 'package:flutter/material.dart';

class MealSummaryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final VoidCallback onTap;

  const MealSummaryCard({
    super.key,
    required this.title,
    required this.icon,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 32),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "${calories.toStringAsFixed(0)} kcal",
                      style: const TextStyle(fontSize: 15),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "P ${protein.toStringAsFixed(1)}g"
                      " • "
                      "C ${carbs.toStringAsFixed(1)}g"
                      " • "
                      "F ${fat.toStringAsFixed(1)}g",
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ],
                ),
              ),

              const Icon(Icons.arrow_forward_ios, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
