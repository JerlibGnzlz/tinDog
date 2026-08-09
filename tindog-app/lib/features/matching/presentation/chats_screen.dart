import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/tindog_loader.dart';
import '../../chat/presentation/stream_chat_errors.dart';
import '../../chat/presentation/stream_chat_providers.dart';
import '../../chat/presentation/widgets/chat_presence_avatar.dart';
import '../../chat/presentation/widgets/match_profile_sheet.dart';
import '../../chat/presentation/widgets/tindog_chat_list_subtitle.dart';
import '../../chat/presentation/widgets/tindog_chat_unread_badge.dart';
import '../../safety/presentation/safety_sheets.dart';
import '../data/chat_models.dart';
import 'chats_providers.dart';
import 'delete_conversation.dart';
import 'likes_providers.dart';
import 'widgets/chats_likes_shortcut_card.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Activa listeners Stream (mensajes → refresh de previews).
    ref.watch(chatsRealtimeInvalidatorProvider);
    final streamAsync = ref.watch(streamChatClientProvider);
    final matchesAsync = ref.watch(matchesProvider);
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
          SizedBox(height: topInset + 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Chats',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
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
              loading: () => const Center(
                child: TindogLoader(message: 'Cargando chats…'),
              ),
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
                final newMatches =
                    threads.where((t) => !t.hasMessages).toList();
                final conversations =
                    threads.where((t) => t.hasMessages).toList();
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
                        padding: EdgeInsets.fromLTRB(20, 16, 20, 10),
                        child: Text(
                          'Matches nuevos',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
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
                        padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                        child: Text(
                          'Mensajes',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (conversations.isEmpty)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(20, 24, 20, 40),
                          child: Text(
                            'Cuando escribas a un match, el chat aparece acá.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
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
                            ),
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
    return const Padding(
      padding: EdgeInsets.only(left: 4, right: 12),
      child: SizedBox(
        width: 160,
        child: Center(
          child: Text(
            'Los matches nuevos aparecen acá',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
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
    this.onAvatarTap,
  });

  final MatchThread thread;
  final VoidCallback onTap;
  final Future<bool> Function() onDelete;
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
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: Colors.red.shade700,
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
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
                    if (hasUnread) ...[
                      TindogChatUnreadBadge(matchId: thread.id),
                    ] else if (yourTurn) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Text(
                          'Tu turno',
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
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
