import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import '../../../authentication/data/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../shared/utils/snackbar_utils.dart';

class JoinClassDialog extends StatefulWidget {
  const JoinClassDialog({super.key});

  @override
  State<JoinClassDialog> createState() => _JoinClassDialogState();
}

class _JoinClassDialogState extends State<JoinClassDialog> {
  final TextEditingController _codeController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // --- KATILMA İŞLEMİ ---
  void _handleJoin() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      SnackbarUtils.showError(context, 'Lütfen 6 haneli sınıf kodunu girin.');
      return;
    }

    final studentUid = FirebaseAuth.instance.currentUser?.uid;
    if (studentUid == null) return; 
    
    setState(() => _isLoading = true);

    // joinClass artık sadece 6 haneli kodu gönderiyor
    final error = await _authService.joinClass(code, studentUid);

    if (mounted) setState(() => _isLoading = false);

    if (error == null) {
      if (mounted) {
        Navigator.pop(context);
        SnackbarUtils.showSuccess(context, 'Sınıfa başarıyla katıldınız!');
      }
    } else {
      if (mounted) {
        SnackbarUtils.showError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0), 
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.group_add, size: 40, color: primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Sınıfa Katıl', 
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold, 
                color: primaryColor
              )
            ),
            const SizedBox(height: 20),

            // Kod Giriş Alanı (SADECE 6 HANE)
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6), // Tam 6 hane
              ],
              style: const TextStyle(fontSize: 24, letterSpacing: 5, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '6 HANELİ KOD', 
                hintStyle: const TextStyle(fontSize: 16, letterSpacing: 1),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
              ),
              enabled: !_isLoading, 
            ),
            
            const SizedBox(height: 24),

            // --- ONAY BUTONLARI ---
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context), 
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('İptal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleJoin, 
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Katıl'),
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