import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aira/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen displays NIEPMD logo and title',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );

    // Verify that the title 'Aira' is present.
    expect(find.text('Aira'), findsOneWidget);

    // Verify that the NIEPMD logo image asset is rendered.
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == 'assets/niepmd-logo.png',
      ),
      findsOneWidget,
    );
  });
}

