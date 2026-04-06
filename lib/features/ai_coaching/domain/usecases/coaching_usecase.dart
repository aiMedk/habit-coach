import 'package:habit_coach/core/utils/date_utils.dart';
import 'package:habit_coach/features/ai_coaching/domain/entities/conversation.dart';
import 'package:habit_coach/features/ai_coaching/domain/repositories/coaching_repository.dart';
import 'package:habit_coach/features/subscription/domain/services/entitlement_service.dart';

/// T058: CoachingUseCase — orchestrates AI check-in visibility and messaging.
final class CoachingUseCase {
  const CoachingUseCase({
    required this.coachingRepository,
    required this.entitlementService,
  });

  final CoachingRepository coachingRepository;
  final EntitlementService entitlementService;

  /// Returns true if the morning check-in card should be shown on the dashboard.
  ///
  /// Conditions:
  /// - User is on Pro tier
  /// - Current time is within morning window (5 AM – 11:59 AM)
  /// - Today's morning check-in has not yet been started
  Future<bool> canShowMorningCard(String userId) async {
    if (!entitlementService.canAccessAI) return false;
    if (!HabitDateUtils.isMorningWindow(DateTime.now())) return false;
    final existing = await coachingRepository.getTodayMorningConversation(
      userId,
    );
    return existing == null;
  }

  /// Returns true if the evening reflection card should be shown on the dashboard.
  ///
  /// Conditions:
  /// - User is on Pro tier
  /// - Current time is within evening window (6 PM – 11:59 PM)
  /// - Today's evening reflection has not yet been started
  Future<bool> canShowEveningCard(String userId) async {
    if (!entitlementService.canAccessAI) return false;
    if (!HabitDateUtils.isEveningWindow(DateTime.now())) return false;
    final existing = await coachingRepository.getTodayEveningConversation(
      userId,
    );
    return existing == null;
  }

  /// Starts or continues a morning check-in conversation.
  Future<Conversation> sendMorningMessage({
    String? conversationId,
    String? userMessage,
  }) => coachingRepository.sendMorningMessage(
    conversationId: conversationId,
    userMessage: userMessage,
  );

  /// Starts or continues an evening reflection conversation.
  Future<Conversation> sendEveningMessage({
    String? conversationId,
    String? userMessage,
  }) => coachingRepository.sendEveningMessage(
    conversationId: conversationId,
    userMessage: userMessage,
  );

  /// Returns today's morning conversation, or null if not started.
  Future<Conversation?> getTodayMorningConversation(String userId) =>
      coachingRepository.getTodayMorningConversation(userId);

  /// Returns today's evening conversation, or null if not started.
  Future<Conversation?> getTodayEveningConversation(String userId) =>
      coachingRepository.getTodayEveningConversation(userId);

  /// Returns conversation history for the given user.
  Future<List<Conversation>> getConversationHistory(String userId) =>
      coachingRepository.getConversationHistory(userId);
}
