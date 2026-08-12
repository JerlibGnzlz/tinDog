import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindog_app/shared/widgets/confirm_app_exit_scope.dart';

void main() {
  testWidgets('atrás muestra diálogo y Cancelar no sale', (tester) async {
    var exited = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ConfirmAppExitScope(
          onExit: () async => exited = true,
          child: const Scaffold(body: Text('shell')),
        ),
      ),
    );

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    // Simula atrás del sistema (Android) o pop del route (también relevante en iOS).
    final handled = await navigator.maybePop();
    expect(handled, isTrue);
    await tester.pumpAndSettle();

    expect(find.text('¿Salir de tinDog?'), findsOneWidget);
    expect(
      find.text('Vas a dejar la app. Tu sesión seguirá iniciada.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Salir de tinDog?'), findsNothing);
    expect(find.text('shell'), findsOneWidget);
    expect(exited, isFalse);
  });

  testWidgets('Salir invoca onExit sin navegar a welcome', (tester) async {
    var exited = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ConfirmAppExitScope(
          onExit: () async => exited = true,
          child: const Scaffold(body: Text('shell')),
        ),
      ),
    );

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await navigator.maybePop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();

    expect(exited, isTrue);
    expect(find.text('shell'), findsOneWidget);
  });

  testWidgets('tras salir y volver, atrás vuelve a preguntar', (tester) async {
    var exitCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: ConfirmAppExitScope(
          onExit: () async => exitCount++,
          child: const Scaffold(body: Text('shell')),
        ),
      ),
    );

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));

    Future<void> confirmExit() async {
      await navigator.maybePop();
      await tester.pumpAndSettle();
      expect(find.text('¿Salir de tinDog?'), findsOneWidget);
      await tester.tap(find.text('Salir'));
      await tester.pumpAndSettle();
    }

    await confirmExit();
    expect(exitCount, 1);

    // Simula volver a la app (como tras moveTaskToBack).
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    await confirmExit();
    expect(exitCount, 2);
    expect(find.text('shell'), findsOneWidget);
  });

  testWidgets('showConfirmAppExitDialog respeta Cancelar y Salir', (
    tester,
  ) async {
    bool? first;
    bool? second;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Column(
                children: [
                  TextButton(
                    onPressed: () async {
                      first = await showConfirmAppExitDialog(context);
                    },
                    child: const Text('ask1'),
                  ),
                  TextButton(
                    onPressed: () async {
                      second = await showConfirmAppExitDialog(context);
                    },
                    child: const Text('ask2'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('ask1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(first, isFalse);

    await tester.tap(find.text('ask2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();
    expect(second, isTrue);
  });
}
