import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/tindog_empty_state.dart';
import '../../chat/presentation/stream_chat_errors.dart';
import '../../chat/presentation/stream_chat_providers.dart';
import '../../chat/presentation/widgets/chat_presence_avatar.dart';
import '../../chat/presentation/widgets/match_profile_sheet.dart';
import '../../chat/presentation/widgets/tindog_chat_list_meta.dart';
import '../../chat/presentation/widgets/tindog_chat_list_subtitle.dart';
import '../../chat/presentation/widgets/tindog_chat_unread_badge.dart';
import '../../safety/presentation/safety_sheets.dart';
import '../data/chat_models.dart';
import 'chats_providers.dart';
import 'delete_conversation.dart';
import 'likes_providers.dart';
import 'widgets/chats_likes_shortcut_card.dart';
import 'widgets/chats_list_skeleton.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Activa listeners Stream (mensajes → refresh de previews).
    ref.watch(chatsRealtimeInvalidatorProvider);
    final streamAsync = ref.watch(streamChatClientProvider);
    final matchesAsync = ref.watch(matchesProvider);
    final removedIds = ref.watch(removedMatchIdsProvider);
    final receivedCount =
        ref.watch(likesSummaryProvider).valueOrNull?.receivedCount ?? 0;
    final receivedLikes =
        ref.watch(receivedLikesProvider).valueOrNull ?? const [];
    final likesPreviewUrl = receivedLikes
        .map((item) => item.photoUrls.isNotEmpty ? item.photoUrls.first : null)
        .whereType<String>()
        .firstOrNull;
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: topInset + AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.xs,
              AppSpacing.md,
              0,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Chats',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => showSafetyInfoSheet(context),
                        icon: const Icon(
                          Icons.shield_outlined,
                          color: AppColors.textSecondary,
                          size: 22,
                        ),
                      ),
                      IconButton(
                        onPressed: () => ref.invalidate(matchesProvider),
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: AppColors.primaryDark,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: matchesAsync.when(
              loading: () => const ChatsListSkeleton(),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        chatErrorMessage(error),
                        style: TextStyle(color: Colors.red.shade700),
                        textAlign: TextAlign.center,
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(matchesProvider),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (threads) {
                final visible = threads
                    .where((t) => !removedIds.contains(t.id))
                    .toList();
                final newMatches =
                    visible.where((t) => !t.hasMessages).toList();
                final conversations =
                    visible.where((t) => t.hasMessages).toList();
                final streamIssue = streamAsync.hasError;

                return RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.card,
                  onRefresh: () async {
                    ref.invalidate(matchesProvider);
                    ref.invalidate(likesSummaryProvider);
                    ref.invalidate(receivedLikesProvider);
                    if (streamIssue) {
                      await ref
                          .read(streamChatClientProvider.notifier)
                          .reconnect();
                    }
                    await ref.read(matchesProvider.future);
                  },
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 12),
                    children: [
                      if (streamIssue)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: Material(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.cloud_off_outlined,
                                    color: AppColors.primaryDark,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      streamConnectionBannerMessage(
                                        streamAsync.error,
                                      ),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => ref
                                        .read(
                                          streamChatClientProvider.notifier,
                                        )
                                        .reconnect(),
                                    child: const Text('Reconectar'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.screenH,
                          AppSpacing.lg,
                          AppSpacing.screenH,
                          AppSpacing.sm,
                        ),
                        child: Text(
                          'Matches nuevos',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          children: [
                            ChatsLikesShortcutCard(
                              count: receivedCount,
                              previewPhotoUrl: likesPreviewUrl,
                              onTap: () => context.go('/likes'),
                            ),
                            ...newMatches.map(
                              (thread) => _NewMatchCard(
                                thread: thread,
                                onTap: () => context.push(
                                  '/chats/${thread.id}',
                                  extra: thread,
                                ),
                                onLongPress: () => confirmAndDeleteConversation(
                                  context: context,
                                  ref: ref,
                                  thread: thread,
                                ),
                              ),
                            ),
                            if (newMatches.isEmpty)
                              const _EmptyNewMatchesHint(),
                          ],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.screenH,
                          AppSpacing.lg,
                          AppSpacing.screenH,
                          AppSpacing.sm,
                        ),
                        child: Text(
                          'Mensajes',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (conversations.isEmpty)
                        TindogEmptyState(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'Todavía no hay mensajes',
                          subtitle:
                              'Cuando escribas a un match, la conversación aparece acá. '
                              'Un “hola” desde un parque público es un gran comienzo.',
                          primaryLabel: 'Ir a Desliza',
                          onPrimary: () => context.go('/discover'),
                          padding: const EdgeInsets.fromLTRB(28, 16, 28, 40),
                        )
                      else
                        ...conversations.map(
                          (thread) => _MessageRow(
                            thread: thread,
                            onTap: () => context.push(
                              '/chats/${thread.id}',
                              extra: thread,
                            ),
                            onAvatarTap: () => showMatchProfileSheet(
                              context: context,
                              pet: thread.otherPet,
                              onDeleteChat: () => confirmAndDeleteConversation(
                                context: context,
                                ref: ref,
                                thread: thread,
                              ),
                            ),
                            onDelete: () => confirmAndDeleteConversation(
                              context: context,
                              ref: ref,
                              thread: thread,
                              optimisticRemove: false,
                            ),
                            onRemoved: () =>
                                markMatchRemovedLocally(ref, thread.id),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NewMatchCard extends StatelessWidget {
  const _NewMatchCard({
    required this.thread,
    required this.onTap,
    this.onLongPress,
  });

  final MatchThread thread;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final photo = thread.otherPet.photoUrls.isNotEmpty
        ? thread.otherPet.photoUrls.first
        : null;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 84,
          child: Column(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textPrimary.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (photo != null)
                          CachedNetworkImage(
                            imageUrl: photo,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            errorWidget: (_, _, _) =>
                                const ColoredBox(color: AppColors.border),
                          )
                        else
                          const ColoredBox(color: AppColors.border),
                        const Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.favorite_rounded,
                              color: AppColors.accent,
                              size: 16,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 6,
                          bottom: 6,
                          child: _NewMatchPresenceDot(
                            streamUserId: thread.otherPet.ownerUserId,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                thread.otherPet.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyNewMatchesHint extends StatelessWidget {
  const _EmptyNewMatchesHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs, right: AppSpacing.md),
      child: SizedBox(
        width: 168,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              color: AppColors.primary.withValues(alpha: 0.75),
              size: 28,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Los matches nuevos aparecen acá. ¡A deslizar!',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NewMatchPresenceDot extends StatelessWidget {
  const _NewMatchPresenceDot({this.streamUserId});

  final String? streamUserId;

  @override
  Widget build(BuildContext context) {
    final state = StreamChat.maybeOf(context)?.client.state;
    final userId = streamUserId;
    if (state == null || userId == null || userId.isEmpty) {
      return const SizedBox.shrink();
    }

    return BetterStreamBuilder<Map<String, User>>(
      stream: state.usersStream,
      initialData: state.users,
      builder: (context, users) {
        final online = users[userId]?.online ?? false;
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: online ? AppColors.primary : AppColors.textSecondary,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.surface, width: 2),
          ),
        );
      },
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.thread,
    required this.onTap,
    required this.onDelete,
    required this.onRemoved,
    this.onAvatarTap,
  });

  final MatchThread thread;
  final VoidCallback onTap;
  final Future<bool> Function() onDelete;
  final VoidCallback onRemoved;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final photo = thread.otherPet.photoUrls.isNotEmpty
        ? thread.otherPet.photoUrls.first
        : null;
    final preview = thread.lastMessage?.previewText ?? '';
    final yourTurn = thread.lastMessage != null && !thread.lastMessage!.fromMe;
    final ownerId = thread.otherPet.ownerUserId;

    return Dismissible(
      key: ValueKey('chat-${thread.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => onDelete(),
      onDismissed: (_) => onRemoved(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade700,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Eliminar match',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TindogChatHasUnread(
              matchId: thread.id,
              builder: (context, hasUnread) {
                return Row(
                  children: [
                    ChatPresenceAvatar(
                      photoUrl: photo,
                      streamUserId: ownerId,
                      radius: 28,
                      onTap: onAvatarTap,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            thread.otherPet.name,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: hasUnread
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          ChatPresenceLabel(streamUserId: ownerId),
                          const SizedBox(height: 2),
                          TindogChatListSubtitle(
                            matchId: thread.id,
                            otherUserId: ownerId,
                            fallbackPreview: preview,
                            emphasize: hasUnread,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TindogChatMutedIcon(matchId: thread.id),
                            TindogChatListTimestamp(
                              matchId: thread.id,
                              fallback: thread.lastMessage?.createdAt ??
                                  thread.matchedAt,
                              emphasize: hasUnread,
                            ),
                          ],
                        ),
                        if (hasUnread) ...[
                          const SizedBox(height: 8),
                          TindogChatUnreadBadge(matchId: thread.id),
                        ] else if (yourTurn) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryDark,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Tu turno',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
