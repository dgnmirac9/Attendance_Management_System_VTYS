import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import '../../../../shared/utils/validators.dart'; // validateRequired fonksiyonu için
import '../../../authentication/data/auth_service.dart';

class CreateClassDialog extends StatefulWidget {
  const CreateClassDialog({super.key});

  @override
  State<CreateClassDialog> createState() => _CreateClassDialogState();
}

class _CreateClassDialogState extends State<CreateClassDialog> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final String _teacherUid = FirebaseAuth.instance.currentUser!.uid;

  final TextEditingController _classNameController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _classNameController.dispose();
    super.dispose();
  }

  // --- SINIF OLUŞTURMA İŞLEMİ ---
  void _handleCreateClass() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // createClass, başarılıysa 6 haneli kodu döndürecek
    final result = await _authService.createClass(
      className: _classNameController.text.trim(),
      teacherUid: _teacherUid,
    );

    if (mounted) setState(() => _isLoading = false);

    if (result != null && !result.startsWith('Hata')) { 
      if (mounted) {
        Navigator.pop(context); // Diyaloğu kapat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sınıf başarıyla oluşturuldu! Sınıf Kodunuz: $result'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5), // Kodu rahat okuması için süreyi uzattık
          ),
        );
      }
    } else {
      if (mounted) {
        // Hata durumunda result bir String ("Hata: ...") döndürecektir.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result ?? 'Bilinmeyen bir hata oluştu.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Yeni Sınıf Oluştur', style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 20)),
            const SizedBox(height: 24),
            
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Sınıf Adı
                  TextFormField(
                    controller: _classNameController,
                    decoration: const InputDecoration(labelText: 'Sınıf Adı', prefixIcon: Icon(Icons.school)),
                    validator: (val) => validateRequired(val, fieldName: 'Sınıf Adı'),
                  ),
                  const SizedBox(height: 16),
                  
                  // Bilgilendirme Notu
                  const Text(
                    'Sınıf kodu otomatik olarak 6 haneli ve benzersiz şekilde üretilecektir.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // OLUŞTUR BUTONU
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleCreateClass,
                child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Sınıfı Oluştur'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}