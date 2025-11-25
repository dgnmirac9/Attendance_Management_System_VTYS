import 'dart:math' show sqrt;

/**
 * FaceEmbedding - Domain Model
 *
 * Bu sınıf bir kullanıcının yüzünü temsil eden sayısal vektörü (embedding) taşır.
 * MobileFaceNet gibi modeller, yüz görüntüsünü sabit uzunlukta (128 float) bir vektöre dönüştürür.
 *
 * Bu veri sadece "ham veri" değildir; kendi anlamı ve davranışı olan bir domain varlığıdır.
 * Yani, iki FaceEmbedding örneğinin birbirine ne kadar benzediğini söyleme görevi bu modele aittir.
 *
 * Neden davranış burada?
 * - Eğer karşılaştırma işlemi (cosine similarity) ViewModel veya UseCase içinde olsaydı,
 *   aynı hesaplama birçok yerde tekrar eder ve bakım / güvenlik sorunları oluşurdu.
 * - Domain Model, veriyi ve ona ait davranışı birlikte taşır → Clean Architecture prensibi.
 *
 * Nasıl kullanılır?
 *
 * final stored = FaceEmbedding(storedVector);
 * final scanned = FaceEmbedding(scannedVector);
 *
 * if (scanned.matches(stored)) {
 *   // Yüz doğrulandı → Login başarılı
 * } else {
 *   // Yüz uyuşmadı → Giriş reddedilir
 * }
 *
 * Yani: ViewModel sadece "karar" verir. Matematik bu modelin içindedir.
 */


class FaceEmbedding {
  /// Her zaman sabit uzunlukta (128 eleman) embedding listesi
  final List<double> values;

  const FaceEmbedding(this.values)
      : assert(values.length == 128, 'Embedding 128 uzunlukta olmalı.');

  /// Cosine similarity hesaplaması
  double similarity(FaceEmbedding other) {
    final a = values;
    final b = other.values;

    double dot = 0;
    double normA = 0;
    double normB = 0;

    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    final denominator = sqrt(normA) * sqrt(normB);
    if (denominator == 0) return 0;

    return dot / denominator;
  }

  /// İki embedding eşleşiyor mu?
  /// threshold → kullanım senaryosuna göre değişebilir (0.65 - 0.85 arası)
  bool matches(FaceEmbedding other, {double threshold = 0.75}) {
    return similarity(other) >= threshold;
  }
}
