import 'dart:io';
import 'dart:math';

import 'package:attendance_management_system_vtys/core/constants/app_assets.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceRecognitionService {
  static final FaceRecognitionService _instance = FaceRecognitionService._internal();
  static FaceRecognitionService get instance => _instance;

  Interpreter? _interpreter;
  // MobileFaceNet output size is usually 192
  static const int _outputSize = 192;
  static const int _inputSize = 112;

  FaceRecognitionService._internal();

  Future<void> loadModel() async {
    try {
      final options = InterpreterOptions();
      if (Platform.isAndroid) {
        // options.addDelegate(GpuDelegateV2());
      }
      
      _interpreter = await Interpreter.fromAsset(
        'assets/models/mobilefacenet.tflite', 
        options: options,
      );
      debugPrint('FaceRecognitionService: Model loaded successfully.');
    } catch (e) {
      debugPrint('FaceRecognitionService: Error loading model: $e');
    }
  }

  Future<List<double>> generateEmbedding(File photo, Face face) async {
    if (_interpreter == null) {
      throw Exception('Model not loaded');
    }
    return _processImage(photo, face);
  }

  Future<List<double>> _processImage(File photoFile, Face face) async {
    // 1. Decode image
    final bytes = await photoFile.readAsBytes();
    final img.Image? decodedImage = img.decodeImage(bytes);

    if (decodedImage == null) {
      throw Exception('Could not decode image');
    }

    // 2. Crop face
    double x = face.boundingBox.left;
    double y = face.boundingBox.top;
    double w = face.boundingBox.width;
    double h = face.boundingBox.height;

    // Ensure cropping is within bounds
    int left = x.toInt().clamp(0, decodedImage.width);
    int top = y.toInt().clamp(0, decodedImage.height);
    int width = w.toInt().clamp(0, decodedImage.width - left);
    int height = h.toInt().clamp(0, decodedImage.height - top);
    
    img.Image croppedImage = img.copyCrop(
      decodedImage,
      x: left,
      y: top,
      width: width,
      height: height,
    );

    // 3. Resize to 112x112
    img.Image resizedImage = img.copyResize(
      croppedImage,
      width: _inputSize,
      height: _inputSize,
    );

    // 4. Prepare input
    List input = _imageToByteListFloat32(resizedImage, _inputSize, 128, 128);
    
    // Output tensor
    List output = List.generate(1, (_) => List.filled(_outputSize, 0.0));
    
    // Run inference
    _interpreter!.run(input, output);
    
    return List<double>.from(output[0]);
  }

  double calculateDistance(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) return double.infinity;
    double sum = 0.0;
    for (int i = 0; i < embedding1.length; i++) {
      double diff = embedding1[i] - embedding2[i];
      sum += diff * diff;
    }
    return sqrt(sum);
  }


  
  List _imageToByteListFloat32(img.Image image, int inputSize, double mean, double std) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (pixel.r - mean) / std;
        buffer[pixelIndex++] = (pixel.g - mean) / std;
        buffer[pixelIndex++] = (pixel.b - mean) / std;
      }
    }
    return convertedBytes.reshape([1, inputSize, inputSize, 3]);
  }

  Interpreter? get interpreter => _interpreter;
}
