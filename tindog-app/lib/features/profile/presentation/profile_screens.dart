import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_navigation.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/network/session_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/swipe_preview_media.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/pet_photo_thumbnail_strip.dart';
import '../../../shared/widgets/swipe_preview_actions.dart';
import '../../../shared/widgets/swipe_preview_card.dart';
import '../../../shared/widgets/tindog_filled_button.dart';
import '../../../shared/widgets/tindog_gradient_progress_bar.dart';
import '../../../shared/widgets/tindog_loader.dart';
import '../../pets/data/pet_model.dart';
import '../data/profile_model.dart';
import 'profile_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final petAsync = ref.watch(myPetProvider);
    final photosAsync = ref.watch(myPetPhotosProvider);
    final videosAsync = ref.watch(myPetVideosProvider);

    ref.listen(myPetProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          if (isSessionError(error)) {
            handleSessionExpired(ref, context, error);
          }
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('tinDog'),
        actions: [
          IconButton(
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar perfil',
          ),
          IconButton(
            onPressed: () => signOutToWelcome(ref, context),
            icon: const Icon(Icons.logout),
            tooltip: 'Salir',
          ),
        ],
      ),
      body: petAsync.when(
        loading: () => const Center(child: TindogLoader(message: 'Cargando…')),
        error: (error, _) => _HomeBody(
          onEdit: () => context.go('/profile'),
          errorMessage: readableError(error),
        ),
        data: (pet) => photosAsync.when(
          loading: () => const Center(child: TindogLoader(message: 'Cargando…')),
          error: (_, _) => _HomeBody(
            pet: pet,
            profile: profileAsync.valueOrNull,
            petName: pet.name,
            mediaItems: buildSwipePreviewMedia(
              photos: const [],
              videos: const [],
              fallbackPhotoUrl: pet.photoUrl,
            ),
            onEdit: () => context.go('/profile'),
          ),
          data: (photos) => videosAsync.when(
            loading: () => _HomeBody(
              pet: pet,
              profile: profileAsync.valueOrNull,
              petName: pet.name,
              mediaItems: buildSwipePreviewMedia(
                photos: photos,
                videos: const [],
                fallbackPhotoUrl: pet.photoUrl,
              ),
              onEdit: () => context.go('/profile'),
            ),
            error: (_, _) => _HomeBody(
              pet: pet,
              profile: profileAsync.valueOrNull,
              petName: pet.name,
              mediaItems: buildSwipePreviewMedia(
                photos: photos,
                videos: const [],
                fallbackPhotoUrl: pet.photoUrl,
              ),
              onEdit: () => context.go('/profile'),
            ),
            data: (videos) => _HomeBody(
              pet: pet,
              profile: profileAsync.valueOrNull,
              petName: pet.name,
              mediaItems: buildSwipePreviewMedia(
                photos: photos,
                videos: videos,
                fallbackPhotoUrl: pet.photoUrl,
              ),
              onEdit: () => context.go('/profile'),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeBody extends StatefulWidget {
  const _HomeBody({
    required this.onEdit,
    this.pet,
    this.profile,
    this.petName,
    this.mediaItems = const [],
    this.errorMessage,
  });

  final VoidCallback onEdit;
  final PetModel? pet;
  final ProfileModel? profile;
  final String? petName;
  final List<SwipePreviewMediaItem> mediaItems;
  final String? errorMessage;

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  final _previewController = SwipePreviewCardController();
  int _mediaIndex = 0;

  int get _safeMediaIndex {
    if (widget.mediaItems.isEmpty) return 0;
    return _mediaIndex.clamp(0, widget.mediaItems.length - 1);
  }

  @override
  void didUpdateWidget(_HomeBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mediaItems.length != oldWidget.mediaItems.length) {
      final lastIndex =
          widget.mediaItems.isEmpty ? 0 : widget.mediaItems.length - 1;
      if (_mediaIndex > lastIndex) {
        setState(() => _mediaIndex = lastIndex);
      }
    }
  }

  void _onPreviewDecision(SwipePreviewDecision decision) {
    showTindogInfoSnackBar(
      context,
      decision == SwipePreviewDecision.like
          ? 'Vista previa: así se verá un LIKE'
          : 'Vista previa: así se verá un PASS',
    );
  }

  double _cardHeight(BuildContext context) {
    final media = MediaQuery.of(context);
    final bodyHeight = media.size.height -
        media.padding.top -
        media.padding.bottom -
        kToolbarHeight;
    const bottomCta = 56.0 + 36.0;
    const textBlock = 88.0;
    const verticalPadding = 16.0;
    const cardExtra = 12.0;
    const thumbsBlock = 68.0 + 12.0;
    const actionsBlock = 54.0 + 12.0;
    const bannerBlock = 78.0 + 12.0;

    final hasMedia = widget.mediaItems.isNotEmpty;
    final hasThumbs = hasMedia && widget.mediaItems.length > 1;
    final showCompletionBanner = widget.profile != null &&
        widget.pet != null &&
        profileCoreCompletionPercent(
              profile: widget.profile!,
              pet: widget.pet!,
            ) <
            100;

    var reserved = bottomCta + textBlock + verticalPadding + cardExtra;
    if (hasThumbs) reserved += thumbsBlock;
    if (hasMedia) reserved += actionsBlock;
    if (showCompletionBanner) reserved += bannerBlock;

    return (bodyHeight - reserved).clamp(250.0, 380.0);
  }

  @override
  Widget build(BuildContext context) {
    final hasPetProfile = widget.petName != null && widget.petName!.isNotEmpty;
    final hasMedia = widget.mediaItems.isNotEmpty;
    final hasVideos = widget.mediaItems.any((item) => item.isVideo);
    final hasThumbs = hasMedia && widget.mediaItems.length > 1;
    final cardHeight = _cardHeight(context);
    final showCompletionBanner = widget.profile != null &&
        widget.pet != null &&
        profileCoreCompletionPercent(
              profile: widget.profile!,
              pet: widget.pet!,
            ) <
            100;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                if (showCompletionBanner)
                  _ProfileCompletionBanner(
                    profile: widget.profile!,
                    pet: widget.pet!,
                    onTap: widget.onEdit,
                  ),
                if (hasMedia)
                  SwipePreviewCard(
                    controller: _previewController,
                    mediaItems: widget.mediaItems,
                    mediaIndex: _safeMediaIndex,
                    petName: widget.petName,
                    maxHeight: cardHeight,
                    onMediaIndexChanged: (index) =>
                        setState(() => _mediaIndex = index),
                    onPreviewDecision: _onPreviewDecision,
                  )
                else
                  const Expanded(
                    child: Center(child: AppLogo(size: 96)),
                  ),
                if (hasThumbs) ...[
                  const SizedBox(height: 12),
                  PetPhotoThumbnailStrip(
                    mediaItems: widget.mediaItems,
                    selectedIndex: _safeMediaIndex,
                    onSelected: (index) =>
                        setState(() => _mediaIndex = index),
                  ),
                ],
                if (hasMedia) ...[
                  const SizedBox(height: 12),
                  SwipePreviewActions(
                    compact: true,
                    onPass: _previewController.previewPass,
                    onLike: _previewController.previewLike,
                  ),
                ],
                const Spacer(),
                Text(
                  hasPetProfile
                      ? '¡Hola, ${widget.petName}!'
                      : 'Bienvenido a tinDog',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                if (widget.errorMessage != null) ...[
                  Text(
                    widget.errorMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  hasPetProfile
                      ? hasMedia
                          ? hasVideos
                              ? 'Vista previa con fotos y videos. Así te verán en el match.'
                              : 'Así te verán otras mascotas. El match real llega en una próxima actualización.'
                          : 'Tu perfil está listo. Subí fotos o videos para ver la vista previa.'
                      : 'Completá el perfil de tu mascota para continuar.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: TindogFilledButton(
            onPressed: widget.onEdit,
            child: Text(hasPetProfile ? 'Editar perfil' : 'Completar perfil'),
          ),
        ),
      ],
    );
  }
}

class _ProfileCompletionBanner extends StatelessWidget {
  const _ProfileCompletionBanner({
    required this.profile,
    required this.pet,
    required this.onTap,
  });

  final ProfileModel profile;
  final PetModel pet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = profileCoreCompletionProgress(
      profile: profile,
      pet: pet,
    );
    final message = profileCoreCompletionMessage(profile: profile, pet: pet);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        message,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TindogGradientProgressBar(value: progress, height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
