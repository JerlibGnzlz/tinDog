import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_navigation.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../notifications/presentation/notification_preferences.dart';

Future<void> showHomeSettingsSheet({
  required BuildContext context,
  required WidgetRef ref,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.card,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.88;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Ajustes',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final soundOn = ref.watch(chatMessageSoundProvider);
                    return SwitchListTile(
                      secondary: Icon(
                        soundOn
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_off_outlined,
                        color: AppColors.primaryDark,
                      ),
                      title: const Text(
                        'Sonido de mensajes',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                      subtitle: const Text(
                        'Suena fuera del chat. Los silenciados no avisan.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      value: soundOn,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) {
                        ref
                            .read(chatMessageSoundProvider.notifier)
                            .setEnabled(v);
                      },
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.primaryDark,
                  ),
                  title: const Text(
                    'Editar perfil',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push('/profile');
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.visibility_outlined,
                    color: AppColors.primaryDark,
                  ),
                  title: const Text(
                    'Qué ven los demás',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: const Text(
                    'Transparencia sobre tu perfil público',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push('/visibility');
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.block_rounded,
                    color: Colors.red.shade700,
                  ),
                  title: const Text(
                    'Bloqueados',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: const Text(
                    'Ver y desbloquear personas',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push('/profile/blocked');
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.primaryDark,
                  ),
                  title: const Text(
                    'Ir a Desliza',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.go('/discover');
                  },
                ),
                ListTile(
                  leading:
                      Icon(Icons.logout_rounded, color: Colors.red.shade700),
                  title: Text(
                    'Cerrar sesión',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    // [context] = padre del sheet (sigue montado).
                    await signOutToWelcome(ref, context);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
