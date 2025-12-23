import 'package:attendance_management_system_vtys/features/auth/providers/auth_controller.dart';
import 'package:attendance_management_system_vtys/features/classroom/services/document_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Ders Dokümanları', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A237E), // Koyu Lacivert
              Color(0xFF0D47A1),
            ],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder(
            stream: documentService.getDocuments(classId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Hata: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)));
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index].data() as Map<String, dynamic>;
                  final name = doc['name'] as String;
                  final url = doc['url'] as String;
                  final type = doc['type'] as String?;
                  
                  // Dummy date/size logic since not provided in original map, feel free to update schema later
                  final date = "Bugün"; 

                  IconData iconData = Icons.insert_drive_file;
                  if (type == 'pdf') iconData = Icons.picture_as_pdf;
                  else if (['jpg', 'jpeg', 'png'].contains(type)) iconData = Icons.image;
                  else if (['doc', 'docx'].contains(type)) iconData = Icons.description;

                  return _buildDocumentCard(context, name, type, iconData, url, date);
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: isAcademic
          ? FloatingActionButton(
              onPressed: () => _uploadDocument(context, ref, documentService),
              backgroundColor: const Color(0xFF2979FF),
              child: const Icon(Icons.upload_file, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildDocumentCard(BuildContext context, String name, String? type, IconData icon, String url, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _launchFile(context, url),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: const Color(0xFF00E5FF), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type?.toUpperCase() ?? 'DOSYA',
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.download_rounded, color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Henüz doküman yok',
            style: GoogleFonts.poppins(
              color: Colors.white60,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchFile(BuildContext context, String url) async {
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
  }

  Future<void> _uploadDocument(BuildContext context, WidgetRef ref, DocumentService service) async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null) {
      final file = result.files.first;
      final user = ref.read(authStateChangesProvider).value;

      if (user != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Yükleniyor...', style: GoogleFonts.poppins()),
              backgroundColor: Colors.blue,
            ),
          );
        }

        try {
          await service.uploadDocument(
            classId: classId,
            file: file,
            uploadedBy: user.uid,
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Doküman başarıyla yüklendi!', style: GoogleFonts.poppins()),
                backgroundColor: Colors.green,
              ),
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
  }
}
