import 'package:habit_coach/features/ai_coaching/domain/entities/message.dart';

/// T055: Conversation domain entity — pure Dart, no Flutter imports.
enum ConversationType { morning, evening }

final class Conversation {
  const Conversation({
    required this.id,
    required this.userId,
    required this.type,
    required this.date,
    required this.messages,
    required this.expiresAt,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final ConversationType type;

  /// Local calendar date string (yyyy-MM-dd) for the conversation.
  final String date;

  final List<Message> messages;
  final DateTime expiresAt;
  final DateTime createdAt;

  int get turnCount => messages.length;
  bool get isComplete => turnCount >= 20;
  bool get hasMessages => messages.isNotEmpty;

  String? get lastAssistantMessage =>
      messages.where((m) => m.isAssistant).lastOrNull?.content;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Conversation && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
