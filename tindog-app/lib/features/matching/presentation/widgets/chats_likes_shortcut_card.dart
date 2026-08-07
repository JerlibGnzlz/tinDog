import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Atajo a Likes en la fila de matches nuevos (foto blur del último like).
class ChatsLikesShortcutCard extends StatelessWidget {
  const ChatsLikesShortcutCard({
    super.key,
    required this.count,
    required this.onTap,
    this.previewPhotoUrl,
  });

  final int count;
  final VoidCallback onTap;
  final String? previewPhotoUrl;

  @override
  Widget build(BuildContext context) {
    final label = count > 0 ? '$count Like' : 'Likes';
    final photo = previewPhotoUrl?.trim();
    final hasPhoto = photo != null && photo.isNotEmpty;

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
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.85),
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textPrimary.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11.5),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (hasPhoto)
                          ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: 10,
                              sigmaY: 10,
                            ),
                            child: Transform.scale(
                              scale: 1.08,
                              child: CachedNetworkImage(
                                imageUrl: photo,
                                fit: BoxFit.cover,
                                placeholder: (_, _) =>
                                    const ColoredBox(color: AppColors.border),
                                errorWidget: (_, _, _) =>
                                    const ColoredBox(color: AppColors.border),
                              ),
                            ),
                          )
                        else
                          const ColoredBox(color: AppColors.card),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primary.withValues(
                                  alpha: hasPhoto ? 0.18 : 0.08,
                                ),
                                AppColors.textPrimary.withValues(
                                  alpha: hasPhoto ? 0.45 : 0.04,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Icon(
                              Icons.favorite_rounded,
                              color: hasPhoto ? Colors.white : AppColors.accent,
                              size: 26,
                              shadows: hasPhoto
                                  ? const [
                                      Shadow(
                                        color: Color(0x66000000),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
