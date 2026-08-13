import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenFoodFactsResult {
  final Map<String, dynamic>? product;
  final bool databaseUnavailable;

  OpenFoodFactsResult({this.product, this.databaseUnavailable = false});

  bool get found => product != null;
}

class OpenFoodFactsService {
  static Future<OpenFoodFactsResult> getProduct(String barcode) async {
    final url = Uri.parse(
      'https://world.openfoodfacts.org/api/v3/product/$barcode',
    );

    try {
      print('========== OPEN FOOD FACTS ==========');
      print('Looking up barcode: $barcode');
      print('URL: $url');

      final response = await http
          .get(url, headers: {'User-Agent': 'CalorieTracker/1.0'})
          .timeout(const Duration(seconds: 8));

      print('OFF status code: ${response.statusCode}');

      // Product genuinely does not exist
      if (response.statusCode == 404) {
        print('OFF: Product genuinely NOT FOUND');
        print('====================================');

        return OpenFoodFactsResult(product: null, databaseUnavailable: false);
      }

      // Server/database problem
      if (response.statusCode != 200) {
        print('OFF: DATABASE UNAVAILABLE');
        print('HTTP status: ${response.statusCode}');
        print('====================================');

        return OpenFoodFactsResult(product: null, databaseUnavailable: true);
      }

      final data = jsonDecode(response.body);

      final product = data['product'];

      if (product == null || product is! Map<String, dynamic>) {
        print('OFF response contains no product');
        print('====================================');

        return OpenFoodFactsResult(product: null, databaseUnavailable: false);
      }

      print('OFF product FOUND');
      print('Product name: ${product['product_name']}');
      print('====================================');

      return OpenFoodFactsResult(product: product, databaseUnavailable: false);
    } catch (e) {
      print('Open Food Facts error: $e');
      print('OFF: DATABASE UNAVAILABLE');
      print('====================================');

      return OpenFoodFactsResult(product: null, databaseUnavailable: true);
    }
  }
}
