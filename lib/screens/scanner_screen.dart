import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import '../services/open_food_facts_service.dart';
import 'review_food_screen.dart';
import '../services/food_service.dart';

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
      final product = await OpenFoodFactsService.getProduct(value);

      if (!mounted) return;

      if (product == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Product not found in Open Food Facts."),
          ),
        );
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

      final parsedCalories = (calories as num?)?.round() ?? 0;
      final parsedProtein = (protein as num?)?.toDouble() ?? 0;
      final parsedCarbs = (carbs as num?)?.toDouble() ?? 0;
      final parsedFat = (fat as num?)?.toDouble() ?? 0;

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
