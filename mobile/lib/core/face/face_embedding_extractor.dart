import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../../features/faceauth/domain/face_embedding.dart';

/// FaceEmbeddingExtractor
///
/// Bu sınıf, MobileFaceNet modelini kullanarak görüntüden embedding üretir.
/// Model yükleme işlemi async olduğundan, constructor içinde _init() çağrılır.
///
/// İş akışı:
/// 1) ImagePreprocessor → 112x112 normalize edilmiş img.Image
/// 2) FaceEmbeddingExtractor.run(image) → 128 boyutlu embedding
/// 3) FaceEmbedding → Domain model
class FaceEmbeddingExtractor {
  late Interpreter _interpreter;
  bool _isReady = false;

  FaceEmbeddingExtractor() {
    _init();
  }

  /// Modeli asenkron yükler
  Future<void> _init() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'models/mobilefacenet.tflite',
        options: InterpreterOptions()..threads = 4, // CPU optimize
      );
      _isReady = true;
    } catch (e) {
      // Model bulunamazsa sessizce devam et (Dummy mod)
      debugPrint("UYARI: Yüz tanıma modeli yüklenemedi. Dummy mod aktif. Hata: $e");
      _isReady = false;
    }
  }

  /// Embedding üretmeden önce model hazır mı kontrolü
  bool get isReady => _isReady;

  /// Image → Embedding
  FaceEmbedding run(img.Image image) {
    // EĞER MODEL YÜKLENEMEDİYSE DUMMY DATA DÖNDÜR
    if (!_isReady) {
      debugPrint("UYARI: Model yüklü değil, sahte (dummy) embedding döndürülüyor.");
      // 128 boyutlu rastgele veya sıfır vektörü döndür
      return FaceEmbedding(List.filled(128, 0.0));
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
}//FaceEmbeddingExtractor sınıfını güncelledim.
// Artık model dosyasını bulamazsa uygulama çökmeyecek,
// bunun yerine "Dummy Mod" devreye girecek ve sahte (boş) veri üretecek.
//<Bu sayede "Yüz Verisi Ekle" ekranına girip fotoğraf çekme akışını test edebilirsiniz.
//İleride mobilefacenet.tflite dosyasını bulup mobile/assets/models/ klasörüne koyduğunuzda,
// kod hiçbir değişiklik yapmanıza gerek kalmadan otomatik olarak gerçek yüz tanıma moduna geçecektir.