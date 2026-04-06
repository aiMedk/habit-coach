import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/features/ai_coaching/domain/entities/conversation.dart';
import 'package:habit_coach/features/ai_coaching/domain/entities/message.dart';
import 'package:habit_coach/features/ai_coaching/domain/repositories/coaching_repository.dart';
import 'package:habit_coach/features/ai_coaching/domain/usecases/coaching_usecase.dart';
import 'package:habit_coach/features/ai_coaching/presentation/providers/coaching_providers.dart';
import 'package:habit_coach/features/ai_coaching/presentation/screens/chat_screen.dart';
import 'package:habit_coach/features/subscription/domain/services/entitlement_service.dart';

/// T163: ChatScreen widget tests — message rendering and skeleton loader.

final _now = DateTime(2026, 3, 25, 9, 0);

Message _msg(MessageRole role, String content) =>
    Message(role: role, content: content, timestamp: _now);

Conversation _conv(List<Message> messages) => Conversation(
  id: 'conv-1',
  userId: 'u1',
  type: ConversationType.morning,
  date: '2026-03-25',
  messages: messages,
  expiresAt: _now.add(const Duration(days: 90)),
  createdAt: _now,
);

Widget _buildChat({required ChatState state}) {
  return ProviderScope(
    overrides: [chatProvider.overrideWith((ref) => _FakeNotifier(state))],
    child: const MaterialApp(home: ChatScreen(conversationId: 'conv-1')),
  );
}

CoachingUseCase _fakeUseCase() => CoachingUseCase(
  coachingRepository: _FakeRepo(),
  entitlementService: _FakeEntitlement(),
);

class _FakeNotifier extends ChatNotifier {
  _FakeNotifier(ChatState initialState) : super(_fakeUseCase()) {
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

void main() {
  group('ChatScreen', () {
    testWidgets('shows AppBar', (tester) async {
      await tester.pumpWidget(
        _buildChat(
          state: ChatState(conversation: null, isLoading: false, error: null),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('renders assistant and user message bubbles', (tester) async {
      final conv = _conv([
        _msg(MessageRole.assistant, 'Good morning!'),
        _msg(MessageRole.user, 'Hello there'),
      ]);

      await tester.pumpWidget(
        _buildChat(
          state: ChatState(conversation: conv, isLoading: false, error: null),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Good morning!'), findsOneWidget);
      expect(find.text('Hello there'), findsOneWidget);
    });

    testWidgets('shows text input bar when conversation is not complete', (
      tester,
    ) async {
      final conv = _conv([_msg(MessageRole.assistant, 'Hi')]);

      await tester.pumpWidget(
        _buildChat(
          state: ChatState(conversation: conv, isLoading: false, error: null),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows completion bar when conversation is complete', (
      tester,
    ) async {
      final conv = _conv(
        List.generate(20, (i) => _msg(MessageRole.user, 'msg $i')),
      );

      await tester.pumpWidget(
        _buildChat(
          state: ChatState(conversation: conv, isLoading: false, error: null),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Check-in complete! See you this evening.'),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('shows skeleton loader when loading with no messages', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildChat(
          state: ChatState(conversation: null, isLoading: true, error: null),
        ),
      );
      // Don't pumpAndSettle — skeleton is visible during loading
      await tester.pump();
      // Skeleton renders Container widgets
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('shows error view when loading fails', (tester) async {
      await tester.pumpWidget(
        _buildChat(
          state: ChatState(
            conversation: null,
            isLoading: false,
            error: 'Network error',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Your coach is unavailable right now.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
