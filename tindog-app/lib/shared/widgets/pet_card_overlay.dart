import 'package:flutter/material.dart';

/// Overlay tipo Tinder: mascota arriba; dueño + bio debajo.
class PetCardOverlay extends StatelessWidget {
  const PetCardOverlay({
    super.key,
    required this.name,
    this.age,
    this.subtitle,
    this.bio,
    this.ownerName,
    this.onInfoTap,
    this.nameFontSize = 28,
  });

  final String name;
  final int? age;
  final String? subtitle;
  final String? bio;
  final String? ownerName;
  final VoidCallback? onInfoTap;
  final double nameFontSize;

  String get _title {
    if (age != null) return '$name $age';
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final cleanSubtitle = subtitle?.trim();
    final cleanBio = bio?.trim();
    final cleanOwner = ownerName?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                _title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: nameFontSize,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  shadows: const [
                    Shadow(
                      color: Color(0x66000000),
                      blurRadius: 8,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
            if (onInfoTap != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: onInfoTap,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.25),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ],
        ),
        if (cleanSubtitle != null && cleanSubtitle.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            cleanSubtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (cleanOwner != null && cleanOwner.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Con $cleanOwner',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (cleanBio != null && cleanBio.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            cleanBio,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 14,
              height: 1.3,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }
}
