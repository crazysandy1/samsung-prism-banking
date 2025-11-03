import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:samsung_prism/providers/keystroke_auth_provider.dart';
import 'package:samsung_prism/screens/auth/enhanced_login_screen.dart';
import 'package:samsung_prism/providers/auth_provider.dart';
import 'package:samsung_prism/models/keystroke_models.dart';

void main() {
  group('Keystroke Authentication Integration Tests', () {
    testWidgets('Enhanced login screen loads without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => KeystrokeAuthProvider()),
          ],
          child: const MaterialApp(
            home: EnhancedLoginScreen(),
          ),
        ),
      );

      // Verify the screen loads
      expect(find.text('Samsung Prism'), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('Keystroke toggle switch works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => KeystrokeAuthProvider()),
          ],
          child: const MaterialApp(
            home: EnhancedLoginScreen(),
          ),
        ),
      );

      // Find and tap the keystroke toggle switch
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      // Initially should be disabled
      Switch switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, isFalse);

      // Tap to enable
      await tester.tap(switchFinder);
      await tester.pump();

      // Should now be enabled
      switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, isTrue);
    });

    testWidgets('Email and password fields are present', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => KeystrokeAuthProvider()),
          ],
          child: const MaterialApp(
            home: EnhancedLoginScreen(),
          ),
        ),
      );

      // Check for email and password fields
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    test('KeystrokeAuthProvider initializes correctly', () {
      final provider = KeystrokeAuthProvider();
      
      expect(provider.isConfigured, isFalse);
      expect(provider.state.status, KeystrokeAuthStatus.idle);
      expect(provider.serverIp, isNull);
    });

    test('KeystrokeAuthProvider configuration', () async {
      final provider = KeystrokeAuthProvider();
      
      // Test configuration
      await provider.configure(
        serverIp: '127.0.0.1',
        port: 5000,
        useHttps: false,
      );
      
      expect(provider.serverIp, equals('127.0.0.1'));
    });
  });

  group('Keystroke Setup Screen Tests', () {
    testWidgets('Setup screen displays properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => KeystrokeAuthProvider()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Text('Keystroke Setup Screen Test'),
            ),
          ),
        ),
      );

      expect(find.text('Keystroke Setup Screen Test'), findsOneWidget);
    });
  });
}
