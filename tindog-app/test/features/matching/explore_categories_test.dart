import 'package:flutter_test/flutter_test.dart';
import 'package:tindog_app/features/matching/presentation/explore_categories.dart';

void main() {
  group('exploreDogShortcuts', () {
    test('abre Discover y tiene 4 atajos', () {
      expect(exploreDogShortcuts, hasLength(4));
      expect(exploreDogShortcuts.every((c) => c.opensDiscover), isTrue);
      expect(
        exploreDogShortcuts.map((c) => c.id).toList(),
        ['near', 'breed', 'play', 'for_you'],
      );
    });
  });

  group('exploreServiceTeasers', () {
    test('no abren Discover (próximamente)', () {
      expect(exploreServiceTeasers, hasLength(4));
      expect(exploreServiceTeasers.every((c) => !c.opensDiscover), isTrue);
      expect(
        exploreServiceTeasers.every((c) => c.countLabel == 'Pronto'),
        isTrue,
      );
    });
  });
}
