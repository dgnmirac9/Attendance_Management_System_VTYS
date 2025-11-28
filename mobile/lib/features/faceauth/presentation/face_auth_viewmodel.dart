
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import '../../../../core/face/face_embedding_extractor.dart';
import '../../../../core/face/image_preprocessor.dart';
import '../domain/face_embedding.dart';

class FaceAuthViewModel extends ChangeNotifier {
  final FaceEmbeddingExtractor _extractor = FaceEmbeddingExtractor();
  final ImagePreprocessor _preprocessor = ImagePreprocessor();

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  String? _error;
  String? get error => _error;

  FaceEmbedding? _lastEmbedding;
  FaceEmbedding? get lastEmbedding => _lastEmbedding;

  /// Kameradan gelen görüntüyü işler ve embedding üretir
  Future<void> processImage(CameraImage cameraImage) async {
    if (_isProcessing) return;
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Yüz Tespiti & Kırpma (Burada basitleştirildi, tüm ekranı alıyoruz)
      // Gerçek senaryoda: Google ML Kit Face Detection ile yüz koordinatları bulunur.
      
      // 2. Ön İşleme (YUV -> RGB -> Resize 112x112)
      final img.Image processedImage = _preprocessor.processCameraImage(cameraImage);

      // 3. Embedding Çıkarma
      final embedding = _extractor.run(processedImage);
      _lastEmbedding = embedding;

    } catch (e) {
      _error = "Yüz işleme hatası: $e";
      debugPrint(_error);
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// İki yüzü karşılaştırır (Login senaryosu)
  bool verifyFace(FaceEmbedding storedEmbedding) {
    if (_lastEmbedding == null) return false;
    return _lastEmbedding!.matches(storedEmbedding);
  }
}
