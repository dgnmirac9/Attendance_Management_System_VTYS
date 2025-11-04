/**
 * FaceAuthViewModel
 *
 * Bu ViewModel kameradan alınan görüntüyü core katmanına (model → embedding) aktarır.
 * Burada "yüzün ne olduğu" bilinmez, sadece embedding üretimi yapılır.
 *
 * Üretilen embedding UI tarafından dinlenir → Signup veya Login ViewModel’e aktarılır.
 */

import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../core/face/image_preprocessor.dart';
import '../../../core/face/face_embedding_extractor.dart';
import 'package:c_lens_mobile/features/faceauth/domain/face_embedding.dart';

class Face_auth_viewModel extends ChangeNotifier {
  final Face_embedding_extractor extractor = Face_embedding_extractor();
  Face_embedding? embedding;

  void onImageCaptured(File file) {
    final processed = Image_preprocessor.preprocess(file);
    embedding = extractor.run(processed);
    notifyListeners();
  }
}
