import 'package:flutter/material.dart';

class CustomConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;
  final bool isDestructive;
  final bool useFilledButton;

  const CustomConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.confirmText = "Evet",
    this.cancelText = "İptal",
    this.isDestructive = false,
    this.useFilledButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine Confirm Button/Text Color
    final confirmColor = isDestructive ? Colors.red : theme.colorScheme.primary;

    return AlertDialog(
      title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : null)),
      content: Text(message),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      actions: [
        // Cancel Button
        TextButton(
          onPressed: () => Navigator.pop(context, false), // Return false on cancel
          child: Text(
            cancelText,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
        
        // Confirm Button
        if (useFilledButton)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true); // Return true on confirm
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive 
                  ? Colors.red 
                  : theme.colorScheme.primary,
              foregroundColor: isDestructive 
                  ? Colors.white 
                  : theme.colorScheme.onPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(confirmText),
          )
        else
          TextButton(
            onPressed: () {
              Navigator.pop(context, true); // Return true on confirm
              onConfirm();
            },
            child: Text(
              confirmText,
              style: TextStyle(
                color: confirmColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }
}
