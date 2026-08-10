import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tindog_app/core/constants/app_constants.dart';
import 'package:tindog_app/main.dart';

/// Credenciales del seed (`tindog-api/prisma/seed.ts`).
/// Override: `--dart-define=E2E_EMAIL=... --dart-define=E2E_PASSWORD=...`
const _e2eEmail = String.fromEnvironment(
  'E2E_EMAIL',
  defaultValue: 'ana@tindog.test',
);
const _e2ePassword = String.fromEnvironment(
  'E2E_PASSWORD',
  defaultValue: 'password123',
);

Future<void> _pumpFrames(WidgetTester tester, [Duration d = const Duration(milliseconds: 600)]) async {
  await tester.pump();
  await tester.pump(d);
}

Future<void> _clearStoredSession() async {
  const storage = FlutterSecureStorage();
  await storage.delete(key: AppConstants.tokenKey);
}

Future<void> _waitFor(Finder finder, WidgetTester tester, {int attempts = 40}) async {
  for (var i = 0; i < attempts; i++) {
    await _pumpFrames(tester, const Duration(milliseconds: 500));
    if (finder.evaluate().isNotEmpty) return;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'login real (seed) welcome → home',
    (tester) async {
      await _clearStoredSession();

      await tester.pumpWidget(const ProviderScope(child: TinDogApp()));
      await _pumpFrames(tester, const Duration(seconds: 1));

      // Si quedó sesión en otro proceso, forzar welcome vía UI no aplica;
      // el clear de token + arranque limpio debe bastar.
      expect(find.text('Continuar con email'), findsOneWidget);

      await tester.tap(find.text('Continuar con email'));
      await _pumpFrames(tester, const Duration(seconds: 1));
      expect(find.text('Entrar'), findsOneWidget);

      final fields = find.byType(TextFormField);
      expect(fields, findsAtLeastNWidgets(2));

      await tester.enterText(fields.at(0), _e2eEmail);
      await tester.enterText(fields.at(1), _e2ePassword);
      await _pumpFrames(tester);

      await tester.tap(find.text('Entrar'));

      // Login + redirect a /home (bottom nav "Desliza").
      await _waitFor(find.text('Desliza'), tester);
      expect(find.text('Desliza'), findsOneWidget);
      expect(find.text('Explorar'), findsOneWidget);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
