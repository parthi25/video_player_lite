import 'package:flutter_test/flutter_test.dart';

import 'package:video_player_app/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app title is present
    expect(find.text('Advanced Video Player'), findsOneWidget);
  });
}
