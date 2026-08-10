import 'package:flutter_test/flutter_test.dart';
import 'package:tindog_app/features/chat/presentation/widgets/chat_time_format.dart';

void main() {
  final now = DateTime(2026, 8, 10, 15, 30);

  group('isSameCalendarDay', () {
    test('mismo día local', () {
      expect(
        isSameCalendarDay(
          DateTime(2026, 8, 10, 1),
          DateTime(2026, 8, 10, 23),
        ),
        isTrue,
      );
    });

    test('días distintos', () {
      expect(
        isSameCalendarDay(DateTime(2026, 8, 9), DateTime(2026, 8, 10)),
        isFalse,
      );
    });
  });

  group('formatChatListTime', () {
    test('hoy → hora', () {
      expect(
        formatChatListTime(DateTime(2026, 8, 10, 9, 5), now: now),
        '09:05',
      );
    });

    test('ayer', () {
      expect(
        formatChatListTime(DateTime(2026, 8, 9, 12), now: now),
        'Ayer',
      );
    });

    test('dentro de la semana → día corto', () {
      // 2026-08-10 es lunes; 2026-08-07 es viernes.
      expect(
        formatChatListTime(DateTime(2026, 8, 7, 12), now: now),
        'vie',
      );
    });
  });

  group('formatPresenceLabel', () {
    test('online', () {
      expect(
        formatPresenceLabel(online: true, lastActive: now, now: now),
        'En línea',
      );
    });

    test('sin lastActive', () {
      expect(
        formatPresenceLabel(online: false, now: now),
        'Desconectado',
      );
    });

    test('hace minutos', () {
      expect(
        formatPresenceLabel(
          online: false,
          lastActive: now.subtract(const Duration(minutes: 12)),
          now: now,
        ),
        'Últ. vez hace 12 min',
      );
    });

    test('hoy a una hora', () {
      expect(
        formatPresenceLabel(
          online: false,
          lastActive: DateTime(2026, 8, 10, 10, 0),
          now: now,
        ),
        'Últ. vez a las 10:00',
      );
    });
  });
}
