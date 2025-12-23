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

    // Call Camera Screen in Registration Mode
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraScreen(isRegistration: true),
      ),
    );

    if (result == true) {
      if (mounted) {
        setState(() {
          _hasFaceRegistered = true;
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
