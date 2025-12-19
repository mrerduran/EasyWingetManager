import 'package:flutter_test/flutter_test.dart';
import 'package:easy_winget_manager/main.dart';
import 'package:easy_winget_manager/src/rust/frb_generated.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => RustLib.init());
  testWidgets('Can call rust function', (WidgetTester tester) async {
    await tester.pumpWidget(const EasyWingetApp());
    expect(find.text('Easy Winget Manager'), findsWidgets);
  });
}
