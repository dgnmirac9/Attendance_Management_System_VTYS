/**
 * ImagePreprocessor
 *
 * Kamera tarafından alınan görüntüyü modele uygun hale getirir.
 * Bu sınıf UI veya ViewModel'e bağımlı değildir → core katmanında yer alır.
 *
 * Yapılan işlemler:
 * - Görüntü okunur
 * - 112x112 boyutuna küçültülür (MobileFaceNet standardı)
 * - Normalizasyon üstte FaceEmbeddingExtractor'da yapılır
 *
 * Bu sınıf sadece veri hazırlar, embedding üretmez.
 */

import 'dart:io';
import 'package:image/image.dart' as img;

class Image_preprocessor {
  static img.Image preprocess(File file) {
    final data = file.readAsBytesSync();
    img.Image image = img.decodeImage(data)!;

    return img.copyResize(image, width: 112, height: 112);
  }
}
