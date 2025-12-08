import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui'; // IMPORANT for ProxyDecorator
import '../../../auth/providers/auth_controller.dart';
import '../../providers/classroom_provider.dart';
import '../../../auth/services/user_service.dart'; // For classOrder update
import 'join_class_dialog.dart';
import 'student_class_detail_screen.dart';
import '../../models/class_model.dart';

class StudentHomeScreen extends ConsumerStatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  ConsumerState<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends ConsumerState<StudentHomeScreen> {
  // Local state for optimistic updates
  List<ClassModel>? _localClasses;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email ?? 'Öğrenci';
    final classesAsync = ref.watch(userClassesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Derslerim (Öğrenci)', style: TextStyle(fontSize: 16)),
            Text(
              userEmail,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: classesAsync.when(
        data: (classes) {
          // Initialize local state once
          if (_localClasses == null || _localClasses!.length != classes.length) {
             // Basic check to sync. In production, might need more robust sync or separate provider for order.
             // For now we trust the stream order initially.
             _localClasses = List.from(classes);
          }

          if (_localClasses!.isEmpty) {
            return const Center(child: Text("Henüz bir derse katılmadınız."));
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: _localClasses!.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final item = _localClasses!.removeAt(oldIndex);
                _localClasses!.insert(newIndex, item);
              });
              
              // Persist order
              final newOrderIds = _localClasses!.map((c) => c.id).toList();
              if (user != null) {
                UserService().updateClassOrder(user.uid, newOrderIds);
              }
            },
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (BuildContext context, Widget? child) {
                  final double animValue = Curves.easeInOut.transform(animation.value);
                  final double elevation = lerpDouble(1, 10, animValue)!;
                  final double scale = lerpDouble(1, 1.05, animValue)!;
                  return Transform.scale(
                    scale: scale,
                    child: Card(
                      elevation: elevation,
                      color: Theme.of(context).cardColor.withValues(alpha: 0.9), // Visual feedback
                      child: child,
                    ),
                  );
                },
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final classItem = _localClasses![index];
              final className = classItem.className;
              final teacherName = classItem.teacherName; // Removed fallback 'Bilinmiyor'; logic inside model handles fallback if needed, but model usually nullable/non-nullable

              // Key is mandatory for ReorderableListView
              return Card(
                key: ValueKey(classItem.id), 
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    className,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Hoca: $teacherName"),
                  trailing: const Icon(Icons.drag_handle, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentClassDetailScreen(
                          className: className,
                          classId: classItem.id,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const JoinClassDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
