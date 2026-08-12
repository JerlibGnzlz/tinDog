import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Avatar circular grande con lápiz de edición (estilo hub Tinder).
class HomeProfileAvatar extends StatelessWidget {
  const HomeProfileAvatar({
    super.key,
    required this.photoUrl,
    required this.onEdit,
    this.size = 128,
  });

  final String? photoUrl;
  final VoidCallback onEdit;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim();
    final hasPhoto = url != null && url.isNotEmpty;

    return SizedBox(
      width: size + 8,
      height: size + 8,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 4,
            top: 4,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onEdit,
                child: Ink(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.border,
                    border: Border.all(color: AppColors.card, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textPrimary.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: hasPhoto
                        ? CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => const ColoredBox(
                              color: AppColors.border,
                              child: Center(
                                child: Icon(
                                  Icons.pets_rounded,
                                  color: AppColors.textSecondary,
                                  size: 40,
                                ),
                              ),
                            ),
                            errorWidget: (_, _, _) => const ColoredBox(
                              color: AppColors.border,
                              child: Center(
                                child: Icon(
                                  Icons.pets_rounded,
                                  color: AppColors.textSecondary,
                                  size: 40,
                                ),
                              ),
                            ),
                          )
                        : const ColoredBox(
                            color: AppColors.border,
                            child: Center(
                              child: Icon(
                                Icons.pets_rounded,
                                color: AppColors.textSecondary,
                                size: 40,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 8,
            child: Material(
              color: AppColors.card,
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onEdit,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 18,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
