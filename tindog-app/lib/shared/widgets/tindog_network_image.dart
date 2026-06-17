import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';

class TindogNetworkImage extends StatelessWidget {
  const TindogNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius = 20,
    this.fit = BoxFit.cover,
  });

  final String? imageUrl;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: const Icon(Icons.pets, size: 48, color: AppColors.textSecondary),
    );

    if (imageUrl == null || imageUrl!.isEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: placeholder,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: fit,
          alignment: Alignment.center,
          placeholder: (_, _) => Shimmer.fromColors(
            baseColor: AppColors.border,
            highlightColor: Colors.white,
            child: Container(color: AppColors.border),
          ),
          errorWidget: (_, _, _) => placeholder,
        ),
      ),
    );
  }
}
