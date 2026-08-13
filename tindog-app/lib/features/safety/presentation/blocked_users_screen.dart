import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/network/session_handler.dart';
import '../../../core/router/tindog_nav.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/tindog_back_button.dart';
import '../../../shared/widgets/tindog_loader.dart';
import '../data/safety_repository.dart';

final blockedUsersProvider =
    FutureProvider.autoDispose<List<BlockedUser>>((ref) {
  return ref.watch(safetyRepositoryProvider).listBlockedUsers();
});

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  Future<void> _unblock(
    BuildContext context,
    WidgetRef ref,
    BlockedUser user,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text(
          '¿Desbloquear?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Vas a desbloquear a ${user.displayName}. Podrán volver a '
          'aparecer en Desliza; el match anterior no se restaura.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desbloquear'),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    try {
      await ref.read(safetyRepositoryProvider).unblockUser(user.userId);
      ref.invalidate(blockedUsersProvider);
      if (!context.mounted) return;
      showTindogSuccessSnackBar(context, '${user.displayName} desbloqueado');
    } catch (e) {
      if (!context.mounted) return;
      if (isUnauthorizedError(e)) {
        handleSessionExpired(ref, context, e);
        return;
      }
      showTindogErrorSnackBar(context, readableError(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(blockedUsersProvider);
    final canPop = context.canPop();

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        tindogPopOrHome(context);
      },
      child: Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Bloqueados'),
        leading: TindogBackButton(onPressed: () => tindogPopOrHome(context)),
      ),
      body: async.when(
        loading: () => const Center(child: TindogLoader(message: 'Cargando…')),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  readableError(e),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade700),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => ref.invalidate(blockedUsersProvider),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (users) {
          if (users.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No tenés nadie bloqueado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: users.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = users[index];
              final photo = user.photoUrl?.trim();
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  backgroundImage: photo != null && photo.isNotEmpty
                      ? CachedNetworkImageProvider(photo)
                      : null,
                  child: photo == null || photo.isEmpty
                      ? const Icon(Icons.person, color: AppColors.primaryDark)
                      : null,
                ),
                title: Text(
                  user.displayName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text(
                  'Bloqueado',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                trailing: TextButton(
                  onPressed: () => _unblock(context, ref, user),
                  child: const Text('Desbloquear'),
                ),
              );
            },
          );
        },
      ),
      ),
    );
  }
}
