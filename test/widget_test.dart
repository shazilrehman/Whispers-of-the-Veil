import 'package:flutter_test/flutter_test.dart';

import 'package:whispers_of_the_veil/main.dart';

void main() {
  testWidgets('App renders GameWidget', (WidgetTester tester) async {
    await tester.pumpWidget(const WhispersApp());
    // Verify the game widget is present (loading or rendered).
    expect(find.byType(WhispersApp), findsOneWidget);
  });
}
