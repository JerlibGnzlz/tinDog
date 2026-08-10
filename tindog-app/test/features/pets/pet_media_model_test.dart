import 'package:flutter_test/flutter_test.dart';
import 'package:tindog_app/features/pets/data/pet_media_model.dart';

void main() {
  group('límites de media', () {
    test('fotos y videos de perfil', () {
      expect(maxPetPhotos, 6);
      expect(maxPetVideos, 2);
      expect(maxVideoDurationSec, 30);
    });
  });

  group('PetMediaModel', () {
    test('fromJson foto', () {
      final m = PetMediaModel.fromJson({
        'id': 'media-1',
        'petId': 'pet-1',
        'type': 'photo',
        'url': 'https://cdn.example/a.jpg',
        'publicId': 'pub-1',
        'sortOrder': 0,
        'isPrimary': true,
      });
      expect(m.isVideo, isFalse);
      expect(m.isPrimary, isTrue);
      expect(m.durationSec, isNull);
    });

    test('fromJson video con duración', () {
      final m = PetMediaModel.fromJson({
        'id': 'media-2',
        'petId': 'pet-1',
        'type': 'video',
        'url': 'https://cdn.example/v.mp4',
        'publicId': 'pub-2',
        'sortOrder': 1,
        'isPrimary': false,
        'durationSec': 25,
      });
      expect(m.isVideo, isTrue);
      expect(m.durationSec, 25);
    });
  });
}
