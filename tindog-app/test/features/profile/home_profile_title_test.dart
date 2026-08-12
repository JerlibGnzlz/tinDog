import 'package:flutter_test/flutter_test.dart';
import 'package:tindog_app/features/pets/data/pet_model.dart';
import 'package:tindog_app/features/profile/data/profile_model.dart';
import 'package:tindog_app/features/profile/presentation/profile_providers.dart';

void main() {
  test('homeProfileTitle no usa el nombre del tutor/Google', () {
    expect(homeProfileTitle(petName: null), 'Tu mascota');
    expect(homeProfileTitle(petName: '  '), 'Tu mascota');
    expect(homeProfileTitle(petName: 'Luna'), 'Luna');
    expect(homeProfileTitle(petName: 'Luna', petAge: 3), 'Luna, 3');
  });

  test('ProfileModel fromJson incluye email y Google', () {
    final p = ProfileModel.fromJson({
      'id': 'p1',
      'userId': 'u1',
      'name': 'Jerlib',
      'email': 'jerlibgnzlz@gmail.com',
      'googleLinked': true,
      'avatarUrl': 'https://example.com/a.png',
    });
    expect(p.email, 'jerlibgnzlz@gmail.com');
    expect(p.googleLinked, isTrue);
    expect(p.avatarUrl, 'https://example.com/a.png');
  });

  test('próximo paso del perfil prioriza la mascota', () {
    expect(
      profileCoreNextStepLabel(
        profile: const ProfileModel(id: 'p', userId: 'u', name: 'Jerlib'),
        pet: const PetModel(id: 'pet', userId: 'u'),
      ),
      'datos de tu mascota',
    );
  });
}
