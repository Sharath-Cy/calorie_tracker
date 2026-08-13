import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import '../services/open_food_facts_service.dart';
import 'review_food_screen.dart';
import '../services/food_service.dart';
import 'nutrition_label_scanner_screen.dart';
import '../services/nutrition_parser.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];

  final BarcodeScanner _barcodeScanner = BarcodeScanner();

  bool _isInitialized = false;
  bool _isProcessing = false;
  String? _barcode;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();

    if (_cameras.isEmpty) return;

    final camera = _cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();

    if (!mounted) return;

    setState(() {
      _isInitialized = true;
    });

    await _controller!.startImageStream(_processCameraImage);
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || _barcode != null) return;

    _isProcessing = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);

      if (inputImage == null) return;

      final barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isEmpty) return;

      final barcode = barcodes.first;
      final value = barcode.rawValue ?? barcode.displayValue;

      if (value == null || value.isEmpty) return;

      if (!mounted) return;

      setState(() {
        _barcode = value;
      });

      await _controller?.stopImageStream();

      final existingFood = await FoodService.getFoodByBarcode(value);

      debugPrint("========== BARCODE CHECK ==========");
      debugPrint("Scanned barcode: $value");
      debugPrint("Existing food: ${existingFood?.name ?? 'NOT FOUND'}");
      debugPrint("===================================");

      if (existingFood != null) {
        if (!mounted) return;

        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Food Already Exists"),
              content: Text("${existingFood.name} is already in your foods."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );

        return;
      }
      debugPrint("========== OPEN FOOD FACTS LOOKUP ==========");
      debugPrint("Sending barcode to Open Food Facts: $value");

      final offResult = await OpenFoodFactsService.getProduct(value);

      final product = offResult.product;

      debugPrint(
        "Open Food Facts returned: ${product != null ? 'PRODUCT FOUND' : 'NULL / NOT FOUND'}",
      );
      debugPrint("=============================================");

      if (!mounted) return;

      if (product == null) {
        debugPrint("========== PRODUCT NULL ==========");
        debugPrint("About to show Product Not Found dialog");
        debugPrint("==================================");
        if (!mounted) return;

        final productNameController = TextEditingController();

        final shouldScanLabel = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(
                offResult.databaseUnavailable
                    ? "Food Database Unavailable"
                    : "Product Not Found",
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    offResult.databaseUnavailable
                        ? "We scanned the barcode successfully, but the food database "
                              "is temporarily unavailable.\n\n"
                              "You can still add this food by scanning the nutrition label "
                              "or entering the nutrition values manually."
                        : "This product wasn't found in the food database.\n\n"
                              "You can still add it by scanning the nutrition label "
                              "or entering the nutrition values manually.",
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: productNameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: "Product name",
                      hintText: "e.g. Knorr Vegetable Soup",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel"),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Scan Nutrition Label"),
                  onPressed: () {
                    if (productNameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please enter the product name."),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(context, true);
                  },
                ),
              ],
            );
          },
        );

        final productName = productNameController.text.trim();

        if (shouldScanLabel != true || productName.isEmpty) {
          return;
        }

        if (!mounted) return;

        final ocrResult = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NutritionLabelScannerScreen(),
          ),
        );

        if (!mounted) return;

        if (ocrResult == null || ocrResult is! List<OcrLineData>) {
          return;
        }

        final nutrition = NutritionParser.parse(ocrResult);

        debugPrint("========== PARSED NUTRITION ==========");
        debugPrint("Calories: ${nutrition.calories}");
        debugPrint("Protein: ${nutrition.protein}");
        debugPrint("Carbs: ${nutrition.carbs}");
        debugPrint("Fat: ${nutrition.fat}");
        debugPrint("Basis: ${nutrition.nutritionBasis}");
        debugPrint("Complete: ${nutrition.isComplete}");
        debugPrint("======================================");

        final food = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReviewFoodScreen(
              name: productName,
              calories: nutrition.calories,
              protein: nutrition.protein,
              carbs: nutrition.carbs,
              fat: nutrition.fat,
              barcode: value,
              nutritionBasis: nutrition.nutritionBasis,
            ),
          ),
        );

        if (!mounted) return;

        if (food != null) {
          await FoodService.addFood(food);

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${food.name} added successfully!")),
          );

          Navigator.pop(context);
        }

        return;
      }

      final productName = product['product_name'] ?? 'Unknown product';

      final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};

      debugPrint("========== NUTRIMENTS ==========");
      debugPrint(nutriments.toString());
      debugPrint("================================");

      final calories = nutriments['energy-kcal_100g'];
      final protein = nutriments['proteins_100g'];
      final carbs = nutriments['carbohydrates_100g'];
      final fat = nutriments['fat_100g'];

      final hasNutritionData =
          calories != null && protein != null && carbs != null && fat != null;
      if (!hasNutritionData) {
        if (!mounted) return;

        final shouldScanLabel = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Nutrition Data Unavailable"),
              content: Text(
                "$productName was found, but Open Food Facts "
                "doesn't have complete nutrition information.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel"),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Scan Label"),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            );
          },
        );

        if (shouldScanLabel != true) return;

        if (!mounted) return;

        final ocrResult = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NutritionLabelScannerScreen(),
          ),
        );

        if (!mounted) return;

        if (ocrResult == null || ocrResult is! List<OcrLineData>) {
          return;
        }

        final nutrition = NutritionParser.parse(ocrResult);

        debugPrint("========== PARSED NUTRITION ==========");
        debugPrint("Calories: ${nutrition.calories}");
        debugPrint("Protein: ${nutrition.protein}");
        debugPrint("Carbs: ${nutrition.carbs}");
        debugPrint("Fat: ${nutrition.fat}");
        debugPrint("Basis: ${nutrition.nutritionBasis}");
        debugPrint("Complete: ${nutrition.isComplete}");
        debugPrint("======================================");

        final food = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReviewFoodScreen(
              name: productName,
              calories: nutrition.calories,
              protein: nutrition.protein,
              carbs: nutrition.carbs,
              fat: nutrition.fat,
              barcode: value,
              nutritionBasis: nutrition.nutritionBasis,
            ),
          ),
        );

        if (!mounted) return;

        if (food != null) {
          await FoodService.addFood(food);

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${food.name} added successfully!")),
          );

          Navigator.pop(context);
        }

        return;
      }
      final parsedCalories = (calories as num).round();
      final parsedProtein = (protein as num).toDouble();
      final parsedCarbs = (carbs as num).toDouble();
      final parsedFat = (fat as num).toDouble();
      if (!mounted) return;

      final food = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewFoodScreen(
            name: productName,
            calories: parsedCalories,
            protein: parsedProtein,
            carbs: parsedCarbs,
            fat: parsedFat,
            barcode: value,
          ),
        ),
      );

      if (!mounted) return;
      if (food != null) {
        await FoodService.addFood(food);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${food.name} added successfully!")),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Barcode scanning error: $e");
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );

    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;

    var rotationCompensation = sensorOrientation;

    if (Platform.isAndroid) {
      final orientations = {
        DeviceOrientation.portraitUp: 0,
        DeviceOrientation.landscapeLeft: 90,
        DeviceOrientation.portraitDown: 180,
        DeviceOrientation.landscapeRight: 270,
      };

      final deviceOrientation =
          _controller?.value.deviceOrientation ?? DeviceOrientation.portraitUp;

      final deviceRotation = orientations[deviceOrientation] ?? 0;

      rotationCompensation = (sensorOrientation - deviceRotation + 360) % 360;
    }

    rotation = InputImageRotationValue.fromRawValue(rotationCompensation);

    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    if (format == null) return null;

    if (Platform.isAndroid && format != InputImageFormat.nv21) {
      return null;
    }

    if (Platform.isIOS && format != InputImageFormat.bgra8888) {
      return null;
    }

    if (image.planes.length != 1) return null;

    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Scan Food")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Scan Food")),
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_controller!)),

          Center(
            child: Container(
              width: 280,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          if (_barcode != null)
            Positioned(
              left: 20,
              right: 20,
              bottom: 30,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Barcode: $_barcode",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
