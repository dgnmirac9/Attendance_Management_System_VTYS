import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/widgets/custom_transparent_appbar.dart';

class CameraScreen extends StatefulWidget {
  // Optional callback for processing photo in-screen
  // If provided: photo processed here with loading/retry
  // If null: photo returned to caller (backward compatible)
  final Future<bool> Function(File photo)? onPhotoTaken;
  
  const CameraScreen({super.key, this.onPhotoTaken});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.veryHigh,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final image = await _controller!.takePicture();
      final photoFile = File(image.path);
      
      if (widget.onPhotoTaken != null) {
        // Process in-screen with callback
        final success = await widget.onPhotoTaken!(photoFile);
        
        if (!mounted) return;
        
        if (success) {
          // Success! Close camera and return to class screen
          Navigator.pop(context, true);
        } else {
          // Failed! Stay in camera, allow retry
          setState(() {
            _isProcessing = false;
          });
          // Error message shown by callback
        }
      } else {
        // Legacy behavior: return file to caller
        if (mounted) {
          Navigator.pop(context, photoFile);
        }
      }
    } catch (e) {
      debugPrint('Camera error: $e');
      if (mounted) {
        SnackbarUtils.showError(context, "Hata: $e");
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomTransparentAppBar(titleText: 'Yüz Doğrulama'),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                // 1. Camera Preview
                SizedBox.expand(
                  child: CameraPreview(_controller!),
                ),
                
                // 2. Overlay guide
                Center(
                  child: Container(
                    width: 300,
                    height: 400,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),

                // 3. UI Elements (Button)
                SafeArea(
                  child: Column(
                    children: [
                      const Spacer(),
                      
                      // Bottom Button
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _takePicture,
                            icon: const Icon(Icons.camera_alt),
                            label: Text(_isProcessing ? 'İşleniyor...' : 'Çek'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
