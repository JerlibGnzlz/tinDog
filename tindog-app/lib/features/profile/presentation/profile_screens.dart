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
import '../../../shared/widgets/tindog_loader.dart';
import 'profile_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              petName: pet.name,
              mediaItems: buildSwipePreviewMedia(
                photos: photos,
                videos: const [],
                fallbackPhotoUrl: pet.photoUrl,
              ),
              onEdit: () => context.go('/profile'),
            ),
            error: (_, _) => _HomeBody(
              petName: pet.name,
              mediaItems: buildSwipePreviewMedia(
                photos: photos,
                videos: const [],
                fallbackPhotoUrl: pet.photoUrl,
              ),
              onEdit: () => context.go('/profile'),
            ),
            data: (videos) => _HomeBody(
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
    this.petName,
    this.mediaItems = const [],
    this.errorMessage,
  });

  final VoidCallback onEdit;
  final String? petName;
  final List<SwipePreviewMediaItem> mediaItems;
  final String? errorMessage;

  @override
  State<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<_HomeBody> {
  int _mediaIndex = 0;

  @override
  Widget build(BuildContext context) {
    final hasPetProfile = widget.petName != null && widget.petName!.isNotEmpty;
    final hasMedia = widget.mediaItems.isNotEmpty;
    final hasVideos = widget.mediaItems.any((item) => item.isVideo);
    final cardHeight =
        (MediaQuery.sizeOf(context).height * 0.46).clamp(400.0, 480.0);

    return Column(
      children: [
        Expanded(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              scrollbars: false,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                children: [
                  if (hasMedia)
                    SwipePreviewCard(
                      mediaItems: widget.mediaItems,
                      mediaIndex: _mediaIndex.clamp(
                        0,
                        widget.mediaItems.length - 1,
                      ),
                      petName: widget.petName,
                      maxHeight: cardHeight,
                      onMediaIndexChanged: (index) =>
                          setState(() => _mediaIndex = index),
                    )
                  else
                    const AppLogo(size: 96),
                  if (hasMedia && widget.mediaItems.length > 1) ...[
                    const SizedBox(height: 20),
                    PetPhotoThumbnailStrip(
                      mediaItems: widget.mediaItems,
                      selectedIndex: _mediaIndex,
                      onSelected: (index) =>
                          setState(() => _mediaIndex = index),
                    ),
                  ],
                  SizedBox(height: hasMedia ? 32 : 20),
                  Text(
                    hasPetProfile
                        ? '¡Hola, ${widget.petName}!'
                        : 'Bienvenido a tinDog',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (widget.errorMessage != null) ...[
                    Text(
                      widget.errorMessage!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.red.shade700,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    hasPetProfile
                        ? hasMedia
                            ? hasVideos
                                ? 'Vista previa con fotos y videos. Así te verán en el match.'
                                : 'Así te verán otras mascotas. El match real llega en una próxima actualización.'
                            : 'Tu perfil está listo. Subí fotos o videos para ver la vista previa.'
                        : 'Completá el perfil de tu mascota para continuar.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: TindogFilledButton(
            onPressed: widget.onEdit,
            child: Text(hasPetProfile ? 'Editar perfil' : 'Completar perfil'),
          ),
        ),
      ],
    );
  }
}
