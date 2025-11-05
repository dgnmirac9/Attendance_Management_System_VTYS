import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

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

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    try {
      final List<CameraDescription> cameras = await availableCameras();
      final CameraDescription front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _controller = CameraController(front, ResolutionPreset.medium, enableAudio: false);
      _initializeFuture = _controller!.initialize();
      setState(() {});
    } catch (e) {
      setState(() {
        _error = 'Kamera başlatılamadı: $e';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureAndValidate() async {
    if (_controller == null) return;
    setState(() => _busy = true);
    try {
      await _initializeFuture;
      final XFile shot = await _controller!.takePicture();

      // Face detection on the captured image
      final FaceDetectorOptions options = FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableLandmarks: false,
        enableContours: false,
        enableClassification: true, // smilingProbability for upSmile step
      );
      final FaceDetector detector = FaceDetector(options: options);
      final InputImage input = InputImage.fromFilePath(shot.path);
      final List<Face> faces = await detector.processImage(input);
      await detector.close();

      if (faces.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yüz algılanamadı. Lütfen tekrar deneyin.')),
        );
        setState(() => _busy = false);
        return;
      }

      // Optional light validation for upSmile: require some smile
      if (_sequence[_stepIndex] == _Pose.upSmile) {
        final double? prob = faces.first.smilingProbability;
        if (prob != null && prob < 0.5) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gülümseme tespit edilemedi, lütfen tekrar deneyin.')),
          );
          setState(() => _busy = false);
          return;
        }
      }

      _captures.add(shot.path);
      if (_stepIndex < _sequence.length - 1) {
        setState(() {
          _stepIndex += 1;
          _busy = false;
        });
      } else {
        if (!mounted) return;
        Navigator.of(context).pop<List<String>>(_captures);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
      setState(() => _busy = false);
    }
  }

  void _skipOptional() {
    // allow skipping the optional last step
    if (_sequence[_stepIndex] == _Pose.upSmile) {
      Navigator.of(context).pop<List<String>>(_captures);
    }
  }

  String _instructionText(_Pose pose) {
    switch (pose) {
      case _Pose.front:
        return 'Tam karşıya bakın';
      case _Pose.right:
        return 'Hafif sağa dönün';
      case _Pose.left:
        return 'Hafif sola dönün';
      case _Pose.upSmile:
        return 'Hafif yukarı bakın ve gülümseyin (opsiyonel)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yüz Verisi Yakalama'),
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
                        Positioned.fill(child: CameraPreview(_controller!)),
                        SafeArea(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 12),
                              // Step indicator
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
                              const SizedBox(height: 8),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _instructionText(current),
                                    style: const TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Row(
                                  children: [
                                    if (current == _Pose.upSmile)
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: _busy ? null : _skipOptional,
                                          child: const Text('Atla'),
                                        ),
                                      ),
                                    if (current == _Pose.upSmile) const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _busy ? null : _captureAndValidate,
                                        icon: const Icon(Icons.camera_alt),
                                        label: Text(_busy ? 'İşleniyor...' : 'Çek'),
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: const Size.fromHeight(56),
                                        ),
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


