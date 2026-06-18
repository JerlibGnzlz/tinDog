import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../pets/data/pet_model.dart';
import '../../pets/data/pet_repository.dart';
import '../data/profile_model.dart';
import '../data/profile_repository.dart';

final myProfileProvider = FutureProvider<ProfileModel>((ref) {
  return ref.watch(profileRepositoryProvider).getMyProfile();
});

final myPetProvider = FutureProvider<PetModel>((ref) {
  return ref.watch(petRepositoryProvider).getMyPet();
});

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

bool isLocationComplete(ProfileModel profile) =>
    (profile.location ?? '').trim().isNotEmpty;
