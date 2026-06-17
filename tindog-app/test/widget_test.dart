import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tindog_app/main.dart';

void main() {
  testWidgets('App loads login route', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TinDogApp()));
    await tester.pumpAndSettle();

    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
