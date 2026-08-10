import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tindog_app/main.dart';

void main() {
  testWidgets('App arranca en welcome', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TinDogApp()));
    // No pumpAndSettle: animaciones / fonts / plugins pueden no terminar.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('tinDog'), findsWidgets);
  });
}
