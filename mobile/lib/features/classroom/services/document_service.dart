import 'package:file_picker/file_picker.dart';

class DocumentService {
  // Mock upload (since backend API for files isn't ready)
  Future<void> uploadDocument({
    required String classId,
    required PlatformFile file,
    required String uploadedBy,
  }) async {
    // Return or throw "Not Implemented"
    throw "Dosya yükleme henüz aktif değil.";
  }

  // Mock get documents (Stream of List<Map>)
  Stream<List<Map<String, dynamic>>> getDocuments(String classId) {
    // Return empty list
    return Stream.value([]);
  }
}
