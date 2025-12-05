import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../auth/providers/auth_controller.dart';
import '../../providers/classroom_provider.dart';
import 'academic_class_detail_screen.dart';
import 'create_class_dialog.dart';

class AcademicHomeScreen extends ConsumerWidget {
  const AcademicHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? 'Akademisyen';
    final classesAsync = ref.watch(userClassesProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Derslerim (Akademisyen)', style: TextStyle(fontSize: 16)),
            Text(
              userEmail,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                "AKADEMİSYEN PANELİ",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ),
          ),
          Expanded(
            child: classesAsync.when(
              data: (snapshot) {
                if (snapshot.docs.isEmpty) {
                  return const Center(child: Text("Henüz ders oluşturmadınız."));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: snapshot.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final className = data['className'] ?? 'İsimsiz Ders';
                    final joinCode = data['joinCode'] ?? '---';
                    final studentCount = (data['studentIds'] as List?)?.length ?? 0;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          className,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("Kod: $joinCode | Öğrenci: $studentCount"),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AcademicClassDetailScreen(
                                className: className,
                                classId: doc.id,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Hata: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const CreateClassDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
