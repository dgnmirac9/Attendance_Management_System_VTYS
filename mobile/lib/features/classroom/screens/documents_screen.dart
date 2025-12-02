import 'package:attendance_management_system_vtys/features/auth/providers/auth_controller.dart';
import 'package:attendance_management_system_vtys/features/classroom/services/document_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentsScreen extends ConsumerWidget {
  final String classId;
  final bool isAcademic;

  const DocumentsScreen({
    super.key,
    required this.classId,
    required this.isAcademic,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentService = DocumentService();

    return Scaffold(
      appBar: AppBar(title: const Text('Ders Dokümanları')),
      body: StreamBuilder(
        stream: documentService.getDocuments(classId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('Henüz yüklenen doküman yok.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index].data() as Map<String, dynamic>;
              final name = doc['name'] as String;
              final url = doc['url'] as String;
              final type = doc['type'] as String?;

              IconData iconData = Icons.insert_drive_file;
              if (type == 'pdf') iconData = Icons.picture_as_pdf;
              if (['jpg', 'jpeg', 'png'].contains(type)) iconData = Icons.image;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(iconData, color: Colors.blue),
                  title: Text(name),
                  subtitle: Text(type?.toUpperCase() ?? 'DOSYA'),
                  trailing: const Icon(Icons.download),
                  onTap: () async {
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Dosya açılamadı')),
                        );
                      }
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: isAcademic
          ? FloatingActionButton(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles();

                if (result != null) {
                  final file = result.files.first;
                  final user = ref.read(authStateChangesProvider).value;

                  if (user != null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Yükleniyor...')),
                      );
                    }

                    try {
                      await documentService.uploadDocument(
                        classId: classId,
                        file: file,
                        uploadedBy: user.uid,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Doküman yüklendi!')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Hata: $e')),
                        );
                      }
                    }
                  }
                }
              },
              child: const Icon(Icons.upload_file),
            )
          : null,
    );
  }
}
