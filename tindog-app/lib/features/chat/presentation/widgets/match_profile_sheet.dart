import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
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
    final photos = pet.photoUrls;
    final height = MediaQuery.sizeOf(context).height * 0.88;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final title = pet.age != null ? '${pet.name}, ${pet.age}' : pet.name;
    final breed = pet.breed?.trim();
    final bio = pet.bio?.trim();

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
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: photos.isEmpty
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
                                itemCount: photos.length,
                                onPageChanged: (i) =>
                                    setState(() => _photoIndex = i),
                                itemBuilder: (context, index) {
                                  return CachedNetworkImage(
                                    imageUrl: photos[index],
                                    fit: BoxFit.cover,
                                    errorWidget: (_, _, _) => const ColoredBox(
                                      color: AppColors.border,
                                      child: Icon(Icons.broken_image_outlined),
                                    ),
                                  );
                                },
                              ),
                              if (photos.length > 1)
                                Positioned(
                                  left: 10,
                                  right: 10,
                                  top: 10,
                                  child: Row(
                                    children: [
                                      for (var i = 0; i < photos.length; i++)
                                        Expanded(
                                          child: Container(
                                            height: 3,
                                            margin: EdgeInsets.only(
                                              right: i == photos.length - 1
                                                  ? 0
                                                  : 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: i == _photoIndex
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
                    icon: Icons.location_on_outlined,
                    text: pet.distanceLabel!,
                  ),
                ],
                if (bio != null && bio.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Sobre nosotros',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    bio,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.4,
                      fontSize: 14,
                    ),
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
