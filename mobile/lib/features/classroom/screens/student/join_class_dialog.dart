import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/classroom_provider.dart';
import '../../../../core/utils/snackbar_utils.dart';

class JoinClassDialog extends ConsumerStatefulWidget {
  const JoinClassDialog({super.key});

  @override
  ConsumerState<JoinClassDialog> createState() => _JoinClassDialogState();
}

class _JoinClassDialogState extends ConsumerState<JoinClassDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }


  Future<void> _joinClass() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(classroomControllerProvider.notifier).joinClass(
          joinCode: _codeController.text.trim().toUpperCase(),
        );
        if (mounted) {
          Navigator.of(context).pop();
          SnackbarUtils.showSuccess(context, 'Derse başarıyla katıldınız');
        }
      } catch (e) {
        if (mounted) {
          final message = e.toString().replaceAll('Exception: ', '');
          SnackbarUtils.showError(context, message);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(classroomControllerProvider);
    final isLoading = state.isLoading;

    return AlertDialog(
      title: const Text('Derse Katıl'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Ders Kodu',
                hintText: 'Örn: X9A2B1',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (value) => value == null || value.isEmpty ? 'Kod gerekli' : null,
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _joinClass,
          child: isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Katıl'),
        ),
      ],
    );
  }
}
