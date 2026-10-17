import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_proj/services/grid_data_service.dart';

void main() {
  test('GridDataService loads and parses all 3 files successfully', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final data = await GridDataService.loadGridData();
    expect(data.routes.isNotEmpty, true);
    expect(data.substations.isNotEmpty, true);
    expect(data.kmlTowers.isNotEmpty, true);
    expect(data.kmlSegments.isNotEmpty, true);
    expect(data.routes.length, 8);
    expect(data.kmlTowers.length, 10);
    expect(data.substations.length, 8);
  });
}
