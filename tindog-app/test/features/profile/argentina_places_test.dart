import 'package:flutter_test/flutter_test.dart';
import 'package:tindog_app/features/profile/data/argentina_provinces.dart';

void main() {
  group('kArgentinaProvinces', () {
    test('tiene las 24 jurisdicciones', () {
      expect(kArgentinaProvinces, hasLength(24));
      expect(kArgentinaProvinces.where((p) => p.isCaba), hasLength(1));
    });

    test('cada provincia del interior tiene capital', () {
      for (final p in kArgentinaProvinces) {
        if (p.isCaba) {
          expect(p.capital, isNull);
        } else {
          expect(p.capital, isNotNull);
          expect(p.capital!.isNotEmpty, isTrue);
        }
      }
    });

    test('provinceByShortOrName resuelve CABA y Córdoba', () {
      expect(provinceByShortOrName('CABA')?.id, '02');
      expect(provinceByShortOrName('Córdoba')?.id, '14');
      expect(provinceById('06')?.capital, 'La Plata');
    });
  });
}
