import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/tindog_loader.dart';
import '../../chat/presentation/widgets/chat_presence_avatar.dart';
import '../data/chat_models.dart';
import 'chats_providers.dart';
import 'likes_providers.dart';
import 'matching_nav.dart';
import 'widgets/discover_bottom_nav.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesProvider);
    final receivedCount =
        ref.watch(likesSummaryProvider).valueOrNull?.receivedCount ?? 0;
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
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
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => showTindogInfoSnackBar(
                          context,
                          'Seguridad — próximamente',
                        ),
                        icon: const Icon(Icons.shield_outlined,
                            color: Colors.white70, size: 22),
                      ),
                      IconButton(
                        onPressed: () => ref.invalidate(matchesProvider),
                        icon: const Icon(Icons.refresh_rounded,
                            color: Colors.white70, size: 22),
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
                child: TindogLoader(message: 'Cargando chats…', inverted: true),
              ),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        chatErrorMessage(error),
                        style: TextStyle(color: Colors.red.shade300),
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

                return RefreshIndicator(
                  color: Colors.white,
                  backgroundColor: const Color(0xFF2A2A2A),
                  onRefresh: () async {
                    ref.invalidate(matchesProvider);
                    await ref.read(matchesProvider.future);
                  },
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 12),
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 16, 20, 10),
                        child: Text(
                          'Matches nuevos',
                          style: TextStyle(
                            color: Colors.white,
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
                            _LikesShortcutCard(
                              count: receivedCount,
                              onTap: () => context.go('/likes'),
                            ),
                            ...newMatches.map(
                              (thread) => _NewMatchCard(
                                thread: thread,
                                onTap: () => context.push(
                                  '/chats/${thread.id}',
                                  extra: thread,
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
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (conversations.isEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                          child: Text(
                            'Cuando escribas a un match, el chat aparece acá.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
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
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          DiscoverBottomNav(
            active: DiscoverNavTab.chats,
            likesBadge: receivedCount > 0 ? receivedCount : null,
            chatsBadge: (matchesAsync.valueOrNull ?? const [])
                .any((t) => !t.hasMessages),
            onSelected: (tab) => handleMatchingBottomNav(context, tab),
          ),
        ],
      ),
    );
  }
}

class _LikesShortcutCard extends StatelessWidget {
  const _LikesShortcutCard({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white, width: 2),
            color: const Color(0xFF2A2A2A),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(Icons.favorite_rounded, color: Colors.white, size: 28),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  count > 0 ? '$count Like' : 'Likes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewMatchCard extends StatelessWidget {
  const _NewMatchCard({required this.thread, required this.onTap});

  final MatchThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final photo = thread.otherPet.photoUrls.isNotEmpty
        ? thread.otherPet.photoUrls.first
        : null;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 84,
          child: Column(
            children: [
              Expanded(
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
                              const ColoredBox(color: Color(0xFF2A2A2A)),
                        )
                      else
                        const ColoredBox(color: Color(0xFF2A2A2A)),
                      const Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.favorite_rounded,
                            color: AppColors.primary,
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
              const SizedBox(height: 6),
              Text(
                thread.otherPet.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
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
      padding: const EdgeInsets.only(left: 4, right: 12),
      child: SizedBox(
        width: 160,
        child: Center(
          child: Text(
            'Los matches nuevos aparecen acá',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
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
            color: online ? AppColors.primary : const Color(0xFF6B6B6B),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF111111), width: 2),
          ),
        );
      },
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({required this.thread, required this.onTap});

  final MatchThread thread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final photo = thread.otherPet.photoUrls.isNotEmpty
        ? thread.otherPet.photoUrls.first
        : null;
    final preview = thread.lastMessage?.previewText ?? '';
    final yourTurn = thread.lastMessage != null && !thread.lastMessage!.fromMe;
    final ownerId = thread.otherPet.ownerUserId;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            ChatPresenceAvatar(
              photoUrl: photo,
              streamUserId: ownerId,
              radius: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    thread.otherPet.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  ChatPresenceLabel(streamUserId: ownerId),
                  const SizedBox(height: 2),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (yourTurn)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Tu turno',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
