import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// ORTAK WIDGET İMPORTU (DRY ilkesi)
import '../../../../shared/themes/custom_transparent_appbar.dart'; 

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  // Barkod bir kere okunsun diye kilit
  bool _isScanned = false;

  // ... (Gereken metotlar buraya devam ediyor: initState, dispose, onDetect, etc.)

  @override
  void initState() {
    super.initState();
    // Ekran açılırken izinler ve kamera başlar
  }

  // --- Buradaki metotlar önceki koddan aynen korunuyor ---
  // onDetect metodu, MobileScanner widget'ının içinde tanımlıdır.
  // ...

  @override
  Widget build(BuildContext context) {
    // 1. TEMADAN ANA RENGİ ÇEKİYORUZ
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      extendBodyBehindAppBar: true, // Kamera tam ekran olsun
      
      // --- APP BAR FIX: Custom Widget Kullanımı ---
      appBar: const CustomTransparentAppBar(
        titleText: 'Kodu Taratın', 
      ),
      
      body: Stack(
        children: [
          // 1. KAMERA
          MobileScanner(
            onDetect: (capture) {
              if (_isScanned) return; 
              
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  setState(() {
                    _isScanned = true;
                  });
                  
                  final String code = barcode.rawValue!;
                  debugPrint('QR Okundu: $code');
                  
                  if (mounted) {
                    Navigator.pop(context, code);
                  }
                  break; 
                }
              }
            },
          ),

          // 2. KAMAŞTIRMA (DIMMER) EFEKTİ VE KARE DELİK
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.7), 
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                // Arka planı karartma
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                // Ortadaki kamera penceresi (delik)
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 280,
                    width: 280,
                    decoration: BoxDecoration(
                      color: Colors.black, // Delik olduğu için siyah görünür
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. ÇERÇEVE SÜSÜ VE YAZI
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mavi Köşeli Çerçeve Süsü (Temadan Renk Çeker)
                Container(
                  height: 280,
                  width: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primaryColor, width: 3),
                  ),
                ),
                const SizedBox(height: 20),
                // Talimat Kutusu (Yüksek Kontrast için Sabit Siyah/Beyaz)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "QR Kodu çerçevenin içine tutun",
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}