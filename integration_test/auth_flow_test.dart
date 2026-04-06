// T156: Auth integration smoke test.
// Verifies app launches, navigates to login, and routes correctly.
// Requires SUPABASE_URL and SUPABASE_ANON_KEY to be injected at build time.
// Run with: flutter test integration_test/auth_flow_test.dart \
//   --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<key>
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:habit_coach/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth flow smoke test', () {
    testWidgets('App launches and shows login screen', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // The redirect guard should route an unauthenticated user to /login.
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('Login screen has email, password, and sign-up link', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('Tapping Sign Up navigates to signup screen', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find and tap via text
      await tester.tap(find.text('Sign Up').last);
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsOneWidget);
    });
  });
}
