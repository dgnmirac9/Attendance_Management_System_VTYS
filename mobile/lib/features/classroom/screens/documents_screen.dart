import 'package:flutter/material.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for documents
    final List<Map<String, dynamic>> documents = [
      {
        'name': 'Hafta 1 - Giriş.pdf',
        'date': '2023-10-02',
        'type': 'pdf',
      },
      {
        'name': 'Hafta 2 - Mimari.pptx',
        'date': '2023-10-09',
        'type': 'ppt', // Using generic file icon or similar for ppt if specific not requested, but user said "Word for blue", let's stick to PDF/Word as requested or general types. User said "PDF for red, Word for blue". I'll add a Word doc too.
      },
      {
        'name': 'Proje Ödevi.docx',
        'date': '2023-11-15',
        'type': 'word',
      },
      {
        'name': 'Hafta 3 - Bellek Yönetimi.pdf',
        'date': '2023-10-16',
        'type': 'pdf',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ders Dokümanları'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: documents.length,
        itemBuilder: (context, index) {
          final doc = documents[index];
          final isPdf = doc['type'] == 'pdf';
          final isWord = doc['type'] == 'word';
          
          IconData iconData = Icons.insert_drive_file;
          Color iconColor = Colors.grey;

          if (isPdf) {
            iconData = Icons.picture_as_pdf;
            iconColor = Colors.red;
          } else if (isWord) {
            iconData = Icons.description;
            iconColor = Colors.blue;
          }

          return Card(
            elevation: 1,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(iconData, color: iconColor, size: 32),
              title: Text(
                doc['name'],
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text('Yüklenme Tarihi: ${doc['date']}'),
              trailing: IconButton(
                icon: const Icon(Icons.download_rounded),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${doc['name']} indiriliyor...')),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
