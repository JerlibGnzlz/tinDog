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
        'ownerName': 'Ana Pérez',
        'ownerAvatarUrl': 'https://example.com/ana.jpg',
        'photoUrls': ['https://example.com/a.jpg', ''],
      });

      expect(c.id, 'pet-1');
      expect(c.name, 'Luna');
      expect(c.age, 3);
      expect(c.breed, 'Golden Retriever');
      expect(c.bio, 'Muy sociable');
      expect(c.ownerUserId, 'user-1');
      expect(c.ownerName, 'Ana Pérez');
      expect(c.ownerAvatarUrl, 'https://example.com/ana.jpg');
      expect(c.photoUrls, ['https://example.com/a.jpg']);
      expect(c.videos, isEmpty);
      expect(c.mediaItems, hasLength(1));
    });

    test('fromJson incluye videos de perfil', () {
      final c = DiscoverCandidate.fromJson({
        'id': 'pet-2',
        'name': 'Rocky',
        'photoUrls': ['https://example.com/a.jpg'],
        'videos': [
          {'url': 'https://example.com/v.mp4', 'durationSec': 12},
        ],
      });
      expect(c.videos, hasLength(1));
      expect(c.videos.first.durationSec, 12);
      expect(c.mediaItems, hasLength(2));
      expect(c.mediaItems.last.isVideo, isTrue);
    });

    test('locationLabel usa barrio corto', () {
      const c = DiscoverCandidate(
        id: '1',
        name: 'Luna',
        photoUrls: [],
        location: 'Palermo, Buenos Aires',
      );
      expect(c.shortLocation, 'Palermo');
      expect(c.locationLabel, 'Vive en Palermo');
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

    test('distanceLabel usa bandas amables', () {
      expect(
        const DiscoverCandidate(
          id: '1',
          name: 'Luna',
          photoUrls: [],
          distanceKm: 0.12,
        ).distanceLabel,
        'Muy cerca · a menos de 250 m',
      );
      expect(
        const DiscoverCandidate(
          id: '1',
          name: 'Luna',
          photoUrls: [],
          distanceKm: 0.35,
        ).distanceLabel,
        'A menos de 1 km',
      );
      expect(
        const DiscoverCandidate(
          id: '1',
          name: 'Luna',
          photoUrls: [],
          distanceKm: 2.4,
        ).distanceLabel,
        'A unos 2.4 km',
      );
      expect(
        const DiscoverCandidate(
          id: '2',
          name: 'Rocky',
          photoUrls: [],
          distanceKm: 42,
        ).distanceLabel,
        'A 42 km',
      );
    });

    test('proximityTip solo si está cerca', () {
      expect(
        const DiscoverCandidate(
          id: '1',
          name: 'Luna',
          photoUrls: [],
          distanceKm: 0.5,
        ).proximityTip,
        'Ideal para un playdate cerca',
      );
      expect(
        const DiscoverCandidate(
          id: '1',
          name: 'Luna',
          photoUrls: [],
          distanceKm: 3.2,
        ).proximityTip,
        'Buena distancia para un paseo juntos',
      );
      expect(
        const DiscoverCandidate(
          id: '1',
          name: 'Luna',
          photoUrls: [],
          distanceKm: 12,
        ).proximityTip,
        isNull,
      );
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

  group('LikeListItem', () {
    test('fromJson incluye matchId', () {
      final item = LikeListItem.fromJson({
        'id': 'pet-z',
        'name': 'Zoe',
        'photoUrls': [],
        'likedAt': '2026-08-11T00:00:00.000Z',
        'matched': true,
        'matchId': 'match-z',
      });
      expect(item.name, 'Zoe');
      expect(item.matched, isTrue);
      expect(item.matchId, 'match-z');
    });
  });
}
