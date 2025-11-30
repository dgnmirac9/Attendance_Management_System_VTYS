import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../routes.dart' as app_routes;

import '../widgets/home_empty_state.dart';
import '../widgets/profile_menu_sheet.dart';
import '../widgets/create_class_dialog.dart'; 
import '../widgets/join_class_dialog.dart';
import '../../../authentication/data/auth_service.dart';
import 'class_details_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userRole;

  const HomeScreen({super.key, this.userRole = 'student'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  bool get isTeacher => widget.userRole == 'teacher';

  List<Map<String, dynamic>> _localClasses = [];
  bool _isClassesLoaded = false;
  DateTime? _lastReorderTime;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _saveOrder() async {
    if (_localClasses.isEmpty) return;
    try {
      List<String> newOrder = _localClasses.map((c) => c['code'] as String).toList();
      await _authService.updateClassOrder(newOrder);
    } catch (e) {
      debugPrint("Sıralama kaydedilemedi: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          app_routes.Routes.login, (Route<dynamic> route) => false);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profileBgColor = primaryColor.withValues(alpha: 0.1);
    final profileBorderColor = primaryColor.withValues(alpha: 0.5); 
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sınıflarım'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: () => _showProfileMenu(context),
              borderRadius: BorderRadius.circular(50), 
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: profileBgColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: profileBorderColor, width: 1),
                ),
                child: Icon(Icons.face, color: primaryColor, size: 24),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _authService.getUserStream(currentUser.uid),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting && !_isClassesLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          List<dynamic> classOrder = [];
          if (userSnapshot.hasData && userSnapshot.data!.exists) {
            classOrder = userSnapshot.data!.data()?['classOrder'] ?? [];
          }

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _authService.getClassesStream(currentUser.uid, widget.userRole),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Veri çekilirken hata oluştu: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting && !_isClassesLoaded) {
                return const Center(child: CircularProgressIndicator());
              }

              final classes = snapshot.data;

              if (classes != null) {
                // 1. Sunucu tarafındaki sıralamayı uygula (Eğer varsa)
                if (classOrder.isNotEmpty) {
                  classes.sort((a, b) {
                    int indexA = classOrder.indexOf(a['code']);
                    int indexB = classOrder.indexOf(b['code']);
                    
                    if (indexA == -1) indexA = 9999;
                    if (indexB == -1) indexB = 9999;
                    return indexA.compareTo(indexB);
                  });
                }

                // 2. Akıllı Senkronizasyon Mantığı
                bool structureChanged = false;
                
                // A. Yapısal Değişiklik Kontrolü (Ekleme/Silme)
                if (!_isClassesLoaded || _localClasses.length != classes.length) {
                  structureChanged = true;
                } else {
                  final localIds = _localClasses.map((c) => c['code']).toSet();
                  final newIds = classes.map((c) => c['code']).toSet();
                  if (localIds.length != newIds.length || !localIds.containsAll(newIds)) {
                    structureChanged = true;
                  }
                }

                if (structureChanged) {
                  // Yapı değiştiyse (yeni sınıf geldi/gitti), her şeyi güncelle
                  _localClasses = List.from(classes);
                  _isClassesLoaded = true;
                  Future.microtask(() {
                    if (mounted) setState(() {});
                  });
                } else {
                  // B. Veri ve Sıralama Kontrolü
                  bool dataChanged = false;
                  bool orderChanged = false;

                  // Sıralama değişmiş mi?
                  for (int i = 0; i < classes.length; i++) {
                    if (_localClasses[i]['code'] != classes[i]['code']) {
                      orderChanged = true;
                      break;
                    }
                  }

                  // Verileri yerinde güncelle (Sıralamayı bozmadan)
                  for (var newClass in classes) {
                    final index = _localClasses.indexWhere((c) => c['code'] == newClass['code']);
                    if (index != -1) {
                      final oldClass = _localClasses[index];
                      if (oldClass['name'] != newClass['name'] || 
                          oldClass['studentCount'] != newClass['studentCount'] ||
                          oldClass['accentColor'] != newClass['accentColor']) {
                        _localClasses[index] = newClass; // Veriyi güncelle, sırayı koru
                        dataChanged = true;
                      }
                    }
                  }

                  // Sıralama güncelleme kararı
                  if (orderChanged) {
                    final now = DateTime.now();
                    // Eğer son 3 saniye içinde yerel sıralama yaptıysak, sunucudan gelen eski sırayı yoksay
                    bool recentlyReordered = _lastReorderTime != null && 
                        now.difference(_lastReorderTime!).inSeconds < 3;
                    
                    if (!recentlyReordered) {
                      _localClasses = List.from(classes);
                      dataChanged = true; // Yeniden çizim tetikle
                    }
                  }

                  if (dataChanged) {
                    Future.microtask(() {
                      if (mounted) setState(() {});
                    });
                  }
                }
              }

              if (_localClasses.isEmpty) {
                return const HomeEmptyState();
              }

              return ReorderableListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _localClasses.length,
                proxyDecorator: (child, index, animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (BuildContext context, Widget? child) {
                      final double animValue = Curves.easeInOut.transform(animation.value);
                      final double scale = lerpDouble(1, 1.05, animValue)!;
                      final double angle = lerpDouble(0, -0.05, animValue)!; 
                      
                      return Transform.rotate(
                        angle: angle,
                        child: Transform.scale(
                          scale: scale,
                          child: Material(
                            elevation: 8,
                            color: Colors.transparent,
                            shadowColor: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: child,
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) {
                      newIndex -= 1;
                    }
                    final item = _localClasses.removeAt(oldIndex);
                    _localClasses.insert(newIndex, item);
                    _lastReorderTime = DateTime.now();
                    _saveOrder();
                  });
                },
                itemBuilder: (context, index) {
                  final classData = _localClasses[index];
                  final accentColor = Color(classData['accentColor'] ?? primaryColor.toARGB32());
                  return Padding(
                    key: ValueKey(classData['code']),
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _buildClassCard(
                      theme,
                      accentColor,
                      classData['name'] ?? 'İsimsiz Sınıf',
                      classData['studentCount'] ?? 0,
                      classData['code'] ?? '',
                      classData['teacherUid'] ?? '',
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (isTeacher) {
            _showCreateClassDialog(context);
          } else {
            _showJoinClassDialog(context);
          }
        },
        backgroundColor: primaryColor,
        foregroundColor: theme.colorScheme.surface,
        elevation: 4,
        shape: const CircleBorder(), 
        child: Icon(isTeacher ? Icons.add : Icons.group_add, size: 28),
      ),
    );
  }

  Widget _buildClassCard(
    ThemeData theme, 
    Color accentColor, 
    String className, 
    int studentCount,
    String classCode,
    String teacherUid,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClassDetailsScreen(
                className: className,
                classCode: classCode,
                teacherUid: teacherUid,
              ),
            ),
          );
        },
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: accentColor,
                width: 6,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  className,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people, size: 20, color: theme.colorScheme.secondary),
                    const SizedBox(width: 6),
                    Text(
                      '$studentCount',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => ProfileMenuSheet(isTeacher: isTeacher),
    );
  }

  void _showCreateClassDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateClassDialog(),
    );
  }

  void _showJoinClassDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const JoinClassDialog(),
    );
  }
}