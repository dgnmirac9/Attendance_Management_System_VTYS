import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';

import '../providers/class_list_provider.dart';

import '../../auth/providers/auth_controller.dart';
import '../../auth/services/user_service.dart';
import 'student/join_class_dialog.dart';
import 'class_detail_screen.dart';

import '../widgets/create_class_dialog.dart';
import '../widgets/profile_menu_sheet.dart';
import '../../../core/widgets/empty_state_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final sortedClassesAsync = ref.watch(sortedClassesProvider);
    final userRoleAsync = ref.watch(userRoleProvider); // Watch user role
    final userDataAsync = ref.watch(userDataProvider); // Watch user data
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sınıflarım'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: () {
                final userName = userDataAsync.value?['name'] ?? 'Kullanıcı';
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (context) => ProfileMenuSheet(
                    isTeacher: userRoleAsync.value == 'academician',
                    userName: userName,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryColor.withValues(alpha: 0.5), width: 1),
                ),
                child: Icon(Icons.face, color: primaryColor, size: 24),
              ),
            ),
          ),
        ],
      ),
      body: sortedClassesAsync.when(
        data: (classes) {
          if (classes.isEmpty) {
            final isTeacher = userRoleAsync.value == 'academician';
            return EmptyStateWidget(
              icon: Icons.class_outlined,
              message: isTeacher 
                  ? "Henüz bir sınıf oluşturmadınız." 
                  : "Henüz bir sınıfa kayıtlı değilsiniz.",
            );
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: classes.length,
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (BuildContext context, Widget? child) {
                  final double animValue = Curves.easeInOut.transform(animation.value);
                  final double scale = lerpDouble(1, 1.05, animValue)!;
                  final double angle = lerpDouble(0, -0.05, animValue)!; // Mild left tilt
                  return Transform.rotate(
                    angle: angle,
                    child: Transform.scale(scale: scale, child: child),
                  );
                },
                child: Material(
                  elevation: 8,
                  color: Colors.transparent,
                  shadowColor: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  child: child,
                ),
              );
            },
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex -= 1;
              
              final item = classes.removeAt(oldIndex);
              classes.insert(newIndex, item);
              
              // Update order in Firestore
              final newOrder = classes.map((c) => c.id).toList();
              if (user != null) {
                ref.read(userServiceProvider).updateClassOrder(user.uid, newOrder);
              }
            },
            itemBuilder: (context, index) {
              final doc = classes[index];
              final data = doc.data() as Map<String, dynamic>;
              final className = data['className'] ?? 'İsimsiz Sınıf';
              final teacherName = data['teacherName'] ?? '';
              final joinCode = data['joinCode'] ?? '';
              // Random accent color based on hash or stored field
              final accentColor = Colors.primaries[doc.id.hashCode % Colors.primaries.length];

              return Padding(
                key: ValueKey(doc.id),
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClassDetailScreen(
                            className: className,
                            classId: doc.id,
                            joinCode: joinCode,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: accentColor, width: 6),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                className,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                teacherName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.people, size: 18, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  "${(data['studentIds'] as List?)?.length ?? 0}",
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
          final isTeacher = userRoleAsync.value == 'academician';
          if (isTeacher) {
            showDialog(context: context, builder: (_) => const CreateClassDialog());
          } else {
            showDialog(context: context, builder: (_) => const JoinClassDialog());
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
