class TodayMeal {
  final int? id;
  final int foodId;
  final String foodName;
  final double grams;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final String date;
  final String mealType;

  const TodayMeal({
    this.id,
    required this.foodId,
    required this.foodName,
    required this.grams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.date,
    required this.mealType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'foodId': foodId,
      'foodName': foodName,
      'grams': grams,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'date': date,
      'mealType': mealType,
    };
  }

  factory TodayMeal.fromMap(Map<String, dynamic> map) {
    return TodayMeal(
      id: map['id'],
      foodId: map['foodId'],
      foodName: map['foodName'],
      grams: map['grams'],
      calories: map['calories'],
      protein: map['protein'],
      carbs: map['carbs'],
      fat: map['fat'],
      date: map['date'],
      mealType: map['mealType'],
    );
  }
}
