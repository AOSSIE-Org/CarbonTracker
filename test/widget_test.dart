import 'package:flutter_test/flutter_test.dart';

import 'package:carbon_tracker/main.dart';

void main() {
  testWidgets('App renders welcome screen with localized hello',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('Welcome to Carbon Tracker!'), findsOneWidget);
  });
}
