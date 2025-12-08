import 'package:flutter/material.dart';

import '../../auth/models/user_model.dart';
class StudentDetailDialog extends StatelessWidget {
  final UserModel studentData;

  const StudentDetailDialog({super.key, required this.studentData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    // Fallback logic if firstName/lastName are missing (old users)
    final rawName = studentData.name;
    final nameParts = rawName.split(' ');
    
    final firstName = studentData.firstName ?? (nameParts.isNotEmpty ? nameParts.first : 'İsimsiz');
    final lastName = studentData.lastName ?? (nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '');
    final email = studentData.email;
    final studentNo = studentData.studentNo ?? 'Numara Yok';
    final fullName = "$firstName $lastName";

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Name
              Text(
                fullName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              // Student No Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  studentNo,
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Details List
              _buildDetailRow(Icons.email, "E-posta", email),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.badge, "Öğrenci No", studentNo),
              
              const SizedBox(height: 32),
              
              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Kapat"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
