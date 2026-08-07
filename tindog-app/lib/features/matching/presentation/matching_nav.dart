import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'widgets/discover_bottom_nav.dart';

/// Navegación entre tabs del shell (o push a rutas fuera del shell).
void handleMatchingBottomNav(BuildContext context, DiscoverNavTab tab) {
  switch (tab) {
    case DiscoverNavTab.discover:
      context.go('/discover');
      return;
    case DiscoverNavTab.explore:
      context.go('/explore');
      return;
    case DiscoverNavTab.likes:
      context.go('/likes');
      return;
    case DiscoverNavTab.chats:
      context.go('/chats');
      return;
    case DiscoverNavTab.profile:
      context.go('/home');
      return;
  }
}
