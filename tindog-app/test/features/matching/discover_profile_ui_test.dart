import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tindog_app/features/chat/presentation/widgets/match_profile_sheet.dart';
import 'package:tindog_app/features/matching/data/discover_candidate.dart';
import 'package:tindog_app/shared/widgets/pet_photo_viewer_screen.dart';

void main() {
  testWidgets('PetPhotoViewerScreen muestra título e índice', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PetPhotoViewerScreen(
          urls: const [
            'https://example.invalid/a.jpg',
            'https://example.invalid/b.jpg',
          ],
          initialIndex: 0,
          title: 'Luna',
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Luna · 1/2'), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);
  });

  testWidgets('showMatchProfileSheet muestra nombre y botón cerrar', (
    tester,
  ) async {
    const pet = DiscoverCandidate(
      id: 'pet-1',
      name: 'Luna',
      age: 3,
      breed: 'Golden Retriever',
      bio: 'Muy sociable',
      location: 'Madrid, España',
      photoUrls: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () => showMatchProfileSheet(
                  context: context,
                  pet: pet,
                ),
                child: const Text('abrir'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pump(); // start sheet
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Perfil'), findsOneWidget);
    expect(find.byTooltip('Cerrar'), findsOneWidget);

    // La foto (AspectRatio 3/4) empuja el nombre fuera del viewport del test.
    await tester.scrollUntilVisible(
      find.text('Luna, 3'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Luna, 3'), findsOneWidget);
    expect(find.text('Golden Retriever'), findsOneWidget);
    expect(find.text('Sobre nosotros'), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Perfil'), findsNothing);
  });
}
