import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tindog_app/features/auth/presentation/auth_provider.dart';
import 'package:tindog_app/main.dart';

/// Sesión forzada a logged-out para que el test siempre arranque en /welcome.
class _LoggedOutAuthSession extends AuthSessionNotifier {
  @override
  Future<bool> build() async => false;
}

Future<void> _pumpFrames(WidgetTester tester) async {
  // Evitar pumpAndSettle: animaciones / plugins pueden no "terminar".
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('welcome → login (Continuar con email)', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionProvider.overrideWith(_LoggedOutAuthSession.new),
        ],
        child: const TinDogApp(),
      ),
    );
    await _pumpFrames(tester);

    expect(find.textContaining('tinDog'), findsWidgets);
    expect(find.text('Continuar con email'), findsOneWidget);

    await tester.tap(find.text('Continuar con email'));
    await _pumpFrames(tester);

    expect(find.text('Email'), findsWidgets);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
