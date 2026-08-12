import 'package:cached_network_image/cached_network_image.dart';
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
    this.ownerAvatarUrl,
    this.ownerGoogleLinked = false,
    this.onInfoTap,
    this.onOwnerTap,
    this.onBioMoreTap,
    this.nameFontSize = 28,
  });

  final String name;
  final int? age;
  final String? subtitle;
  final String? bio;
  final String? ownerName;
  final String? ownerAvatarUrl;
  final bool ownerGoogleLinked;
  final VoidCallback? onInfoTap;
  final VoidCallback? onOwnerTap;
  /// Abre la ficha completa (bio truncada en la card).
  final VoidCallback? onBioMoreTap;
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
    final avatarUrl = ownerAvatarUrl?.trim();
    final hasOwner = cleanOwner != null && cleanOwner.isNotEmpty;

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
        if (hasOwner) ...[
          const SizedBox(height: 8),
          _OwnerChip(
            name: cleanOwner,
            avatarUrl: avatarUrl,
            googleLinked: ownerGoogleLinked,
            onTap: onOwnerTap,
          ),
        ],
        if (cleanBio != null && cleanBio.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            cleanBio,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 14,
              height: 1.3,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (onBioMoreTap != null) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: onBioMoreTap,
              behavior: HitTestBehavior.opaque,
              child: Text(
                'Ver más',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _OwnerChip extends StatelessWidget {
  const _OwnerChip({
    required this.name,
    this.avatarUrl,
    this.googleLinked = false,
    this.onTap,
  });

  final String name;
  final String? avatarUrl;
  final bool googleLinked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;
    final chip = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.85),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: hasAvatar
              ? CachedNetworkImage(
                  imageUrl: avatarUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const ColoredBox(
                    color: Color(0x55FFFFFF),
                    child: Icon(Icons.person, size: 14, color: Colors.white),
                  ),
                  errorWidget: (_, _, _) => const ColoredBox(
                    color: Color(0x55FFFFFF),
                    child: Icon(Icons.person, size: 14, color: Colors.white),
                  ),
                )
              : const ColoredBox(
                  color: Color(0x55FFFFFF),
                  child: Icon(Icons.person, size: 14, color: Colors.white),
                ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'Con $name',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              shadows: const [
                Shadow(
                  color: Color(0x66000000),
                  blurRadius: 6,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
        if (googleLinked) ...[
          const SizedBox(width: 6),
          Icon(
            Icons.verified_rounded,
            size: 16,
            color: const Color(0xFF7CFFB2),
            shadows: const [
              Shadow(
                color: Color(0x66000000),
                blurRadius: 4,
              ),
            ],
          ),
        ],
      ],
    );

    if (onTap == null) return chip;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          child: chip,
        ),
      ),
    );
  }
}
