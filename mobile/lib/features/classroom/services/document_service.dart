import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../../core/constants/firestore_constants.dart';

class DocumentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload a document for a class
  Future<void> uploadDocument({
    required String classId,
    required PlatformFile file,
    required String uploadedBy,
  }) async {
    try {
      final fileName = file.name;
      final storageRef = _storage.ref().child('class_documents/$classId/$fileName');

      // Upload file
      if (kIsWeb) {
        await storageRef.putData(file.bytes!);
      } else {
        await storageRef.putFile(File(file.path!));
      }

      final downloadUrl = await storageRef.getDownloadURL();

      // Save metadata to Firestore
      await _firestore
          .collection(FirestoreConstants.classesCollection)
          .doc(classId)
          .collection(FirestoreConstants.documentsCollection)
          .add({
        'name': fileName,
        'url': downloadUrl,
        'type': file.extension,
        'size': file.size,
        'uploadedBy': uploadedBy,
        'uploadedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error uploading document: $e');
      rethrow;
    }
  }

  // Get stream of documents for a class
  Stream<QuerySnapshot> getDocuments(String classId) {
    return _firestore
        .collection(FirestoreConstants.classesCollection)
        .doc(classId)
        .collection(FirestoreConstants.documentsCollection)
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }
}
