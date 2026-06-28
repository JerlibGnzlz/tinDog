import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/feedback/app_feedback.dart';
import '../../../core/feedback/app_haptics.dart';
import '../../../core/session/user_data_cache.dart';
import '../../../core/network/session_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/profile_completion_confetti.dart';
import '../../../shared/widgets/tindog_back_button.dart';
import '../../../shared/widgets/tindog_filled_button.dart';
import '../../../shared/widgets/tindog_gradient_progress_bar.dart';
import '../../../shared/widgets/tindog_loader.dart';
import '../../pets/data/pet_model.dart';
import '../../pets/data/pet_media_model.dart';
import '../data/profile_model.dart';
import 'profile_providers.dart';
import 'widgets/profile_menu_tile.dart';

class ProfileHubScreen extends ConsumerStatefulWidget {
  const ProfileHubScreen({super.key});

  @override
  ConsumerState<ProfileHubScreen> createState() => _ProfileHubScreenState();
}

class _ProfileHubScreenState extends ConsumerState<ProfileHubScreen> {
  int? _previousCompletedCount;
  bool _playConfetti = false;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);
    final petAsync = ref.watch(myPetProvider);

    ref.listen(myProfileProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          if (isSessionError(error)) {
            handleSessionExpired(ref, context, error);
          }
        },
      );
    });
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
        title: const Text('Mi perfil'),
        leading: TindogBackButton(onPressed: () => context.go('/home')),
        leadingWidth: 48,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: TindogLoader(message: 'Cargando perfil…')),
        error: (error, _) {
          if (isSessionError(error)) {
            return _SessionErrorBody(
              onLogin: () => context.go('/login'),
            );
          }
          return _ErrorBody(
            message: readableError(error),
            onRetry: () => ref.read(userDataCacheGenerationProvider.notifier).update((n) => n + 1),
          );
        },
        data: (profile) => petAsync.when(
          loading: () => const Center(child: TindogLoader(message: 'Cargando perfil…')),
          error: (error, _) {
            if (isSessionError(error)) {
              return _SessionErrorBody(
                onLogin: () => context.go('/login'),
              );
            }
            return _ErrorBody(
              message: readableError(error),
              onRetry: () => ref.read(userDataCacheGenerationProvider.notifier).update((n) => n + 1),
            );
          },
          data: (pet) {
            final completedCount = _completedCount(profile, pet);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _handleCompletionChange(completedCount);
            });

            return ProfileCompletionConfetti(
              play: _playConfetti,
              child: _HubBody(
                profile: profile,
                pet: pet,
                completedCount: completedCount,
              ),
            );
          },
        ),
      ),
    );
  }

  int _completedCount(ProfileModel profile, PetModel pet) {
    return [
      isPersonalComplete(profile),
      isPetComplete(pet),
      isPhotosComplete(pet),
      isLocationComplete(profile),
    ].where((v) => v).length;
  }

  void _handleCompletionChange(int completedCount) {
    final previous = _previousCompletedCount;
    if (previous != null && previous < 4 && completedCount == 4) {
      setState(() => _playConfetti = true);
      AppHaptics.success();
      showTindogSuccessSnackBar(
        context,
        '¡Perfil completo! Ya estás listo para hacer match.',
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _playConfetti = false);
      });
    }
    _previousCompletedCount = completedCount;
  }
}

class _SessionErrorBody extends StatelessWidget {
  const _SessionErrorBody({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Tu sesión no está activa',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Iniciá sesión de nuevo para ver tu perfil.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TindogFilledButton(
              onPressed: onLogin,
              child: const Text('Iniciar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message),
            const SizedBox(height: 16),
            TindogFilledButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HubBody extends ConsumerWidget {
  const _HubBody({
    required this.profile,
    required this.pet,
    required this.completedCount,
  });

  final ProfileModel profile;
  final PetModel pet;
  final int completedCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personalDone = isPersonalComplete(profile);
    final petDone = isPetComplete(pet);
    final photosDone = isPhotosComplete(pet);
    final locationDone = isLocationComplete(profile);
    final videosAsync = ref.watch(myPetVideosProvider);
    final videos = videosAsync.valueOrNull ?? const [];
    final videosDone = isVideosComplete(videos);
    final progress = completedCount / 4;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Text(
          'Completá tu perfil',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ).animate().fadeIn(duration: 300.ms),
        const SizedBox(height: 4),
        Text(
          '$completedCount de 4 secciones listas',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ).animate().fadeIn(delay: 60.ms, duration: 300.ms),
        const SizedBox(height: 12),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => TindogGradientProgressBar(value: value),
        ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
        const SizedBox(height: 20),
        ProfileMenuTile(
          animationIndex: 0,
          icon: Icons.person_outline,
          title: 'Datos personales',
          subtitle: personalDone ? (profile.name ?? '') : 'Tu nombre y bio',
          isComplete: personalDone,
          onTap: () => context.push('/profile/personal'),
        ),
        ProfileMenuTile(
          animationIndex: 1,
          icon: Icons.pets,
          title: 'Datos caninos',
          subtitle: petDone ? petHubSubtitle(pet) : 'Nombre, raza, edad y más',
          isComplete: petDone,
          onTap: () => context.push('/profile/pet'),
        ),
        ProfileMenuTile(
          animationIndex: 2,
          icon: Icons.photo_library_outlined,
          title: 'Fotos',
          subtitle: photosDone
              ? 'Galería lista · hasta 6 fotos'
              : 'Subí hasta 6 fotos',
          isComplete: photosDone,
          onTap: () => context.push('/profile/photos'),
        ),
        ProfileMenuTile(
          animationIndex: 3,
          icon: Icons.videocam_outlined,
          title: 'Videos',
          subtitle: videosDone
              ? videos.length == 1
                  ? '1 clip listo'
                  : '${videos.length} clips listos'
              : 'Hasta $maxPetVideos clips cortos (opcional)',
          isComplete: videosDone,
          onTap: () => context.push('/profile/videos'),
        ),
        ProfileMenuTile(
          animationIndex: 4,
          icon: Icons.location_on_outlined,
          title: 'Ubicación',
          subtitle: locationDone ? (profile.location ?? '') : 'Ciudad o barrio',
          isComplete: locationDone,
          onTap: () => context.push('/profile/location'),
        ),
      ],
    );
  }
}
