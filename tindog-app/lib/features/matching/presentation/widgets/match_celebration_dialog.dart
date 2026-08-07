import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Diálogo breve al crear un match (like back / discover).
Future<bool> showMatchCelebrationDialog(
  BuildContext context, {
  required String petName,
}) async {
  final goChat = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '¡Es un match!',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'A $petName también le gustás. ¿Querés empezar a chatear?',
          style: const TextStyle(
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Después'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ir al chat'),
          ),
        ],
      );
    },
  );
  return goChat == true;
}
