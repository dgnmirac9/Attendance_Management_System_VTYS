import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../../core/widgets/custom_transparent_appbar.dart'; 
import '../../../core/utils/snackbar_utils.dart'; 

class FaceCaptureScreen extends StatefulWidget {
  const FaceCaptureScreen({super.key});

  @override
  State<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

enum _Pose { front, right, left, upSmile }

class _FaceCaptureScreenState extends State<FaceCaptureScreen> {
  CameraController? _controller;
  Future<void>? _initializeFuture;
  bool _busy = false;
  String? _error;

  final List<_Pose> _sequence = const [_Pose.front, _Pose.right, _Pose.left, _Pose.upSmile];
  int _stepIndex = 0;
  final List<String> _captures = <String>[];

  // Yüz dedektörü
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableLandmarks: true,
      enableClassification: true,
    ),
  );

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    try {
      final List<CameraDescription> cameras = await availableCameras();
      if (cameras.isEmpty) {
         setState(() => _error = "Kamera bulunamadı. (Simülatör?)");
         return;
      }
      final CameraDescription front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      
      _controller = CameraController(front, ResolutionPreset.medium, enableAudio: false);
      _initializeFuture = _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Kamera başlatılamadı: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _captureAndValidate() async {
    if (_controller == null || _busy) return;
    setState(() => _busy = true);
    
    try {
      await _initializeFuture;
      final XFile shot = await _controller!.takePicture();
      final File file = File(shot.path);
      final InputImage inputImage = InputImage.fromFile(file);

      final List<Face> faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        throw 'Yüz bulunamadı. Lütfen kameraya bakın.';
      }
      if (faces.length > 1) {
        throw 'Birden fazla yüz algılandı. Tek kişi olmalı.';
      }

      final Face face = faces.first;
      final _Pose currentPose = _sequence[_stepIndex];

      _validatePose(face, currentPose);

      // Başarılı
      _captures.add(shot.path);
      
      if (_captures.length == _sequence.length) {
        if (mounted) {
          SnackbarUtils.showSuccess(context, 'Tüm taramalar tamamlandı!');
          Navigator.pop(context, _captures);
        }
      } else {
        if (mounted) {
          SnackbarUtils.showSuccess(context, 'Başarılı! Sıradaki adıma geçiliyor.');
          setState(() {
            _stepIndex++;
          });
        }
      }

    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _validatePose(Face face, _Pose pose) {
    final double headEulerAngleY = face.headEulerAngleY ?? 0; // Sağa/Sola dönüş
    final double headEulerAngleX = face.headEulerAngleX ?? 0; // Yukarı/Aşağı eğim
    final double? smilingProbability = face.smilingProbability;

    switch (pose) {
      case _Pose.front:
        if (headEulerAngleY.abs() > 10 || headEulerAngleX.abs() > 10) {
          throw 'Lütfen tam karşıya bakın.';
        }
        break;
      case _Pose.right:
        // Kullanıcı sağa dönünce Y açısı negatif olur (ayna etkisi yoksa) veya pozitif. 
        // Genelde: Sola dönünce pozitif, sağa dönünce negatif.
        // Eşik değerleri test edilmeli, şimdilik varsayılan mantık.
        if (headEulerAngleY > -20) { 
          throw 'Yüzünüzü biraz daha sağa çevirin.';
        }
        break;
      case _Pose.left:
        if (headEulerAngleY < 20) {
          throw 'Yüzünüzü biraz daha sola çevirin.';
        }
        break;
      case _Pose.upSmile:
        if (headEulerAngleX > -10) { // Yukarı bakınca X negatif olur (genelde)
           // throw 'Biraz yukarı bakın.'; // Çok katı olmamak için kapattım
        }
        if (smilingProbability != null && smilingProbability < 0.5) {
          throw 'Lütfen gülümseyin!';
        }
        break;
    }
  }

  void _skipOptional() {
    // Sadece son adım (upSmile) opsiyonel kabul ediliyor
    if (_sequence[_stepIndex] == _Pose.upSmile) {
       if (mounted) {
          SnackbarUtils.showInfo(context, 'Son adım atlandı. Kayıt tamamlanıyor.');
          Navigator.pop(context, _captures);
       }
    }
  }

  String _instructionText(_Pose pose) {
    switch (pose) {
      case _Pose.front: return 'Tam karşıya bakın';
      case _Pose.right: return 'Hafif sağa dönün';
      case _Pose.left: return 'Hafif sola dönün';
      case _Pose.upSmile: return 'Hafif yukarı bakın ve gülümseyin';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceColor = theme.colorScheme.surface.withValues(alpha: 0.85); 
    const fixedTextColor = Colors.white; 

    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: const CustomTransparentAppBar(
        titleText: 'Yüz Taraması', 
      ),
      
      body: _error != null
          ? Center(child: Text(_error!))
          : (_controller == null || _initializeFuture == null)
              ? const Center(child: CircularProgressIndicator())
              : FutureBuilder<void>(
                  future: _initializeFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final _Pose current = _sequence[_stepIndex];
                    return Stack(
                      children: [
                        // 1. Kamera
                        Positioned.fill(child: CameraPreview(_controller!)),
                        
                        // 2. Arayüz Elemanları
                        SafeArea(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 20),
                              
                              // Adım Noktaları
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(_sequence.length, (i) {
                                  final bool done = i < _captures.length;
                                  final bool active = i == _stepIndex;
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: active ? 14 : 10,
                                    height: active ? 14 : 10,
                                    decoration: BoxDecoration(
                                      color: done ? Colors.greenAccent : (active ? Colors.white : Colors.white54),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.black26),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 20),
                              
                              // --- TALİMAT YAZISI (GÖLGELİ BEYAZ) ---
                              Center(
                                child: Text(
                                  _instructionText(current),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: fixedTextColor, // Beyaz
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        offset: const Offset(1, 1),
                                        blurRadius: 3,
                                        color: Colors.black.withValues(alpha: 0.8),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              
                              const Spacer(),
                              
                              // Alt Butonlar
                              Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Row(
                                  children: [
                                    if (current == _Pose.upSmile)
                                      Expanded(
                                        child: Container(
                                          margin: const EdgeInsets.only(right: 12),
                                          decoration: BoxDecoration(
                                            color: surfaceColor, 
                                            borderRadius: BorderRadius.circular(20)
                                          ),
                                          child: OutlinedButton(
                                            onPressed: _busy ? null : _skipOptional,
                                            style: OutlinedButton.styleFrom(side: BorderSide.none),
                                            child: const Text('Atla'),
                                          ),
                                        ),
                                      ),
                                    
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _busy ? null : _captureAndValidate,
                                        icon: const Icon(Icons.camera_alt),
                                        label: Text(_busy ? 'İşleniyor...' : 'Çek'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}
