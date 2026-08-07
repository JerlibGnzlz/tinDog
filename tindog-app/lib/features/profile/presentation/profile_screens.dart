import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_navigation.dart';
import '../../../core/network/session_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/swipe_preview_media.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/pet_photo_thumbnail_strip.dart';
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
            onPressed: () => context.go('/discover'),
            icon: const Icon(Icons.local_fire_department_rounded),
            tooltip: 'Deslizar / Matches',
          ),
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

  @override
  Widget build(BuildContext context) {
    final hasPetProfile = widget.petName != null && widget.petName!.isNotEmpty;
    final hasMedia = widget.mediaItems.isNotEmpty;
    final hasThumbs = hasMedia && widget.mediaItems.length > 1;
    final showCompletionBanner = widget.profile != null &&
        widget.pet != null &&
        profileCoreCompletionPercent(
              profile: widget.profile!,
              pet: widget.pet!,
            ) <
            100;
    final breed = widget.pet?.breed?.trim();
    final bio = widget.profile?.bio?.trim();

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
            child: Column(
              children: [
                if (showCompletionBanner)
                  _ProfileCompletionBanner(
                    profile: widget.profile!,
                    pet: widget.pet!,
                    onTap: widget.onEdit,
                  ),
                if (hasMedia)
                  Expanded(
                    child: SwipePreviewCard(
                      mediaItems: widget.mediaItems,
                      mediaIndex: _safeMediaIndex,
                      petName: widget.petName,
                      petAge: widget.pet?.age,
                      subtitle: (breed != null && breed.isNotEmpty)
                          ? breed
                          : null,
                      bio: (bio != null && bio.isNotEmpty) ? bio : null,
                      expand: true,
                      borderRadius: 18,
                      onInfoTap: widget.onEdit,
                      onMediaIndexChanged: (index) =>
                          setState(() => _mediaIndex = index),
                    ),
                  )
                else
                  const Expanded(
                    child: Center(child: AppLogo(size: 96)),
                  ),
                if (hasThumbs) ...[
                  const SizedBox(height: 10),
                  PetPhotoThumbnailStrip(
                    mediaItems: widget.mediaItems,
                    selectedIndex: _safeMediaIndex,
                    onSelected: (index) =>
                        setState(() => _mediaIndex = index),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  hasPetProfile
                      ? hasMedia
                          ? 'Así te ven al deslizar'
                          : 'Subí fotos para ver la vista previa'
                      : 'Completá el perfil de tu mascota',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (widget.errorMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.errorMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Column(
            children: [
              if (hasPetProfile && hasMedia) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/discover'),
                    icon: const Icon(Icons.local_fire_department_rounded),
                    label: const Text('Ir a Desliza'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              TindogFilledButton(
                onPressed: widget.onEdit,
                child: Text(
                  hasPetProfile ? 'Editar perfil' : 'Completar perfil',
                ),
              ),
            ],
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
