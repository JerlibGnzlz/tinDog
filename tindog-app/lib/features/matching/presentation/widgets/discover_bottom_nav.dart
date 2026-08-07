import 'package:flutter/material.dart';

enum DiscoverNavTab { discover, explore, likes, chats, profile }

class DiscoverBottomNav extends StatelessWidget {
  const DiscoverBottomNav({
    super.key,
    required this.active,
    required this.onSelected,
    this.likesBadge = 1,
    this.chatsBadge = true,
  });

  final DiscoverNavTab active;
  final ValueChanged<DiscoverNavTab> onSelected;
  final int? likesBadge;
  final bool chatsBadge;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return ColoredBox(
      color: const Color(0xFF111111),
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, 6, 8, bottom > 0 ? bottom : 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              children: [
                _Item(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Desliza',
                  selected: active == DiscoverNavTab.discover,
                  onTap: () => onSelected(DiscoverNavTab.discover),
                ),
                _Item(
                  icon: Icons.explore_outlined,
                  label: 'Explorar',
                  selected: active == DiscoverNavTab.explore,
                  onTap: () => onSelected(DiscoverNavTab.explore),
                ),
                _Item(
                  icon: Icons.favorite_border_rounded,
                  label: 'Likes',
                  selected: active == DiscoverNavTab.likes,
                  badgeCount: likesBadge,
                  onTap: () => onSelected(DiscoverNavTab.likes),
                ),
                _Item(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Chats',
                  selected: active == DiscoverNavTab.chats,
                  showDot: chatsBadge,
                  onTap: () => onSelected(DiscoverNavTab.chats),
                ),
                _Item(
                  icon: Icons.person_outline_rounded,
                  label: 'Perfil',
                  selected: active == DiscoverNavTab.profile,
                  onTap: () => onSelected(DiscoverNavTab.profile),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount,
    this.showDot = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? badgeCount;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : const Color(0xFFB0B0B0);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2C2C2E) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 28,
                height: 24,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Icon(icon, size: 24, color: color),
                    if (badgeCount != null && badgeCount! > 0)
                      Positioned(
                        top: -4,
                        right: -8,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 16),
                          height: 16,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4458),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badgeCount! > 9 ? '9+' : '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    if (showDot)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF4458),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
