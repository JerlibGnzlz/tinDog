import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/session_handler.dart';
import '../../../core/session/user_data_cache.dart';
import '../../pets/data/pet_model.dart';
import '../../pets/data/pet_repository.dart';
import '../../pets/data/pet_media_model.dart';
import '../../pets/data/pet_media_repository.dart';
import '../data/profile_model.dart';
import '../data/profile_repository.dart';
import '../../../shared/models/swipe_preview_media.dart';

final myProfileProvider = FutureProvider<ProfileModel>((ref) async {
  ref.watch(userDataCacheGenerationProvider);
  final token = await ref.read(tokenStorageProvider).readToken();
  if (token == null || token.isEmpty) {
    throw const SessionRequiredException();
  }
  return ref.read(profileRepositoryProvider).getMyProfile();
});

final myPetProvider = FutureProvider<PetModel>((ref) async {
  ref.watch(userDataCacheGenerationProvider);
  final token = await ref.read(tokenStorageProvider).readToken();
  if (token == null || token.isEmpty) {
    throw const SessionRequiredException();
  }
  return ref.read(petRepositoryProvider).getMyPet();
});

final myPetPhotosProvider = FutureProvider<List<PetMediaModel>>((ref) async {
  ref.watch(userDataCacheGenerationProvider);
  final token = await ref.read(tokenStorageProvider).readToken();
  if (token == null || token.isEmpty) {
    throw const SessionRequiredException();
  }
  return ref.read(petMediaRepositoryProvider).listMyPhotos();
});

final myPetVideosProvider = FutureProvider<List<PetMediaModel>>((ref) async {
  ref.watch(userDataCacheGenerationProvider);
  final token = await ref.read(tokenStorageProvider).readToken();
  if (token == null || token.isEmpty) {
    throw const SessionRequiredException();
  }
  return ref.read(petMediaRepositoryProvider).listMyVideos();
});

List<SwipePreviewMediaItem> buildSwipePreviewMedia({
  required List<PetMediaModel> photos,
  required List<PetMediaModel> videos,
  String? fallbackPhotoUrl,
}) {
  final items = <SwipePreviewMediaItem>[
    ...photos.map((photo) => SwipePreviewMediaItem.photo(photo.url)),
    ...videos.map(
      (video) => SwipePreviewMediaItem.video(
        url: video.url,
        durationSec: video.durationSec,
      ),
    ),
  ];

  if (items.isEmpty) {
    final url = fallbackPhotoUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return [SwipePreviewMediaItem.photo(url)];
    }
  }

  return items;
}

bool isPersonalComplete(ProfileModel profile) =>
    (profile.name ?? '').trim().isNotEmpty;

bool isPetComplete(PetModel pet) => (pet.name ?? '').trim().isNotEmpty;

String petHubSubtitle(PetModel pet) {
  if (!isPetComplete(pet)) {
    return 'Nombre, raza, edad y más';
  }
  final parts = <String>[pet.name!.trim()];
  if (pet.age != null) {
    parts.add('${pet.age} años');
  }
  if ((pet.breed ?? '').trim().isNotEmpty) {
    parts.add(pet.breed!.trim());
  }
  return parts.join(' · ');
}

bool isPhotosComplete(PetModel pet) => (pet.photoUrl ?? '').trim().isNotEmpty;

bool isVideosComplete(List<PetMediaModel> videos) => videos.isNotEmpty;

bool isLocationComplete(ProfileModel profile) =>
    (profile.location ?? '').trim().isNotEmpty;

const profileCoreSectionCount = 4;

int countProfileCoreSectionsComplete({
  required ProfileModel profile,
  required PetModel pet,
}) {
  return [
    isPersonalComplete(profile),
    isPetComplete(pet),
    isPhotosComplete(pet),
    isLocationComplete(profile),
  ].where((v) => v).length;
}

double profileCoreCompletionProgress({
  required ProfileModel profile,
  required PetModel pet,
}) {
  return countProfileCoreSectionsComplete(profile: profile, pet: pet) /
      profileCoreSectionCount;
}

int profileCoreCompletionPercent({
  required ProfileModel profile,
  required PetModel pet,
}) {
  return (profileCoreCompletionProgress(profile: profile, pet: pet) * 100)
      .round();
}

String? profileCoreNextStepLabel({
  required ProfileModel profile,
  required PetModel pet,
}) {
  if (!isPersonalComplete(profile)) return 'datos personales';
  if (!isPetComplete(pet)) return 'datos de tu mascota';
  if (!isPhotosComplete(pet)) return 'fotos';
  if (!isLocationComplete(profile)) return 'ubicación';
  return null;
}

String profileCoreCompletionMessage({
  required ProfileModel profile,
  required PetModel pet,
}) {
  final percent = profileCoreCompletionPercent(profile: profile, pet: pet);
  if (percent >= 100) {
    return 'Perfil completo — ¡listo para el match!';
  }

  final nextStep = profileCoreNextStepLabel(profile: profile, pet: pet);
  return 'Perfil $percent% listo — falta $nextStep';
}
