import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/features/ai_coaching/presentation/providers/coaching_providers.dart';
import 'package:habit_coach/features/ai_coaching/presentation/widgets/morning_prompt_card.dart';

/// T163: MorningPromptCard widget tests — visibility and dismissibility.
Widget _buildCard({bool showMorning = true}) {
  return ProviderScope(
    overrides: [
      morningCardVisibilityProvider.overrideWith((ref) async => showMorning),
    ],
    child: const MaterialApp(home: Scaffold(body: MorningPromptCard())),
  );
}

void main() {
  group('MorningPromptCard', () {
    testWidgets('shows morning check-in title', (tester) async {
      await tester.pumpWidget(_buildCard());
      await tester.pumpAndSettle();
      expect(find.text('Morning check-in ready'), findsOneWidget);
    });

    testWidgets('shows Start button', (tester) async {
      await tester.pumpWidget(_buildCard());
      await tester.pumpAndSettle();
      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('shows dismiss close icon', (tester) async {
      await tester.pumpWidget(_buildCard());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('hides card after dismiss tap', (tester) async {
      await tester.pumpWidget(_buildCard());
      await tester.pumpAndSettle();

      // Verify card is visible
      expect(find.text('Morning check-in ready'), findsOneWidget);

      // Tap the dismiss button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Card should be gone (SizedBox.shrink replaces it)
      expect(find.text('Morning check-in ready'), findsNothing);
    });
  });
}
