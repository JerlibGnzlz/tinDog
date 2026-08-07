import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import 'likes_providers.dart';
import 'widgets/discover_bottom_nav.dart';

/// Shell fijo: la bottom bar no se recrea al cambiar de tab.
class MatchingShell extends ConsumerWidget {
  const MatchingShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = <DiscoverNavTab>[
    DiscoverNavTab.discover,
    DiscoverNavTab.explore,
    DiscoverNavTab.likes,
    DiscoverNavTab.chats,
    DiscoverNavTab.profile,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receivedCount =
        ref.watch(likesSummaryProvider).valueOrNull?.receivedCount ?? 0;
    final index = navigationShell.currentIndex.clamp(0, _tabs.length - 1);

    return ColoredBox(
      color: AppColors.surface,
      child: Column(
        children: [
          Expanded(child: navigationShell),
          DiscoverBottomNav(
            active: _tabs[index],
            likesBadge: receivedCount > 0 ? receivedCount : null,
            chatsBadge: false,
            onSelected: (tab) {
              final target = _tabs.indexOf(tab);
              if (target < 0) return;
              navigationShell.goBranch(
                target,
                initialLocation: target == navigationShell.currentIndex,
              );
            },
          ),
        ],
      ),
    );
  }
}
