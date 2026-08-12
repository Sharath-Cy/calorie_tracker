import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenFoodFactsService {
  static Future<Map<String, dynamic>?> getProduct(String barcode) async {
    final url = Uri.parse(
      'https://world.openfoodfacts.org/api/v3/product/$barcode',
    );

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'CalorieTracker/1.0'},
      );

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body);

      final product = data['product'];

      if (product == null || product is! Map<String, dynamic>) {
        return null;
      }

      return product;
    } catch (e) {
      print('Open Food Facts error: $e');
      return null;
    }
  }
}
