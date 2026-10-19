import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_proj/main.dart';

void main() {
  testWidgets('TowerLens App smoke test and launch verification',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TowerLensApp());

    // Verify initial loading or screen state
    expect(find.byType(TowerLensApp), findsOneWidget);
  });
}
