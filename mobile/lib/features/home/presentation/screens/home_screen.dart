import 'package:flutter/material.dart';
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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  bool get isTeacher => widget.userRole == 'teacher';

  bool _isReordering = false;
  late AnimationController _shakeController;
  List<Map<String, dynamic>> _localClasses = [];
  bool _isClassesLoaded = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _startReordering() {
    setState(() {
      _isReordering = true;
    });
    _shakeController.repeat(reverse: true);
  }

  void _stopReordering() {
    setState(() {
      _isReordering = false;
    });
    _shakeController.stop();
    _shakeController.reset();
    _saveOrder();
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
    
    return GestureDetector(
      onTap: () {
        if (_isReordering) {
          _stopReordering();
        }
      },
      child: Scaffold(
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
                if (snapshot.connectionState == ConnectionState.waiting && !_isClassesLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('Veri çekilirken hata oluştu: ${snapshot.error}'));
                }

                final classes = snapshot.data ?? [];

                if (classes.isEmpty) {
                  return const HomeEmptyState();
                }

                // Sınıfları sırala ve yerel listeyi güncelle (sadece reordering modunda değilken)
                if (!_isReordering) {
                  if (classOrder.isNotEmpty) {
                    classes.sort((a, b) {
                      int indexA = classOrder.indexOf(a['code']);
                      int indexB = classOrder.indexOf(b['code']);
                      
                      if (indexA == -1) indexA = 9999;
                      if (indexB == -1) indexB = 9999;
                      
                      return indexA.compareTo(indexB);
                    });
                  }
                  _localClasses = List.from(classes);
                  _isClassesLoaded = true;
                }

                return _buildClassesList(context);
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
      ),
    );
  }

  Widget _buildClassesList(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary; 
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ReorderableListView.builder(
        itemCount: _localClasses.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final item = _localClasses.removeAt(oldIndex);
            _localClasses.insert(newIndex, item);
          });
        },
        itemBuilder: (context, index) {
          final classData = _localClasses[index];
          final studentCount = classData['studentUids']?.length ?? 0;
          final classCode = classData['code'] ?? 'Yok';
          final className = classData['name'] ?? 'Bilinmeyen Sınıf';
          
          return AnimatedBuilder(
            key: ValueKey(classCode),
            animation: _shakeController,
            builder: (context, child) {
              final double angle = _isReordering 
                  ? 0.02 * (index % 2 == 0 ? 1 : -1) * _shakeController.value 
                  : 0;
              return Transform.rotate(
                angle: angle,
                child: child,
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: GestureDetector(
                onLongPress: _isReordering ? null : _startReordering,
                onTap: () {
                  if (_isReordering) {
                    // Reorder modundaysa tıklama bir şey yapmasın
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClassDetailsScreen(
                          className: className,
                          classCode: classCode,
                          teacherUid: classData['teacherUid'] ?? '',
                        ),
                      ),
                    );
                  }
                },
                child: _isReordering
                    ? ReorderableDragStartListener(
                        index: index,
                        child: _buildClassCard(theme, accentColor, className, studentCount),
                      )
                    : _buildClassCard(theme, accentColor, className, studentCount),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClassCard(ThemeData theme, Color accentColor, String className, int studentCount) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
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