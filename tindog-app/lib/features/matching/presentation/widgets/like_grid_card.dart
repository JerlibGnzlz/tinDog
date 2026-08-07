import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/discover_candidate.dart';

class LikeGridCard extends StatelessWidget {
  const LikeGridCard({
    super.key,
    required this.item,
    this.onTap,
    this.onLikeBack,
    this.liking = false,
  });

  final LikeListItem item;
  final VoidCallback? onTap;
  /// Like mutuo desde likes recibidos (null = solo lectura, p. ej. enviados).
  final VoidCallback? onLikeBack;
  final bool liking;

  @override
  Widget build(BuildContext context) {
    final title = item.age != null ? '${item.name}, ${item.age}' : item.name;
    final photo = item.photoUrls.isNotEmpty ? item.photoUrls.first : null;
    final canLikeBack = onLikeBack != null && !item.matched;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (photo != null)
                  CachedNetworkImage(
                    imageUrl: photo,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        const ColoredBox(color: AppColors.border),
                    errorWidget: (_, _, _) => const ColoredBox(
                      color: AppColors.border,
                      child: Icon(Icons.pets, color: AppColors.textSecondary),
                    ),
                  )
                else
                  const ColoredBox(color: AppColors.border),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00000000),
                        Color(0xB3222222),
                      ],
                      stops: [0.45, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              canLikeBack
                                  ? 'Tocá ♥ para match'
                                  : item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: liking
                              ? null
                              : (canLikeBack ? onLikeBack : onTap),
                          customBorder: const CircleBorder(),
                          child: Ink(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: canLikeBack
                                  ? AppColors.primary
                                  : AppColors.card.withValues(alpha: 0.92),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: canLikeBack
                                    ? AppColors.primaryDark
                                    : AppColors.border,
                              ),
                              boxShadow: canLikeBack
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primaryDark
                                            .withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: liking
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    item.matched || canLikeBack
                                        ? Icons.favorite_rounded
                                        : Icons.star_rounded,
                                    size: 20,
                                    color: canLikeBack
                                        ? Colors.white
                                        : item.matched
                                            ? AppColors.accent
                                            : AppColors.primaryDark,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
