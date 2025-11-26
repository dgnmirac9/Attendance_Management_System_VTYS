/**
 * FaceEmbeddingExtractor
 *
 * Bu sınıf, MobileFaceNet modelini kullanarak görüntüden embedding üretir.
 * Model yükleme işlemi async olduğundan, constructor içinde _init() çağrılır.
 *
 * İş akışı:
 * 1) ImagePreprocessor → 112x112 normalize edilmiş img.Image
 * 2) FaceEmbeddingExtractor.run(image) → 128 boyutlu embedding
 * 3) FaceEmbedding → Domain model
 */

import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../../features/faceauth/domain/face_embedding.dart';

// Sınıf ismi düzeltildi (PascalCase)
class FaceEmbeddingExtractor {
  late Interpreter _interpreter;
  bool _isReady = false;

  FaceEmbeddingExtractor() {
    _init();
  }

  /// Modeli asenkron yükler
  Future<void> _init() async {
    _interpreter = await Interpreter.fromAsset(
      'models/mobilefacenet.tflite',
      options: InterpreterOptions()..threads = 4, // CPU optimize
    );
    _isReady = true;
  }

  /// Embedding üretmeden önce model hazır mı kontrolü
  bool get isReady => _isReady;

  /// Image → Embedding
  FaceEmbedding run(img.Image image) {
    if (!_isReady) {
      throw Exception("FaceEmbeddingExtractor: Model henüz yüklenmedi!");
    }

    final input = List.generate(112, (y) =>
        List.generate(112, (x) {
          final p = image.getPixel(x, y);
          
          // DÜZELTME BURADA YAPILDI:
          // image paketi v4'te getRed/getGreen yerine p.r/p.g kullanılır.
          final r = p.r;
          final g = p.g;
          final b = p.b;

          return [
            (r - 127.5) / 128.0,
            (g - 127.5) / 128.0,
            (b - 127.5) / 128.0,
          ];
        })
    );

    final output = List.filled(128, 0.0).reshape([1, 128]);
    _interpreter.run(input, output);

    return FaceEmbedding(output[0].cast<double>());
  }
}