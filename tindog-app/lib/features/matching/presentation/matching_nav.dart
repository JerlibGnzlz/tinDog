import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/feedback/app_feedback.dart';
import 'widgets/discover_bottom_nav.dart';

void handleMatchingBottomNav(BuildContext context, DiscoverNavTab tab) {
  switch (tab) {
    case DiscoverNavTab.discover:
      context.go('/discover');
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
    case DiscoverNavTab.explore:
      showTindogInfoSnackBar(context, 'Próximamente en tinDog');
  }
}
