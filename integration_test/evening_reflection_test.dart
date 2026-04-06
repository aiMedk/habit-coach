// T166: US3 evening reflection integration smoke test.
// Verifies that the evening reflection flow renders with mock providers.
// This test does not require a live Supabase connection.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:habit_coach/features/ai_coaching/domain/entities/conversation.dart';
import 'package:habit_coach/features/ai_coaching/domain/entities/message.dart';
import 'package:habit_coach/features/ai_coaching/domain/repositories/coaching_repository.dart';
import 'package:habit_coach/features/ai_coaching/domain/usecases/coaching_usecase.dart';
import 'package:habit_coach/features/ai_coaching/presentation/providers/coaching_providers.dart';
import 'package:habit_coach/features/ai_coaching/presentation/screens/chat_screen.dart';
import 'package:habit_coach/features/ai_coaching/presentation/widgets/evening_prompt_card.dart';
import 'package:habit_coach/features/habits/presentation/providers/habit_providers.dart';
import 'package:habit_coach/features/habits/presentation/screens/dashboard_screen.dart';
import 'package:habit_coach/features/subscription/domain/services/entitlement_service.dart';

final _now = DateTime(2026, 3, 25, 20, 0); // 8 PM

Conversation _eveningConv(List<Message> messages) => Conversation(
  id: 'ev-1',
  userId: 'u1',
  type: ConversationType.evening,
  date: '2026-03-25',
  messages: messages,
  expiresAt: _now.add(const Duration(days: 90)),
  createdAt: _now,
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('US3: Evening reflection smoke tests', () {
    testWidgets(
      'Dashboard shows evening prompt card for Pro users in evening',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              habitListProvider.overrideWith((ref) async => const []),
              todayCompletionsProvider.overrideWith((ref) async => const []),
              morningCardVisibilityProvider.overrideWith((ref) async => false),
              eveningCardVisibilityProvider.overrideWith((ref) async => true),
            ],
            child: const MaterialApp(home: DashboardScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(EveningPromptCard), findsOneWidget);
        expect(find.text('Evening reflection ready'), findsOneWidget);
      },
    );

    testWidgets('Dashboard hides evening card when morning card is showing', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            habitListProvider.overrideWith((ref) async => const []),
            todayCompletionsProvider.overrideWith((ref) async => const []),
            morningCardVisibilityProvider.overrideWith((ref) async => true),
            eveningCardVisibilityProvider.overrideWith((ref) async => true),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      // Morning card takes priority
      expect(find.text('Morning check-in ready'), findsOneWidget);
      expect(find.text('Evening reflection ready'), findsNothing);
    });

    testWidgets('Evening prompt card is dismissible', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eveningCardVisibilityProvider.overrideWith((ref) async => true),
          ],
          child: const MaterialApp(home: Scaffold(body: EveningPromptCard())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Evening reflection ready'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Evening reflection ready'), findsNothing);
    });

    testWidgets('Chat screen shows "Evening reflection" title for evening', (
      tester,
    ) async {
      final conv = _eveningConv([
        Message(
          role: MessageRole.assistant,
          content: 'Good evening! How was your day?',
          timestamp: _now,
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eveningChatProvider.overrideWith(
              (ref) => _FakeChatNotifier(
                ChatState(conversation: conv, isLoading: false, error: null),
              ),
            ),
          ],
          child: const MaterialApp(
            home: ChatScreen(conversationId: 'new-evening'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Evening reflection'), findsOneWidget);
      expect(find.text('Good evening! How was your day?'), findsOneWidget);
    });

    testWidgets('Evening chat shows correct completion message', (
      tester,
    ) async {
      final conv = _eveningConv(
        List.generate(
          20,
          (i) => Message(
            role: i.isEven ? MessageRole.assistant : MessageRole.user,
            content: 'Turn $i',
            timestamp: _now,
          ),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eveningChatProvider.overrideWith(
              (ref) => _FakeChatNotifier(
                ChatState(conversation: conv, isLoading: false, error: null),
              ),
            ),
          ],
          child: const MaterialApp(
            home: ChatScreen(conversationId: 'new-evening'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Reflection complete! Have a restful night.'),
        findsOneWidget,
      );
    });
  });
}

CoachingUseCase _fakeUseCase() => CoachingUseCase(
  coachingRepository: _FakeRepo(),
  entitlementService: _FakeEntitlement(),
);

class _FakeChatNotifier extends EveningChatNotifier {
  _FakeChatNotifier(ChatState initialState) : super(_fakeUseCase()) {
    state = initialState;
  }

  @override
  Future<void> startConversation() async {}

  @override
  Future<void> sendMessage(String text, {String? conversationId}) async {}
}

class _FakeRepo implements CoachingRepository {
  @override
  Future<Conversation> sendMorningMessage({
    String? conversationId,
    String? userMessage,
  }) => throw UnimplementedError();

  @override
  Future<Conversation> sendEveningMessage({
    String? conversationId,
    String? userMessage,
  }) => throw UnimplementedError();

  @override
  Future<Conversation?> getTodayMorningConversation(String userId) async =>
      null;

  @override
  Future<Conversation?> getTodayEveningConversation(String userId) async =>
      null;

  @override
  Future<List<Conversation>> getConversationHistory(String userId) async => [];

  @override
  Future<Conversation?> getConversationById(String id) async => null;
}

class _FakeEntitlement implements EntitlementService {
  @override
  bool get isPro => true;
  @override
  bool canAddHabit(int count) => true;
  @override
  bool get canAccessAI => true;
  @override
  bool get canAccessPartner => true;
  @override
  bool get canAccessChallenge => true;
}
