import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/classroom_provider.dart';

class CreateClassDialog extends ConsumerStatefulWidget {
  const CreateClassDialog({super.key});

  @override
  ConsumerState<CreateClassDialog> createState() => _CreateClassDialogState();
}

class _CreateClassDialogState extends ConsumerState<CreateClassDialog> {
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  final _teacherNameController = TextEditingController();

  @override
  void dispose() {
    _classNameController.dispose();
    _teacherNameController.dispose();
    super.dispose();
  }

  Future<void> _createClass() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(classroomControllerProvider.notifier).createClass(
          className: _classNameController.text.trim(),
          teacherName: _teacherNameController.text.trim(),
        );
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ders başarıyla oluşturuldu')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(classroomControllerProvider);
    final isLoading = state.isLoading;

    return AlertDialog(
      title: const Text('Ders Oluştur'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _classNameController,
              decoration: const InputDecoration(labelText: 'Ders Adı (Örn: YZM302)'),
              validator: (value) => value == null || value.isEmpty ? 'Ders adı gerekli' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _teacherNameController,
              decoration: const InputDecoration(labelText: 'Öğretim Görevlisi Adı'),
              validator: (value) => value == null || value.isEmpty ? 'İsim gerekli' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : _createClass,
          child: isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Oluştur'),
        ),
      ],
    );
  }
}
