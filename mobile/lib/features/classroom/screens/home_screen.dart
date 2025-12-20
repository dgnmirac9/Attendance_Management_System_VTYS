import 'package:flutter/material.dart';
import 'dart:ui'; // For lerpDouble
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/class_list_provider.dart';
import '../providers/classroom_provider.dart'; // ADDED - for userClassesFutureProvider

import '../../auth/providers/auth_controller.dart';

import 'student/join_class_dialog.dart';
import 'class_detail_screen.dart';

import '../widgets/create_class_dialog.dart';
import '../widgets/profile_menu_sheet.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/skeleton_list_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh class list when returning to app/screen
      ref.invalidate(userClassesFutureProvider);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final sortedClassesAsync = ref.watch(sortedClassesProvider);
    final userRole = ref.watch(userRoleProvider); // Direct String?
    final userData = ref.watch(userDataProvider); // Direct Map?
    final currentUser = ref.watch(currentUserProvider); // Direct UserModel?
    final theme = Theme.of(context);


    return Scaffold(
      appBar: AppBar(
        title: const Text('Sınıflarım'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: () {
                final userName = userData?['name'] ?? 'Kullanıcı';
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (context) => ProfileMenuSheet(
                    isTeacher: userRole == 'instructor',
                    userName: userName,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 1),
                ),
                child: Icon(Icons.face, color: theme.colorScheme.primary, size: 24),
              ),
            ),
          ),
        ],
      ),
      body: sortedClassesAsync.when(
        data: (classes) {
          if (classes.isEmpty) {
            final isTeacher = userRole == 'instructor';
            return EmptyStateWidget(
              icon: Icons.class_outlined,
              message: isTeacher 
                  ? "Henüz bir sınıf oluşturmadınız." 
                  : "Henüz bir sınıfa kayıtlı değilsiniz.",
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userClassesFutureProvider);
              // Wait for refresh to complete
              await ref.read(userClassesFutureProvider.future);
            },
            child: ReorderableListView.builder(
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

              if (currentUser != null) {
                // Note: Class order update not yet implemented in backend
                // ref.read(userServiceProvider).updateClassOrder(currentUser.uid, newOrder);
              }
            },
            itemBuilder: (context, index) {
              final classItem = classes[index];
              final className = classItem.className;
              final teacherName = classItem.teacherName;
              final joinCode = classItem.joinCode;
              // Random accent color based on hash or stored field
              final accentColor = Colors.primaries[classItem.id.hashCode % Colors.primaries.length];

              return Padding(
                key: ValueKey(classItem.id),
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Card(
                  margin: EdgeInsets.zero,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ClassDetailScreen(
                            className: className,
                            classId: classItem.id,
                            joinCode: joinCode,
                          ),
                        ),
                      );
                      
                      // If course was deleted, refresh list
                      if (result == true) {
                        ref.invalidate(userClassesFutureProvider);
                      }
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
                                  "${classItem.studentIds.length}",
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
          ),
          ); // Close RefreshIndicator
        },
        loading: () => const SkeletonListWidget(),
        error: (e, s) => Center(child: Text('Hata: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final isTeacher = userRole == 'instructor';
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
