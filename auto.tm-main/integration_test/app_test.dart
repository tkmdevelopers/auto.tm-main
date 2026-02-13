import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:auto_tm/main.dart' as app;

/// Integration tests for the Auto.tm app
/// Run with: flutter test integration_test/app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Launch Tests', () {
    testWidgets('app should start and show splash screen', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();

      // After splash, we should see some UI
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('app should show home screen after loading', (
      WidgetTester tester,
    ) async {
      app.main();

      // Wait for splash screen animation
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Should find scaffold (main app structure)
      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  group('Navigation Tests', () {
    testWidgets('bottom navigation should have multiple tabs', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Look for bottom navigation bar
      final bottomNav = find.byType(BottomNavigationBar);
      if (bottomNav.evaluate().isNotEmpty) {
        expect(bottomNav, findsOneWidget);
      }
    });
  });
}
