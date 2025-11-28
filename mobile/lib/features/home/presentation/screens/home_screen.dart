import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../routes.dart' as app_routes;

import '../widgets/home_empty_state.dart';
import '../widgets/profile_menu_sheet.dart';
import '../widgets/create_class_dialog.dart'; 
import '../widgets/join_class_dialog.dart';
import '../../../authentication/data/auth_service.dart';
import '../../../../shared/utils/snackbar_utils.dart';
import 'class_details_screen.dart';

class HomeScreen extends StatelessWidget {
  final String userRole;
  final AuthService _authService = AuthService(); 

  HomeScreen({super.key, this.userRole = 'student'});

  bool get isTeacher => userRole == 'teacher';

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

    final profileBgColor = primaryColor.withAlpha(255 ~/ 10);
    final profileBorderColor = primaryColor.withAlpha(255 ~/ 2); 
    
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

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _authService.getClassesStream(currentUser.uid, userRole),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Veri çekilirken hata oluştu: ${snapshot.error}'));
          }

          final classes = snapshot.data ?? [];

          if (classes.isEmpty) {
            return const HomeEmptyState();
          }

          return _buildClassesList(context, classes);
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

  Widget _buildClassesList(BuildContext context, List<Map<String, dynamic>> classes) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary; 
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.builder(
        itemCount: classes.length,
        itemBuilder: (context, index) {
          final classData = classes[index];
          final studentCount = classData['studentUids']?.length ?? 0;
          final classCode = classData['code'] ?? 'Yok';
          final className = classData['name'] ?? 'Bilinmeyen Sınıf';
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: InkWell(
              onTap: () {
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
              },
              borderRadius: BorderRadius.circular(12), 
              child: Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: accentColor, 
                        width: 6,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        className,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () {
                              if (classCode != 'Yok') {
                                Clipboard.setData(ClipboardData(text: classCode));
                                SnackbarUtils.showInfo(context, 'Sınıf kodu kopyalandı: $classCode');
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.copy, size: 16, color: theme.colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 8),
                                  Text(
                                    classCode,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace', 
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          Row(
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
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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