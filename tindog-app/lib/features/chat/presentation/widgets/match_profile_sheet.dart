import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/swipe_preview_media.dart';
import '../../../../shared/widgets/pet_video_player_screen.dart';
import '../../../matching/data/discover_candidate.dart';

/// Ficha del match desde el chat (avatar / nombre).
Future<void> showMatchProfileSheet({
  required BuildContext context,
  required DiscoverCandidate pet,
  VoidCallback? onSafety,
  VoidCallback? onDeleteChat,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    enableDrag: true,
    showDragHandle: false,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (context) {
      return _MatchProfileSheet(
        pet: pet,
        onSafety: onSafety,
        onDeleteChat: onDeleteChat,
      );
    },
  );
}

class _MatchProfileSheet extends StatefulWidget {
  const _MatchProfileSheet({
    required this.pet,
    this.onSafety,
    this.onDeleteChat,
  });

  final DiscoverCandidate pet;
  final VoidCallback? onSafety;
  final VoidCallback? onDeleteChat;

  @override
  State<_MatchProfileSheet> createState() => _MatchProfileSheetState();
}

class _MatchProfileSheetState extends State<_MatchProfileSheet> {
  late final PageController _pageController;
  var _photoIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    final media = pet.mediaItems;
    final height = MediaQuery.sizeOf(context).height * 0.88;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final title = pet.age != null ? '${pet.name}, ${pet.age}' : pet.name;
    final breed = pet.breed?.trim();
    final bio = pet.bio?.trim();
    final mediaIndex =
        _photoIndex.clamp(0, media.isEmpty ? 0 : media.length - 1);

    return SizedBox(
      height: height,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Perfil',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textSecondary,
                  tooltip: 'Cerrar',
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: media.isEmpty
                        ? const ColoredBox(
                            color: AppColors.border,
                            child: Center(
                              child: Icon(
                                Icons.pets_rounded,
                                size: 64,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              PageView.builder(
                                controller: _pageController,
                                itemCount: media.length,
                                onPageChanged: (i) =>
                                    setState(() => _photoIndex = i),
                                itemBuilder: (context, index) {
                                  final item = media[index];
                                  return GestureDetector(
                                    onTap: item.isVideo
                                        ? () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    PetVideoPlayerScreen(
                                                  url: item.url,
                                                  title: item.durationSec !=
                                                          null
                                                      ? formatMediaDuration(
                                                          item.durationSec!,
                                                        )
                                                      : pet.name,
                                                ),
                                              ),
                                            );
                                          }
                                        : null,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        CachedNetworkImage(
                                          imageUrl: item.thumbnailUrl,
                                          fit: BoxFit.cover,
                                          alignment: Alignment.topCenter,
                                          errorWidget: (_, _, _) =>
                                              const ColoredBox(
                                            color: AppColors.border,
                                            child: Icon(
                                              Icons.broken_image_outlined,
                                            ),
                                          ),
                                        ),
                                        if (item.isVideo)
                                          Center(
                                            child: Container(
                                              padding: const EdgeInsets.all(14),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(
                                                  alpha: 0.4,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.play_arrow_rounded,
                                                color: Colors.white,
                                                size: 40,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              if (media.length > 1)
                                Positioned(
                                  left: 10,
                                  right: 10,
                                  top: 10,
                                  child: Row(
                                    children: [
                                      for (var i = 0; i < media.length; i++)
                                        Expanded(
                                          child: Container(
                                            height: 3,
                                            margin: EdgeInsets.only(
                                              right: i == media.length - 1
                                                  ? 0
                                                  : 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: i == mediaIndex
                                                  ? Colors.white
                                                  : Colors.white
                                                      .withValues(alpha: 0.35),
                                              borderRadius:
                                                  BorderRadius.circular(999),
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
                const SizedBox(height: 18),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                  ),
                ),
                if (breed != null && breed.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    breed,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
                if (pet.locationLabel != null) ...[
                  const SizedBox(height: 10),
                  _MetaRow(
                    icon: Icons.home_outlined,
                    text: pet.locationLabel!,
                  ),
                ],
                if (pet.distanceLabel != null) ...[
                  const SizedBox(height: 6),
                  _MetaRow(
                    icon: Icons.near_me_outlined,
                    text: pet.distanceLabel!,
                  ),
                ],
                if (pet.proximityTip != null) ...[
                  const SizedBox(height: 6),
                  _MetaRow(
                    icon: Icons.pets_rounded,
                    text: pet.proximityTip!,
                  ),
                ],
                if (_hasOwnerSection(pet)) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Dueño/a',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _OwnerCard(
                    name: pet.ownerName?.trim(),
                    avatarUrl: pet.ownerAvatarUrl?.trim(),
                    bio: bio,
                  ),
                ],
                const SizedBox(height: 22),
                if (widget.onSafety != null)
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onSafety!();
                    },
                    icon: const Icon(Icons.shield_outlined),
                    label: const Text('Reportar o bloquear'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                      side: const BorderSide(color: AppColors.border),
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                if (widget.onDeleteChat != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onDeleteChat!();
                    },
                    child: Text(
                      'Eliminar conversación',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasOwnerSection(DiscoverCandidate pet) {
    final name = pet.ownerName?.trim();
    final bio = pet.bio?.trim();
    final avatar = pet.ownerAvatarUrl?.trim();
    return (name != null && name.isNotEmpty) ||
        (bio != null && bio.isNotEmpty) ||
        (avatar != null && avatar.isNotEmpty);
  }
}

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({
    this.name,
    this.avatarUrl,
    this.bio,
  });

  final String? name;
  final String? avatarUrl;
  final String? bio;

  @override
  Widget build(BuildContext context) {
    final hasName = name != null && name!.isNotEmpty;
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;
    final hasBio = bio != null && bio!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary.withValues(alpha: 0.18),
                backgroundImage:
                    hasAvatar ? CachedNetworkImageProvider(avatarUrl!) : null,
                child: hasAvatar
                    ? null
                    : const Icon(
                        Icons.person_rounded,
                        color: AppColors.primaryDark,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasName ? name! : 'Dueño/a de tinDog',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          if (hasBio) ...[
            const SizedBox(height: 12),
            Text(
              bio!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
