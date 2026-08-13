class Food {
  final int? id;
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final bool isCustom;
  final bool isFavorite;
  final String? barcode;
  final String nutritionBasis;

  Food({
    this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.isCustom = false,
    this.isFavorite = false,
    this.barcode,
    this.nutritionBasis = '100g',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'isCustom': isCustom ? 1 : 0,
      'isFavorite': isFavorite ? 1 : 0,
      'barcode': barcode,
      'nutritionBasis': nutritionBasis,
    };
  }

  factory Food.fromMap(Map<String, dynamic> map) {
    return Food(
      id: map['id'],
      name: map['name'],
      calories: map['calories'],
      protein: map['protein'],
      carbs: map['carbs'],
      fat: map['fat'],
      isCustom: map['isCustom'] == 1,
      isFavorite: map['isFavorite'] == 1,
      barcode: map['barcode'],
      nutritionBasis: map['nutritionBasis'] ?? '100g',
    );
  }
}
