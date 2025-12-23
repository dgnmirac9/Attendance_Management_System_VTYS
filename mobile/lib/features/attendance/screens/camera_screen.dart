import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:attendance_management_system_vtys/features/attendance/services/face_recognition_service.dart';
import 'package:attendance_management_system_vtys/features/auth/services/user_service.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class CameraScreen extends StatefulWidget {
  final bool isRegistration;

  const CameraScreen({
    super.key,
    this.isRegistration = false,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with TickerProviderStateMixin {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isProcessing = false;
  Timer? _blinkTimer;
  bool _isLedOn = true;

  // Verification Status: 'IDLE', 'VERIFYING', 'SUCCESS', 'FAILED'
  String _verificationStatus = 'IDLE'; 
  double _similarityScore = 0.0;
  String _statusMessage = "";

  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _initCamera();
    
    if (!widget.isRegistration) {
      _startBlinkTimer();
      _scanController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
      )..repeat(reverse: true);
      _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_scanController);
    } else {
      _scanController = AnimationController(vsync: this);
      _scanAnimation = AlwaysStoppedAnimation(0.0);
    }
  }

  void _startBlinkTimer() {
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (mounted) {
        setState(() {
          _isLedOn = !_isLedOn;
        });
      }
    });
  }

  Future<void> _initCamera() async {
    await FaceRecognitionService().loadModel();
    final cameras = await availableCameras();
    final firstCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      firstCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    _scanController.dispose();
    _blinkTimer?.cancel();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _verificationStatus = widget.isRegistration ? 'PROCESSING' : 'VERIFYING'; // Initial State
    });

    try {
      final image = await _controller!.takePicture();
      final file = File(image.path);

      if (widget.isRegistration) {
        await _handleRegistration(file);
      } else {
        await _handleAttendance(file);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _verificationStatus = 'IDLE';
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
  }

  Future<void> _handleRegistration(File photoFile) async {
    try {
      final inputImage = InputImage.fromFile(photoFile);
      final faceDetector = FaceDetector(options: FaceDetectorOptions());
      final faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      if (faces.isEmpty) {
        throw Exception("Yüz bulunamadı!");
      }

      final embedding = await FaceRecognitionService.instance.generateEmbedding(photoFile, faces.first);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await UserService().saveFaceEmbedding(user.uid, embedding);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kayıt Başarılı!'), backgroundColor: Colors.green));
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleAttendance(File file) async {
    try {
      // 1. Detect Face
      final inputImage = InputImage.fromFile(file);
      final faceDetector = FaceDetector(options: FaceDetectorOptions());
      final faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      if (faces.isEmpty) {
        _setVerificationResult('FAILED', 'YÜZ BULUNAMADI');
        return;
      }

      // 2. Generate Embedding
      final currentEmbedding = await FaceRecognitionService.instance.generateEmbedding(file, faces.first);

      // 3. Get User Stored Embedding
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _setVerificationResult('FAILED', 'OTURUM HATASI');
        return;
      }
      final storedEmbedding = await UserService().getFaceEmbedding(user.uid);

      if (storedEmbedding == null) {
         _setVerificationResult('FAILED', 'KAYITLI YÜZ YOK');
         return;
      }

      // 4. Compare
      final distance = FaceRecognitionService.instance.calculateDistance(currentEmbedding, storedEmbedding);
      // Determine threshold (Using standard 0.60 or 0.70 usually, let's say 0.70 for mobilefacenet is safeish, 
      // but the user's settings screen default is 0.60. Let's use 0.60 as strict)
      final threshold = 0.60; 

      if (distance <= threshold) {
        // Calculate a nice percentage score for display: map distance 0.0-0.6 to 100%-60% estimate
        // Just for visual "Match Score"
        final score = max(0.0, 1.0 - distance); 
        _similarityScore = score;
        
        setState(() {
           _verificationStatus = 'SUCCESS'; 
        });
        
        // Wait and Return
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.of(context).pop(file); // Return file to caller (which will handle attendance record)

      } else {
        _similarityScore = max(0.0, 1.0 - distance);
        _setVerificationResult('FAILED', 'EŞLEŞME BAŞARISIZ');
      }

    } catch (e) {
      _setVerificationResult('FAILED', 'HATA OLUŞTU');
    }
  }

  Future<void> _setVerificationResult(String status, String message) async {
    if (mounted) {
      setState(() {
        _verificationStatus = status;
        _statusMessage = message;
      });
      // Verification Failed - Retry logic
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _verificationStatus = 'IDLE'; // Reset to scanning
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              fit: StackFit.expand,
              children: [
                CameraPreview(_controller!),

                // HUD Layer
                if (_verificationStatus == 'IDLE' || widget.isRegistration)
                   _buildIdleOverlay(),
                
                // Result Overlay (Processing/Success/Fail)
                if (_verificationStatus != 'IDLE' && !widget.isRegistration)
                   _buildResultOverlay(),

                // Buttons
                if (_verificationStatus == 'IDLE' || widget.isRegistration)
                  _buildBottomControls(),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget _buildIdleOverlay() {
    return Stack(
      children: [
         Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),
          if (!widget.isRegistration)
            CustomPaint(painter: GridPainter(), child: Container()),

          if (!widget.isRegistration)
            Positioned(
              top: 50, left: 20, right: 20,
              child: _buildSystemInfo(),
            ),
          
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 280, height: 380,
                  child: CustomPaint(
                    painter: CornerPainter(
                      color: widget.isRegistration ? const Color(0xFF00E676) : const Color(0xFF00E5FF)
                    ),
                  ),
                ),
                if (!widget.isRegistration)
                  AnimatedBuilder(
                    animation: _scanAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: _scanAnimation.value * 380,
                        child: Container(
                          width: 280, height: 2,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E5FF),
                            boxShadow: [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.8), blurRadius: 10)],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildResultOverlay() {
    Color statusColor;
    String title;
    String subtitle;
    IconData icon;

    switch (_verificationStatus) {
      case 'VERIFYING':
        statusColor = const Color(0xFFFFD600); // Amber
        title = "KİMLİK DOĞRULANIYOR...";
        subtitle = "Lütfen bekleyiniz";
        icon = Icons.hourglass_empty;
        break;
      case 'SUCCESS':
        statusColor = const Color(0xFF00E676); // Green
        title = "KİMLİK DOĞRULANDI";
        subtitle = "Eşleşme Oranı: %${(_similarityScore * 100).toStringAsFixed(1)}";
        icon = Icons.check_circle_outline;
        break;
      case 'FAILED':
        statusColor = const Color(0xFFFF1744); // Red
        title = _statusMessage.isNotEmpty ? _statusMessage : "EŞLEŞME BAŞARISIZ";
        subtitle = "Tekrar deneniyor...";
        icon = Icons.error_outline;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: statusColor, width: 4),
                boxShadow: [BoxShadow(color: statusColor.withOpacity(0.4), blurRadius: 30)],
              ),
              child: _verificationStatus == 'VERIFYING'
                  ? CircularProgressIndicator(color: statusColor)
                  : Icon(icon, color: statusColor, size: 48),
            ),
            const SizedBox(height: 32),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.orbitron(
                color: statusColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  color: _isLedOn ? const Color(0xFF00FF00) : Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: _isLedOn ? [const BoxShadow(color: Color(0xFF00FF00), blurRadius: 5)] : [],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "SİSTEM AKTİF",
                style: GoogleFonts.shareTechMono(color: const Color(0xFF00FF00), fontSize: 14, letterSpacing: 2),
              ),
            ],
          ),
          Text(
            "FACE_ID_CAM_01",
            style: GoogleFonts.shareTechMono(color: const Color(0xFF00E5FF), fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 40, left: 20, right: 20,
      child: widget.isRegistration
          ? SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _takePicture,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: const Color(0xFF1A237E),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: const StadiumBorder(),
                  elevation: 10,
                  shadowColor: const Color(0xFF00E676).withOpacity(0.6),
                ),
                child: _isProcessing
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Color(0xFF1A237E)))
                    : Text(
                        "YÜZÜMÜ KAYDET",
                        style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.5),
                      ),
              ),
            )
          : Column(
              children: [
                Text(
                  "YÜZÜ ÇERÇEVEYE ALINIZ",
                  style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14, letterSpacing: 2),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00E5FF), width: 4),
                      color: Colors.white.withOpacity(0.1),
                      boxShadow: [BoxShadow(color: const Color(0xFF00E5FF).withOpacity(0.4), blurRadius: 15, spreadRadius: 2)],
                    ),
                    child: Center(
                      child: Container(
                        width: 60, height: 60,
                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                        child: const Icon(Icons.fingerprint, color: Colors.black, size: 40),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class CornerPainter extends CustomPainter {
  final Color color;
  CornerPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 4..style = PaintingStyle.stroke..strokeCap = StrokeCap.square; 
    double length = 40;
    canvas.drawLine(Offset(0, length), Offset(0, 0), paint); canvas.drawLine(Offset(0, 0), Offset(length, 0), paint);
    canvas.drawLine(Offset(size.width - length, 0), Offset(size.width, 0), paint); canvas.drawLine(Offset(size.width, 0), Offset(size.width, length), paint);
    canvas.drawLine(Offset(0, size.height - length), Offset(0, size.height), paint); canvas.drawLine(Offset(0, size.height), Offset(length, size.height), paint);
    canvas.drawLine(Offset(size.width - length, size.height), Offset(size.width, size.height), paint); canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - length), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.05)..strokeWidth = 1;
    double step = 40;
    for (double x = 0; x < size.width; x += step) canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y < size.height; y += step) canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
