import 'package:flutter_test/flutter_test.dart';

import 'package:sz_pic_flutter/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SZPicApp());

    // Verify that the app launches with the home screen
    expect(find.text('SZ Pic'), findsOneWidget);
    expect(find.text('AI-Powered Collage & Slideshow Creator'), findsOneWidget);
    
    // Verify menu items are present
    expect(find.text('Create Collage'), findsOneWidget);
    expect(find.text('Create Slideshow'), findsOneWidget);
    expect(find.text('My Projects'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
