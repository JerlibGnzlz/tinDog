import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

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

    return Material(
      color: AppColors.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(10, 4, 10, bottom > 0 ? bottom : 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SizedBox(
            height: 58,
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
    final color = selected ? AppColors.primaryDark : AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.22)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(
                width: 28,
                height: 22,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Icon(icon, size: 22, color: color),
                    if (badgeCount != null && badgeCount! > 0)
                      Positioned(
                        top: -4,
                        right: -8,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 14),
                          height: 14,
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badgeCount! > 9 ? '9+' : '$badgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
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
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  height: 1.0,
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
