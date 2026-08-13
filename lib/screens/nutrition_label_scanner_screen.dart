import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrLineData {
  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;

  const OcrLineData({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'left': left,
      'top': top,
      'right': right,
      'bottom': bottom,
    };
  }
}

class NutritionLabelScannerScreen extends StatefulWidget {
  const NutritionLabelScannerScreen({super.key});

  @override
  State<NutritionLabelScannerScreen> createState() =>
      _NutritionLabelScannerScreenState();
}

class _NutritionLabelScannerScreenState
    extends State<NutritionLabelScannerScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];

  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  bool _isInitialized = false;
  bool _isScanning = false;

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
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();

    if (!mounted) return;

    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _captureLabel() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isScanning) {
      return;
    }

    setState(() {
      _isScanning = true;
    });

    try {
      final XFile image = await _controller!.takePicture();

      final inputImage = InputImage.fromFilePath(image.path);

      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (!mounted) return;

      if (recognizedText.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Couldn't read the label. Try again with better lighting.",
            ),
          ),
        );
        return;
      }

      final ocrLines = <OcrLineData>[];

      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          final rect = line.boundingBox;

          ocrLines.add(
            OcrLineData(
              text: line.text,
              left: rect.left,
              top: rect.top,
              right: rect.right,
              bottom: rect.bottom,
            ),
          );
        }
      }

      debugPrint("========== OCR LINES ==========");

      for (final line in ocrLines) {
        debugPrint(
          "${line.text} | "
          "L:${line.left.toStringAsFixed(1)} "
          "T:${line.top.toStringAsFixed(1)} "
          "R:${line.right.toStringAsFixed(1)} "
          "B:${line.bottom.toStringAsFixed(1)}",
        );
      }

      debugPrint("===============================");

      Navigator.pop(context, ocrLines);
    } catch (e) {
      debugPrint("Nutrition label OCR error: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't scan the nutrition label.")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Scan Nutrition Label")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Scan Nutrition Label")),
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_controller!)),

          Center(
            child: Container(
              width: 340,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "Position the nutrition label inside the box",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isScanning ? null : _captureLabel,
                    icon: _isScanning
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt),
                    label: Text(
                      _isScanning ? "Reading Label..." : "Capture Label",
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
