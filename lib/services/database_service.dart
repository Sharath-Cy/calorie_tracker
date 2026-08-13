import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/food.dart';
import '../models/today_meal.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initializeDatabase();
    return _database!;
  }

  static Future<Database> _initializeDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(databasePath, 'calorie_tracker.db');

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDatabase,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
CREATE TABLE foods(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  calories INTEGER NOT NULL,
  protein REAL NOT NULL,
  carbs REAL NOT NULL,
  fat REAL NOT NULL,
  isCustom INTEGER NOT NULL,
  isFavorite INTEGER NOT NULL DEFAULT 0,
  barcode TEXT,
  nutritionBasis TEXT NOT NULL DEFAULT '100g'
)
  ''');
    await db.execute('''
CREATE TABLE today_meals(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  foodId INTEGER NOT NULL,
  foodName TEXT NOT NULL,
  grams REAL NOT NULL,
  calories REAL NOT NULL,
  protein REAL NOT NULL,
  carbs REAL NOT NULL,
  fat REAL NOT NULL,
  date TEXT NOT NULL,
mealType TEXT NOT NULL
)
''');
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE foods ADD COLUMN isFavorite INTEGER NOT NULL DEFAULT 0',
      );
    }

    if (oldVersion < 4) {
      await db.execute('ALTER TABLE foods ADD COLUMN barcode TEXT');
    }
    if (oldVersion < 5) {
      await db.execute(
        "ALTER TABLE foods ADD COLUMN nutritionBasis TEXT NOT NULL DEFAULT '100g'",
      );
    }
  }

  static Future<int> getFoodCount() async {
    final db = await database;

    final result = await db.rawQuery('SELECT COUNT(*) as count FROM foods');

    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<void> updateFood(Food food) async {
    final db = await database;

    await db.update(
      'foods',
      food.toMap(),
      where: 'id = ?',
      whereArgs: [food.id],
    );
  }

  static Future<void> deleteFood(int id) async {
    final db = await database;

    await db.delete('foods', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> insertFood(Food food) async {
    final db = await database;

    await db.insert(
      'foods',
      food.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Food>> getFoods() async {
    final db = await database;

    final result = await db.query('foods', orderBy: 'name ASC');

    return result.map((food) => Food.fromMap(food)).toList();
  }

  static Future<bool> foodExists(String name, {int? excludeId}) async {
    final db = await database;

    final result = await db.query(
      'foods',
      where: excludeId == null
          ? 'LOWER(name) = ?'
          : 'LOWER(name) = ? AND id != ?',
      whereArgs: excludeId == null
          ? [name.toLowerCase()]
          : [name.toLowerCase(), excludeId],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  static Future<Food?> getFoodByBarcode(String barcode) async {
    final db = await database;

    final result = await db.query(
      'foods',
      where: 'barcode = ?',
      whereArgs: [barcode],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return Food.fromMap(result.first);
  }

  static Future<int> insertTodayMeal(TodayMeal meal) async {
    final db = await database;

    return await db.insert(
      'today_meals',
      meal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<TodayMeal>> getTodayMeals() async {
    final db = await database;

    final result = await db.query('today_meals');

    return result.map((meal) => TodayMeal.fromMap(meal)).toList();
  }

  static Future<List<int>> getRecentlyUsedFoodIds({int limit = 5}) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
    SELECT foodId
    FROM today_meals
    GROUP BY foodId
    ORDER BY MAX(id) DESC
    LIMIT ?
  ''',
      [limit],
    );

    return result.map((row) => row['foodId'] as int).toList();
  }

  static Future<void> updateTodayMeal(TodayMeal meal) async {
    final db = await database;

    await db.update(
      'today_meals',
      meal.toMap(),
      where: 'id = ?',
      whereArgs: [meal.id],
    );
  }

  static Future<void> deleteTodayMeal(int id) async {
    final db = await database;

    await db.delete('today_meals', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clearTodayMeals() async {
    final db = await database;

    await db.delete('today_meals');
  }

  static Future<void> clearOldMeals() async {
    final db = await database;

    final today = DateTime.now().toIso8601String().split('T')[0];

    await db.delete('today_meals', where: 'date != ?', whereArgs: [today]);
  }
}
