import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'chats_providers.dart';
import 'likes_providers.dart';
import 'widgets/discover_bottom_nav.dart';

/// Shell fijo: la bottom bar no se recrea al cambiar de tab.
class MatchingShell extends ConsumerStatefulWidget {
  const MatchingShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MatchingShell> createState() => _MatchingShellState();
}

class _MatchingShellState extends ConsumerState<MatchingShell> {
  static const _tabs = <DiscoverNavTab>[
    DiscoverNavTab.discover,
    DiscoverNavTab.explore,
    DiscoverNavTab.likes,
    DiscoverNavTab.chats,
    DiscoverNavTab.profile,
  ];

  Timer? _likesPoll;

  void _refreshLikes() {
    ref.invalidate(likesSummaryProvider);
    ref.invalidate(receivedLikesProvider);
    ref.invalidate(sentLikesProvider);
  }

  @override
  void initState() {
    super.initState();
    // Sin push FCM aún: refrescar badge + listas de likes periódicamente.
    _likesPoll = Timer.periodic(const Duration(seconds: 12), (_) {
      if (!mounted) return;
      _refreshLikes();
    });
  }

  @override
  void dispose() {
    _likesPoll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mantener Stream escuchando aunque no estés en la pestaña Chats.
    ref.watch(chatsRealtimeInvalidatorProvider);
    final receivedCount =
        ref.watch(likesSummaryProvider).valueOrNull?.receivedCount ?? 0;
    final unreadChats =
        ref.watch(unreadChatsCountProvider).valueOrNull ?? 0;
    final index =
        widget.navigationShell.currentIndex.clamp(0, _tabs.length - 1);

    return ColoredBox(
      color: AppColors.surface,
      child: Column(
        children: [
          Expanded(child: widget.navigationShell),
          DiscoverBottomNav(
            active: _tabs[index],
            likesBadge: receivedCount > 0 ? receivedCount : null,
            chatsBadge: unreadChats > 0 ? unreadChats : null,
            onSelected: (tab) {
              _refreshLikes();
              final target = _tabs.indexOf(tab);
              if (target < 0) return;
              widget.navigationShell.goBranch(
                target,
                initialLocation:
                    target == widget.navigationShell.currentIndex,
              );
            },
          ),
        ],
      ),
    );
  }
}
