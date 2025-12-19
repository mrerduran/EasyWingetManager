import 'package:flutter_test/flutter_test.dart';
import 'package:easy_winget_manager/main.dart';
import 'package:provider/provider.dart';
import 'package:easy_winget_manager/providers/package_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => PackageProvider(),
        child: const EasyWingetApp(),
      ),
    );

    // Verify that the app title exists.
    expect(find.text('Easy Winget Manager'), findsAtLeastNWidgets(1));
  });
}
