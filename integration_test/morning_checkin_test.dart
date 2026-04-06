// T164: US2 morning check-in integration smoke test.
// Verifies that the morning check-in flow renders with mock providers.
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
import 'package:habit_coach/features/ai_coaching/presentation/widgets/morning_prompt_card.dart';
import 'package:habit_coach/features/habits/presentation/providers/habit_providers.dart';
import 'package:habit_coach/features/habits/presentation/screens/dashboard_screen.dart';
import 'package:habit_coach/features/subscription/domain/services/entitlement_service.dart';

final _now = DateTime(2026, 3, 25, 9, 0);

Conversation _conv(List<Message> messages) => Conversation(
  id: 'conv-1',
  userId: 'u1',
  type: ConversationType.morning,
  date: '2026-03-25',
  messages: messages,
  expiresAt: _now.add(const Duration(days: 90)),
  createdAt: _now,
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('US2: Morning check-in smoke tests', () {
    testWidgets('Dashboard shows morning prompt card for Pro users', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            habitListProvider.overrideWith((ref) async => const []),
            todayCompletionsProvider.overrideWith((ref) async => const []),
            morningCardVisibilityProvider.overrideWith((ref) async => true),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(MorningPromptCard), findsOneWidget);
      expect(find.text('Morning check-in ready'), findsOneWidget);
    });

    testWidgets('Dashboard hides morning card for free users', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            habitListProvider.overrideWith((ref) async => const []),
            todayCompletionsProvider.overrideWith((ref) async => const []),
            morningCardVisibilityProvider.overrideWith((ref) async => false),
          ],
          child: const MaterialApp(home: DashboardScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Morning check-in ready'), findsNothing);
    });

    testWidgets('Morning prompt card is dismissible', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            morningCardVisibilityProvider.overrideWith((ref) async => true),
          ],
          child: const MaterialApp(home: Scaffold(body: MorningPromptCard())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Morning check-in ready'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('Morning check-in ready'), findsNothing);
    });

    testWidgets('Chat screen renders AI message', (tester) async {
      final conv = _conv([
        Message(
          role: MessageRole.assistant,
          content: 'Good morning! How are you feeling today?',
          timestamp: _now,
        ),
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatProvider.overrideWith(
              (ref) => _FakeChatNotifier(
                ChatState(conversation: conv, isLoading: false, error: null),
              ),
            ),
          ],
          child: const MaterialApp(home: ChatScreen(conversationId: 'conv-1')),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Good morning! How are you feeling today?'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Chat screen shows complete bar after 20 turns', (
      tester,
    ) async {
      final conv = _conv(
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
            chatProvider.overrideWith(
              (ref) => _FakeChatNotifier(
                ChatState(conversation: conv, isLoading: false, error: null),
              ),
            ),
          ],
          child: const MaterialApp(home: ChatScreen(conversationId: 'conv-1')),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Check-in complete! See you this evening.'),
        findsOneWidget,
      );
    });
  });
}

CoachingUseCase _fakeUseCase() => CoachingUseCase(
  coachingRepository: _FakeRepo(),
  entitlementService: _FakeEntitlement(),
);

class _FakeChatNotifier extends ChatNotifier {
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
