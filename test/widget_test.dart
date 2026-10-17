import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_proj/main.dart';

void main() {
  testWidgets('KnoGrid App smoke test and launch verification',
      (WidgetTester tester) async {
    await tester.pumpWidget(const KnoGridApp());

    // Verify initial loading or screen state
    expect(find.byType(KnoGridApp), findsOneWidget);
  });
}
