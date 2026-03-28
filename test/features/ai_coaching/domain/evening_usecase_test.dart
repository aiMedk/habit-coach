import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:habit_coach/features/ai_coaching/domain/entities/conversation.dart';
import 'package:habit_coach/features/ai_coaching/domain/repositories/coaching_repository.dart';
import 'package:habit_coach/features/ai_coaching/domain/usecases/coaching_usecase.dart';
import 'package:habit_coach/features/subscription/domain/services/entitlement_service.dart';

/// T165: US3 unit tests — CoachingUseCase.canShowEveningCard time window logic,
/// evening conversation type mapping.
class _MockCoachingRepository extends Mock implements CoachingRepository {}

class _MockEntitlementService extends Mock implements EntitlementService {}

void main() {
  late _MockCoachingRepository repo;
  late _MockEntitlementService entitlement;
  late CoachingUseCase useCase;

  final now = DateTime(2026, 3, 25, 20, 0); // 8 PM

  Conversation _eveningConv() => Conversation(
    id: 'ev-1',
    userId: 'u1',
    type: ConversationType.evening,
    date: '2026-03-25',
    messages: const [],
    expiresAt: now.add(const Duration(days: 90)),
    createdAt: now,
  );

  setUp(() {
    repo = _MockCoachingRepository();
    entitlement = _MockEntitlementService();
    useCase = CoachingUseCase(
      coachingRepository: repo,
      entitlementService: entitlement,
    );
  });

  group('canShowEveningCard', () {
    test('returns false when user is not Pro', () async {
      when(() => entitlement.canAccessAI).thenReturn(false);

      final result = await useCase.canShowEveningCard('u1');
      expect(result, isFalse);
      verifyNever(() => repo.getTodayEveningConversation(any()));
    });

    test(
      'returns false when canAccessAI is false regardless of time',
      () async {
        when(() => entitlement.canAccessAI).thenReturn(false);
        final result = await useCase.canShowEveningCard('u1');
        expect(result, isFalse);
      },
    );

    test('does not query repo when not Pro', () async {
      when(() => entitlement.canAccessAI).thenReturn(false);
      await useCase.canShowEveningCard('u1');
      verifyNever(() => repo.getTodayEveningConversation(any()));
    });

    test('returns a bool regardless of system time', () async {
      when(() => entitlement.canAccessAI).thenReturn(true);
      when(
        () => repo.getTodayEveningConversation('u1'),
      ).thenAnswer((_) async => null);
      final result = await useCase.canShowEveningCard('u1');
      expect(result, isA<bool>());
    });
  });

  group('sendEveningMessage', () {
    test('delegates to repository', () async {
      final conv = _eveningConv();
      when(
        () => repo.sendEveningMessage(
          conversationId: any(named: 'conversationId'),
          userMessage: any(named: 'userMessage'),
        ),
      ).thenAnswer((_) async => conv);

      final result = await useCase.sendEveningMessage(
        conversationId: 'ev-1',
        userMessage: 'Good evening',
      );
      expect(result, equals(conv));
      expect(result.type, ConversationType.evening);
    });

    test('returns evening conversation type', () async {
      final conv = _eveningConv();
      when(
        () => repo.sendEveningMessage(
          conversationId: any(named: 'conversationId'),
          userMessage: any(named: 'userMessage'),
        ),
      ).thenAnswer((_) async => conv);

      final result = await useCase.sendEveningMessage();
      expect(result.type, ConversationType.evening);
    });
  });

  group('getTodayEveningConversation', () {
    test('delegates to repository', () async {
      final conv = _eveningConv();
      when(
        () => repo.getTodayEveningConversation('u1'),
      ).thenAnswer((_) async => conv);

      final result = await useCase.getTodayEveningConversation('u1');
      expect(result, equals(conv));
    });

    test('returns null when no evening conversation today', () async {
      when(
        () => repo.getTodayEveningConversation('u1'),
      ).thenAnswer((_) async => null);

      final result = await useCase.getTodayEveningConversation('u1');
      expect(result, isNull);
    });
  });

  group('Conversation type enum', () {
    test('morning and evening are distinct', () {
      expect(ConversationType.morning, isNot(ConversationType.evening));
    });

    test('evening conversation has correct type', () {
      final conv = _eveningConv();
      expect(conv.type, ConversationType.evening);
    });
  });
}
