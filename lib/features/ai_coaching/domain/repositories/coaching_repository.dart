import 'package:habit_coach/features/ai_coaching/domain/entities/conversation.dart';

/// T057/T069: CoachingRepository interface — domain layer, no Supabase imports.
abstract interface class CoachingRepository {
  /// Starts a new morning check-in or continues an existing one.
  ///
  /// Pass [conversationId] = null and [userMessage] = null to start fresh.
  /// Pass both to continue an existing conversation.
  /// Returns the updated [Conversation] with the new assistant message appended.
  Future<Conversation> sendMorningMessage({
    String? conversationId,
    String? userMessage,
  });

  /// Starts a new evening reflection or continues an existing one.
  ///
  /// Same semantics as [sendMorningMessage] but calls the evening Edge Function.
  Future<Conversation> sendEveningMessage({
    String? conversationId,
    String? userMessage,
  });

  /// Returns today's morning conversation if it exists, or null.
  Future<Conversation?> getTodayMorningConversation(String userId);

  /// Returns today's evening conversation if it exists, or null.
  Future<Conversation?> getTodayEveningConversation(String userId);

  /// Returns all conversations for [userId] within the 90-day retention window,
  /// sorted by date descending.
  Future<List<Conversation>> getConversationHistory(String userId);

  /// Returns a single conversation by [id], or null.
  Future<Conversation?> getConversationById(String id);
}
