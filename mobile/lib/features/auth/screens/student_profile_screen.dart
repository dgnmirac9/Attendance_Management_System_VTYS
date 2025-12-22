import 'dart:io';
import 'package:attendance_management_system_vtys/features/attendance/screens/camera_screen.dart';

import 'package:attendance_management_system_vtys/features/attendance/services/face_recognition_service.dart';
import 'package:attendance_management_system_vtys/features/auth/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  bool _isLoading = false;
  bool _hasFaceRegistered = false;

  @override
  void initState() {
    super.initState();
    _checkFaceRegistration();
  }

  Future<void> _checkFaceRegistration() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final embedding = await UserService().getFaceEmbedding(user.uid);
      if (mounted) {
        setState(() {
          _hasFaceRegistered = embedding != null;
        });
      }
    }
  }

  Future<void> _registerFace() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Take Photo
    final photoFile = await Navigator.push<File>(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraScreen(),
      ),
    );

    if (photoFile == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 2. Detect Face
      final inputImage = InputImage.fromFile(photoFile);
      final faceDetector = FaceDetector(options: FaceDetectorOptions());
      final faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      if (faces.isEmpty) {
        throw Exception("Fotoğrafta yüz bulunamadı! Lütfen yüzünüzü net bir şekilde gösterin.");
      }

      // 3. Generate Embedding
      final embedding = await FaceRecognitionService.instance.generateEmbedding(photoFile, faces.first);

      // 4. Save to Firestore
      await UserService().saveFaceEmbedding(user.uid, embedding);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yüzünüz başarıyla sisteme tanımlandı'), backgroundColor: Colors.green),
        );
        setState(() {
          _hasFaceRegistered = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profilim')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 16),
            Text(
              user?.email ?? 'Öğrenci',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Yüz Tanıma Durumu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  Icon(
                    _hasFaceRegistered ? Icons.check_circle : Icons.warning_amber_rounded,
                    color: _hasFaceRegistered ? Colors.green : Colors.orange,
                    size: 64,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _hasFaceRegistered ? 'Yüzünüz Kayıtlı' : 'Yüzünüz Kayıtlı Değil',
                    style: TextStyle(
                      color: _hasFaceRegistered ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _registerFace,
                    icon: const Icon(Icons.face),
                    label: Text(_hasFaceRegistered ? 'Yüzümü Güncelle' : 'Yüzümü Kaydet'),
                  ),
                  if (!_hasFaceRegistered)
                    const Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: Text(
                        'Yoklamalara katılabilmek için yüzünüzü kaydetmeniz gerekmektedir.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
