import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:habit_coach/core/constants/app_constants.dart';
import 'package:habit_coach/core/error/failures.dart';
import 'package:habit_coach/core/network/supabase_client.dart';
import 'package:habit_coach/core/utils/date_utils.dart';
import 'package:habit_coach/features/ai_coaching/domain/entities/conversation.dart';
import 'package:habit_coach/features/ai_coaching/domain/entities/message.dart';
import 'package:habit_coach/features/ai_coaching/domain/repositories/coaching_repository.dart';

/// T060/T071: SupabaseCoachingRepository — calls the morning and evening Edge
/// Functions and maps responses to domain [Conversation] entities.
final class SupabaseCoachingRepository implements CoachingRepository {
  SupabaseCoachingRepository() : _client = AppSupabaseClient.instance;

  final SupabaseClient _client;

  @override
  Future<Conversation> sendMorningMessage({
    String? conversationId,
    String? userMessage,
  }) async {
    try {
      final response = await _client.functions
          .invoke(
            'ai-morning-checkin',
            body: {
              'conversation_id': conversationId,
              'user_message': userMessage,
            },
          )
          .timeout(
            Duration(seconds: AppConstants.aiFirstTokenTimeoutSeconds * 3),
          );

      if (response.status == 403) {
        throw const EntitlementFailure(
          'Pro subscription required for AI coaching',
        );
      }
      if (response.status == 409) {
        throw const ValidationFailure(
          'Morning check-in already completed today',
        );
      }
      if (response.status == 422) {
        throw const ValidationFailure('Conversation turn limit reached');
      }
      if (response.status != 200) {
        throw ServerFailure('AI service error', statusCode: response.status);
      }

      final data = response.data as Map<String, dynamic>;
      final newConversationId = data['conversation_id'] as String;

      // Fetch the full conversation to return a complete domain object
      return await getConversationById(newConversationId) ??
          _buildMinimalConversation(
            id: newConversationId,
            assistantMessage: data['assistant_message'] as String,
            userMessage: userMessage,
          );
    } on EntitlementFailure {
      rethrow;
    } on ValidationFailure {
      rethrow;
    } on ServerFailure {
      rethrow;
    } catch (e) {
      throw ServerFailure('AI service unavailable: $e');
    }
  }

  @override
  Future<Conversation> sendEveningMessage({
    String? conversationId,
    String? userMessage,
  }) async {
    try {
      final response = await _client.functions
          .invoke(
            'ai-evening-reflection',
            body: {
              'conversation_id': conversationId,
              'user_message': userMessage,
            },
          )
          .timeout(
            Duration(seconds: AppConstants.aiFirstTokenTimeoutSeconds * 3),
          );

      if (response.status == 403) {
        throw const EntitlementFailure(
          'Pro subscription required for AI coaching',
        );
      }
      if (response.status == 409) {
        throw const ValidationFailure(
          'Evening reflection already completed today',
        );
      }
      if (response.status == 422) {
        throw const ValidationFailure('Conversation turn limit reached');
      }
      if (response.status != 200) {
        throw ServerFailure('AI service error', statusCode: response.status);
      }

      final data = response.data as Map<String, dynamic>;
      final newConversationId = data['conversation_id'] as String;

      return await getConversationById(newConversationId) ??
          _buildMinimalConversation(
            id: newConversationId,
            assistantMessage: data['assistant_message'] as String,
            userMessage: userMessage,
            type: ConversationType.evening,
          );
    } on EntitlementFailure {
      rethrow;
    } on ValidationFailure {
      rethrow;
    } on ServerFailure {
      rethrow;
    } catch (e) {
      throw ServerFailure('AI service unavailable: $e');
    }
  }

  @override
  Future<Conversation?> getTodayMorningConversation(String userId) async {
    final today = HabitDateUtils.toDateString(HabitDateUtils.today());
    try {
      final data =
          await _client
              .from('conversations')
              .select()
              .eq('user_id', userId)
              .eq('type', 'morning')
              .eq('date', today)
              .maybeSingle();
      return data != null ? _mapToConversation(data) : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Conversation?> getTodayEveningConversation(String userId) async {
    final today = HabitDateUtils.toDateString(HabitDateUtils.today());
    try {
      final data =
          await _client
              .from('conversations')
              .select()
              .eq('user_id', userId)
              .eq('type', 'evening')
              .eq('date', today)
              .maybeSingle();
      return data != null ? _mapToConversation(data) : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Conversation>> getConversationHistory(String userId) async {
    try {
      final cutoff = HabitDateUtils.toDateString(
        HabitDateUtils.daysAgo(AppConstants.retentionDays),
      );
      final rows = await _client
          .from('conversations')
          .select()
          .eq('user_id', userId)
          .gte('date', cutoff)
          .order('date', ascending: false);
      return (rows as List)
          .map((r) => _mapToConversation(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Conversation?> getConversationById(String id) async {
    try {
      final data =
          await _client
              .from('conversations')
              .select()
              .eq('id', id)
              .maybeSingle();
      return data != null ? _mapToConversation(data) : null;
    } catch (_) {
      return null;
    }
  }

  // ── Mappers ──────────────────────────────────────────────────────────────────

  static Conversation _mapToConversation(Map<String, dynamic> row) {
    final rawMessages =
        (row['messages'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final messages = rawMessages.map(Message.fromJson).toList();
    return Conversation(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      type:
          (row['type'] as String) == 'evening'
              ? ConversationType.evening
              : ConversationType.morning,
      date: row['date'] as String,
      messages: messages,
      expiresAt: DateTime.parse(row['expires_at'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  /// Builds a minimal Conversation when the full fetch fails — ensures the
  /// chat screen always has something to render.
  static Conversation _buildMinimalConversation({
    required String id,
    required String assistantMessage,
    String? userMessage,
    ConversationType type = ConversationType.morning,
  }) {
    final now = DateTime.now().toUtc();
    final messages = <Message>[
      if (userMessage != null)
        Message(
          role: MessageRole.user,
          content: userMessage,
          timestamp: now.subtract(const Duration(seconds: 1)),
        ),
      Message(
        role: MessageRole.assistant,
        content: assistantMessage,
        timestamp: now,
      ),
    ];
    return Conversation(
      id: id,
      userId: '',
      type: type,
      date: HabitDateUtils.toDateString(HabitDateUtils.today()),
      messages: messages,
      expiresAt: now.add(const Duration(days: 90)),
      createdAt: now,
    );
  }
}
