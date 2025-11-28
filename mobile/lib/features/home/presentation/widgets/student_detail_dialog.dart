import 'package:flutter/material.dart';

class StudentDetailDialog extends StatelessWidget {
  final Map<String, dynamic> studentData;

  const StudentDetailDialog({super.key, required this.studentData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final firstName = studentData['firstName'] ?? 'İsimsiz';
    final lastName = studentData['lastName'] ?? '';
    final email = studentData['email'] ?? 'E-posta yok';
    final studentNo = studentData['studentNo'] ?? 'Numara Yok';
    final fullName = "$firstName $lastName";

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
            
            // İsim Soyisim
            Text(
              fullName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Öğrenci Numarası Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Text(
                studentNo,
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Detaylar Listesi
            _buildDetailRow(Icons.email, "E-posta", email),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.badge, "Öğrenci No", studentNo),
            
            const SizedBox(height: 32),
            
            // Kapat Butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
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
