/// T056: Message value object — a single turn in an AI conversation.
/// Pure Dart, no Flutter imports.
enum MessageRole { user, assistant }

final class Message {
  const Message({
    required this.role,
    required this.content,
    required this.timestamp,
  });

  final MessageRole role;
  final String content;
  final DateTime timestamp;

  bool get isUser => role == MessageRole.user;
  bool get isAssistant => role == MessageRole.assistant;

  Map<String, dynamic> toJson() => {
    'role': role.name,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
  };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
    role: json['role'] == 'user' ? MessageRole.user : MessageRole.assistant,
    content: json['content'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.role == role &&
          other.content == content &&
          other.timestamp == timestamp);

  @override
  int get hashCode => Object.hash(role, content, timestamp);
}
