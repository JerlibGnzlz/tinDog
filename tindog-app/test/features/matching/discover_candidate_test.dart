import 'package:flutter_test/flutter_test.dart';
import 'package:tindog_app/features/matching/data/discover_candidate.dart';

void main() {
  group('DiscoverCandidate', () {
    test('fromJson mapea campos básicos', () {
      final c = DiscoverCandidate.fromJson({
        'id': 'pet-1',
        'name': 'Luna',
        'age': 3,
        'breed': 'Golden Retriever',
        'bio': 'Muy sociable',
        'location': 'Madrid, España',
        'distanceKm': 2.4,
        'isActive': true,
        'ownerUserId': 'user-1',
        'photoUrls': ['https://example.com/a.jpg', ''],
      });

      expect(c.id, 'pet-1');
      expect(c.name, 'Luna');
      expect(c.age, 3);
      expect(c.breed, 'Golden Retriever');
      expect(c.bio, 'Muy sociable');
      expect(c.ownerUserId, 'user-1');
      expect(c.photoUrls, ['https://example.com/a.jpg']);
      expect(c.mediaItems, hasLength(1));
    });

    test('locationLabel agrega prefijo Vive en', () {
      const c = DiscoverCandidate(
        id: '1',
        name: 'Luna',
        photoUrls: [],
        location: 'Madrid, España',
      );
      expect(c.locationLabel, 'Vive en Madrid, España');
    });

    test('locationLabel no duplica Vive', () {
      const c = DiscoverCandidate(
        id: '1',
        name: 'Luna',
        photoUrls: [],
        location: 'Vive en Córdoba',
      );
      expect(c.locationLabel, 'Vive en Córdoba');
    });

    test('distanceLabel en metros si < 1 km', () {
      const c = DiscoverCandidate(
        id: '1',
        name: 'Luna',
        photoUrls: [],
        distanceKm: 0.35,
      );
      expect(c.distanceLabel, 'A 350 m de distancia');
    });

    test('distanceLabel redondea km', () {
      const near = DiscoverCandidate(
        id: '1',
        name: 'Luna',
        photoUrls: [],
        distanceKm: 2.4,
      );
      const far = DiscoverCandidate(
        id: '2',
        name: 'Rocky',
        photoUrls: [],
        distanceKm: 10352,
      );
      expect(near.distanceLabel, 'A 2.4 km de distancia');
      expect(far.distanceLabel, 'A 10352 km de distancia');
    });
  });

  group('LikeResult', () {
    test('fromJson con match', () {
      final r = LikeResult.fromJson({
        'liked': true,
        'matched': true,
        'match': {'id': 'm-1'},
      });
      expect(r.liked, isTrue);
      expect(r.matched, isTrue);
      expect(r.matchId, 'm-1');
    });
  });
}
