import 'package:flutter/material.dart';
 
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
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.group_add, color: theme.colorScheme.primary, size: 32),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Sınıf Kodu',
                hintText: 'Öğretmeninizden aldığınız kodu girin',
                prefixIcon: const Icon(Icons.vpn_key_outlined),
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'İptal',
                      style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
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