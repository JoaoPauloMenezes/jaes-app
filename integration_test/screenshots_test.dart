import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:jaes_app/firebase_options.dart';
import 'package:jaes_app/pages/home_page.dart';
import 'package:jaes_app/services/sample_data_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app store screenshots', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await SampleDataGenerator.generateSampleData();

    // Bypasses login so no real account is needed.
    await tester.pumpWidget(
      const MaterialApp(debugShowCheckedModeBanner: false, home: HomeScreen()),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    Future<void> shot(String name) async {
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      await binding.takeScreenshot(name);
    }

    await shot('01_daily_summary');

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    await shot('02_card_front');

    await tester.tapAt(tester.getCenter(find.byType(Scaffold).last));
    await tester.pumpAndSettle();
    await shot('03_card_back');

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    await shot('04_library');

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    await shot('05_settings');
  });
}
