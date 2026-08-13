import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/session_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../pets/data/pet_media_model.dart';
import '../../pets/data/pet_model.dart';
import '../../safety/presentation/safety_sheets.dart';
import '../data/profile_model.dart';
import 'profile_providers.dart';
import 'widgets/home_profile_action_row.dart';
import 'widgets/home_profile_atmosphere.dart';
import 'widgets/home_profile_avatar.dart';
import 'widgets/home_profile_promo_carousel.dart';
import 'widgets/home_profile_skeleton.dart';
import 'widgets/home_settings_sheet.dart';

/// Tab Perfil (/home): hub estilo Tinder con colores tinDog.
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
      backgroundColor: Colors.transparent,
      body: HomeProfileAtmosphere(
        child: petAsync.when(
          loading: () => const HomeProfileSkeleton(),
          error: (error, _) => _HomeProfileBody(
            errorMessage: readableError(error),
            onEdit: () => context.push('/profile'),
          ),
          data: (pet) {
            if ((pet.name ?? '').trim().isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) context.go('/profile/pet');
              });
            }
            final photos = photosAsync.valueOrNull ?? const <PetMediaModel>[];
            final videos = videosAsync.valueOrNull ?? const <PetMediaModel>[];
            final profile = profileAsync.valueOrNull;
            return _HomeProfileBody(
              pet: pet,
              profile: profile,
              photos: photos,
              videos: videos,
              onEdit: () => context.push('/profile'),
            );
          },
        ),
      ),
    );
  }
}

class _HomeProfileBody extends ConsumerWidget {
  const _HomeProfileBody({
    required this.onEdit,
    this.pet,
    this.profile,
    this.photos = const [],
    this.videos = const [],
    this.errorMessage,
  });

  final VoidCallback onEdit;
  final PetModel? pet;
  final ProfileModel? profile;
  final List<PetMediaModel> photos;
  final List<PetMediaModel> videos;
  final String? errorMessage;

  String? get _photoUrl {
    final primary = photos.where((p) => p.isPrimary).map((p) => p.url);
    if (primary.isNotEmpty) return primary.first;
    if (photos.isNotEmpty) return photos.first.url;
    return pet?.photoUrl;
  }

  String get _title => homeProfileTitle(
        petName: pet?.name,
        petAge: pet?.age,
      );

  String get _nudgeText {
    if (profile != null && pet != null) {
      final percent = profileCoreCompletionPercent(
        profile: profile!,
        pet: pet!,
      );
      if (percent < 100) {
        return profileCoreCompletionMessage(profile: profile!, pet: pet!);
      }
    }
    final avatar = profile?.avatarUrl?.trim();
    if (avatar == null || avatar.isEmpty) {
      return 'Sumá tu foto: otros dueños confían más cuando ven tu cara.';
    }
    if (videos.isEmpty) {
      return '¡Novedad! Añadí un video corto: es lo que más diferencia a tinDog.';
    }
    if (photos.length < 2) {
      return 'Sumá más fotos para que tu perfil destaque en Desliza.';
    }
    return 'Así te ven en Desliza. Mantené el perfil al día.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = MediaQuery.paddingOf(context).top;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, top + 12, 20, 12),
            child: Column(
              children: [
                HomeProfileAvatar(
                  photoUrl: _photoUrl,
                  onEdit: onEdit,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (_isCoreComplete) ...[
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Perfil listo para Desliza (no es verificación de identidad)',
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                    if (profile?.googleLinked == true) ...[
                      const SizedBox(width: 6),
                      const Tooltip(
                        message: 'Verificado con Google',
                        child: Icon(
                          Icons.verified_rounded,
                          size: 22,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                _NudgeBubble(text: _nudgeText, onTap: onEdit),
                if (errorMessage != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 22),
                HomeProfileActionRow(
                  onSettings: () => showHomeSettingsSheet(
                    context: context,
                    ref: ref,
                  ),
                  onAddMedia: () => context.push('/profile/photos'),
                  onSafety: () => showSafetyInfoSheet(context),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        HomeProfilePromoCarousel(slides: _promoSlides(context)),
      ],
    );
  }

  bool get _isCoreComplete {
    if (profile == null || pet == null) return false;
    return isPersonalComplete(profile!) &&
        isPetComplete(pet!) &&
        isPhotosComplete(pet!, galleryPhotos: photos) &&
        isLocationComplete(profile!);
  }

  List<HomePromoSlide> _promoSlides(BuildContext context) {
    final slides = <HomePromoSlide>[];
    final coreDone = _isCoreComplete;

    if (!coreDone) {
      slides.add(
        HomePromoSlide(
          title: 'Completá tu perfil',
          subtitle: 'Nombre y bio visibles para otros dueños',
          cta: 'Editar perfil',
          icon: Icons.pets_rounded,
          onCta: onEdit,
        ),
      );
    }
    final avatar = profile?.avatarUrl?.trim();
    if (avatar == null || avatar.isEmpty) {
      slides.add(
        HomePromoSlide(
          title: 'Tu foto genera confianza',
          subtitle: 'Mostrá quién acompaña a la mascota',
          cta: 'Datos personales',
          icon: Icons.person_rounded,
          onCta: () => context.push('/profile/personal'),
        ),
      );
    }
    if (videos.isEmpty) {
      slides.add(
        HomePromoSlide(
          title: 'Sumá un vídeo',
          subtitle: 'Un clip corto muestra personalidad',
          cta: 'Subir vídeo',
          icon: Icons.videocam_rounded,
          onCta: () => context.push('/profile/videos'),
        ),
      );
    }
    if (photos.length < 2) {
      slides.add(
        HomePromoSlide(
          title: 'Más fotos',
          subtitle: 'Varias fotos = más likes',
          cta: 'Añadir fotos',
          icon: Icons.photo_library_rounded,
          onCta: () => context.push('/profile/photos'),
        ),
      );
    }
    slides.add(
      HomePromoSlide(
        title: coreDone ? 'Seguí deslizando' : 'Empezá a deslizar',
        subtitle: coreDone
            ? 'Hay perfiles nuevos en Desliza'
            : 'Cuando estés listo, buscá amigos',
        cta: 'Ir a Desliza',
        icon: Icons.local_fire_department_rounded,
        onCta: () => context.go('/discover'),
      ),
    );
    // Una idea clara: como máximo 3 slides (prioridad + Desliza).
    if (slides.length <= 3) return slides;
    return [slides.first, slides[slides.length - 2], slides.last];
  }
}

class _NudgeBubble extends StatelessWidget {
  const _NudgeBubble({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.95),
              AppColors.primaryDark,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}
