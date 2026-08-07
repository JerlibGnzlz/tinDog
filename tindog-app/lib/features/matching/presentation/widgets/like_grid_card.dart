import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../data/discover_candidate.dart';

class LikeGridCard extends StatelessWidget {
  const LikeGridCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final LikeListItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title = item.age != null ? '${item.name}, ${item.age}' : item.name;
    final photo = item.photoUrls.isNotEmpty ? item.photoUrls.first : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
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
                        const ColoredBox(color: Color(0xFF222222)),
                    errorWidget: (_, _, _) => const ColoredBox(
                      color: Color(0xFF222222),
                      child: Icon(Icons.pets, color: Colors.white38),
                    ),
                  )
                else
                  const ColoredBox(color: Color(0xFF222222)),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00000000),
                        Color(0x99000000),
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
                              item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.matched
                              ? Icons.favorite_rounded
                              : Icons.star_rounded,
                          size: 18,
                          color: item.matched
                              ? const Color(0xFFFF4458)
                              : const Color(0xFF4DB5FF),
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
