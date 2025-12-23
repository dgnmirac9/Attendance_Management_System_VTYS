import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../features/auth/providers/auth_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  double _similarityThreshold = 0.60;
  bool _notificationEnabled = true;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF1A237E), // FIX 1: Set Background Color
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Ayarlar', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        height: double.infinity, // FIX 2: Ensure full height
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A237E),
              Color(0xFF0D47A1),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. PROFILE CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withOpacity(0.1),
                        child: const Icon(Icons.person, size: 36, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'Kullanıcı',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user?.email ?? '',
                              style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Şifre değiştirme yakında eklenecek')));
                        },
                        icon: const Icon(Icons.lock_reset, color: Color(0xFF00E5FF)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 2. FACE REC SETTINGS
                Text(
                  "Yüz Tanıma Ayarları",
                  style: GoogleFonts.orbitron(
                    color: const Color(0xFF00E5FF),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Benzerlik Eşiği (Threshold)", style: GoogleFonts.poppins(color: Colors.white)),
                          Text(
                            _similarityThreshold.toStringAsFixed(2),
                            style: GoogleFonts.shareTechMono(color: const Color(0xFF00E676), fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF2979FF),
                          inactiveTrackColor: Colors.white.withOpacity(0.2),
                          thumbColor: const Color(0xFF00E5FF),
                          overlayColor: const Color(0xFF00E5FF).withOpacity(0.2),
                        ),
                        child: Slider(
                          value: _similarityThreshold,
                          min: 0.0,
                          max: 1.0,
                          onChanged: (value) {
                            setState(() {
                              _similarityThreshold = value;
                            });
                          },
                        ),
                      ),
                      Text(
                        "Şu anki değer: ${_similarityThreshold.toStringAsFixed(2)}",
                        style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 3. NOTIFICATIONS
                Text(
                  "Bildirimler",
                  style: GoogleFonts.orbitron(
                    color: const Color(0xFF00E5FF),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Ders Başlangıç Uyarısı", style: GoogleFonts.poppins(color: Colors.white)),
                      Switch(
                        value: _notificationEnabled,
                        activeColor: const Color(0xFF00E676),
                        activeTrackColor: const Color(0xFF00E676).withOpacity(0.4),
                        inactiveThumbColor: Colors.white60,
                        inactiveTrackColor: Colors.white10,
                        onChanged: (value) {
                          setState(() {
                            _notificationEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // 4. LOGOUT BUTTON
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref.read(authControllerProvider.notifier).signOut();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    icon: const Icon(Icons.logout, color: Color(0xFFFF5252)),
                    label: Text(
                      "ÇIKIŞ YAP",
                      style: GoogleFonts.orbitron(
                        color: const Color(0xFFFF5252),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFF5252), width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
