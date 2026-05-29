import 'package:flutter_test/flutter_test.dart';

import 'package:fashion_room_girls/main.dart';

void main() {
  testWidgets('Shop screen shows items and opens purchase dialog', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Store'), findsOneWidget);
    expect(find.text('0 TC'), findsOneWidget);
    expect(find.text('Chaussures'), findsOneWidget);
    expect(find.text('Baskets Coeur'), findsOneWidget);
    expect(find.text('ACHETER >'), findsWidgets);

    await tester.tap(find.text('ACHETER >').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text("CONFIRMER L'ACHAT"), findsOneWidget);
    expect(find.text('CONFIRMER'), findsOneWidget);
    expect(find.text('ANNULER'), findsOneWidget);
  });
}
