import 'package:flutter_test/flutter_test.dart';

import 'package:sz_pic_flutter/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SZPicApp());

    // Verify that the app launches with the home screen
    expect(find.text('SZ Picture Create'), findsOneWidget);
    expect(find.text('Collage & Slideshow Creator'), findsOneWidget);

    // Verify menu items are present
    expect(find.text('Create Collage'), findsOneWidget);
    expect(find.text('Create Slideshow'), findsOneWidget);
    expect(find.text('Edit Photo'), findsOneWidget);

    // Verify version footer
    expect(find.text('v0.5'), findsOneWidget);
  });
}
