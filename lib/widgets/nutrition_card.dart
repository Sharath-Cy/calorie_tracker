import 'package:flutter/material.dart';

class NutritionCard extends StatelessWidget {
  final String title;
  final String value;
  final double progress;
  final bool isCalories;

  const NutritionCard({
    super.key,
    required this.title,
    required this.value,
    required this.progress,
    this.isCalories = false,
  });

  Color _getProgressColor() {
    if (!isCalories) {
      return Colors.green;
    }

    if (progress <= 1.0) {
      return Colors.green;
    }

    if (progress <= 1.10) {
      return Colors.amber;
    }

    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final progressColor = _getProgressColor();

    return Card(
      elevation: 12,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(value, style: const TextStyle(fontSize: 18)),
              ],
            ),

            const SizedBox(height: 15),

            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(10),
              color: progressColor,
            ),
          ],
        ),
      ),
    );
  }
}
