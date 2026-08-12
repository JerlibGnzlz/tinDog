import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/network/session_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../data/chat_models.dart';
import '../data/matching_repository.dart';
import 'chats_providers.dart';
import 'likes_providers.dart';

/// Confirma y elimina match (unmatch). No bloquea.
///
/// [optimisticRemove]: si es true (default), saca el hilo de la lista al
/// instante. Con [Dismissible], pasar false y marcar el id en [onDismissed].
Future<bool> confirmAndDeleteConversation({
  required BuildContext context,
  required WidgetRef ref,
  required MatchThread thread,
  bool optimisticRemove = true,
}) async {
  final name = thread.otherPet.name;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('¿Eliminar conversación?'),
        content: Text(
          'Se elimina el match con $name y el chat. '
          'No es un bloqueo: pueden volver a verse en Desliza.',
          style: const TextStyle(color: AppColors.textSecondary, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      );
    },
  );
  if (ok != true || !context.mounted) return false;

  try {
    await ref.read(matchingRepositoryProvider).deleteMatch(thread.id);
    if (optimisticRemove) {
      markMatchRemovedLocally(ref, thread.id);
    }
    ref.invalidate(matchesProvider);
    ref.invalidate(receivedLikesProvider);
    ref.invalidate(sentLikesProvider);
    ref.invalidate(likesSummaryProvider);
    unawaited(_pruneRemovedMatchIds(ref));
    if (context.mounted) {
      showTindogInfoSnackBar(context, 'Conversación con $name eliminada');
    }
    return true;
  } catch (e) {
    if (!context.mounted) return false;
    if (isSessionError(e)) {
      handleSessionExpired(ref, context, e);
      return false;
    }
    showTindogErrorSnackBar(context, readableError(e));
    return false;
  }
}

void markMatchRemovedLocally(WidgetRef ref, String matchId) {
  ref.read(removedMatchIdsProvider.notifier).update(
        (ids) => {...ids, matchId},
      );
}

Future<void> _pruneRemovedMatchIds(WidgetRef ref) async {
  try {
    final threads = await ref.read(matchesProvider.future);
    final alive = threads.map((t) => t.id).toSet();
    ref.read(removedMatchIdsProvider.notifier).update(
          (ids) => ids.intersection(alive),
        );
  } catch (_) {
    // Ignore: la UI ya filtró el id; el próximo refresh limpia.
  }
}
