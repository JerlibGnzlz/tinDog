import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Diálogo breve al crear un match (like back / discover).
Future<bool> showMatchCelebrationDialog(
  BuildContext context, {
  required String petName,
  String? shortLocation,
}) async {
  final goChat = await showDialog<bool>(
    context: context,
    builder: (context) {
      final parkHint = shortLocation != null && shortLocation.isNotEmpty
          ? 'Tip: coordiná un playdate de día en un parque público cerca de $shortLocation.'
          : 'Tip: coordiná un playdate de día en un parque público cerca de ambos.';

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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A $petName también le gustás. ¿Querés empezar a chatear?',
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.park_outlined,
                        size: 18,
                        color: AppColors.primaryDark,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Lugar seguro',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    parkHint,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.35,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pronto te sugeriremos parques cerca de los dos.',
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
