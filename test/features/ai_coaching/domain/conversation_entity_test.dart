import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/features/ai_coaching/domain/entities/conversation.dart';
import 'package:habit_coach/features/ai_coaching/domain/entities/message.dart';

/// T162: Conversation entity unit tests.
void main() {
  final now = DateTime(2026, 3, 25, 9, 0);

  Message _msg(MessageRole role, String content) =>
      Message(role: role, content: content, timestamp: now);

  Conversation _conv({List<Message> messages = const []}) => Conversation(
    id: 'conv-1',
    userId: 'user-1',
    type: ConversationType.morning,
    date: '2026-03-25',
    messages: messages,
    expiresAt: now.add(const Duration(days: 90)),
    createdAt: now,
  );

  group('Conversation', () {
    test('turnCount equals message count', () {
      final conv = _conv(
        messages: [
          _msg(MessageRole.assistant, 'Hi'),
          _msg(MessageRole.user, 'Hello'),
        ],
      );
      expect(conv.turnCount, 2);
    });

    test('isComplete is false when fewer than 20 messages', () {
      final conv = _conv(
        messages: List.generate(19, (i) => _msg(MessageRole.user, 'msg $i')),
      );
      expect(conv.isComplete, isFalse);
    });

    test('isComplete is true when 20 or more messages', () {
      final conv = _conv(
        messages: List.generate(20, (i) => _msg(MessageRole.user, 'msg $i')),
      );
      expect(conv.isComplete, isTrue);
    });

    test('hasMessages is false for empty conversation', () {
      expect(_conv().hasMessages, isFalse);
    });

    test('hasMessages is true when messages present', () {
      final conv = _conv(messages: [_msg(MessageRole.assistant, 'Hi')]);
      expect(conv.hasMessages, isTrue);
    });

    test('lastAssistantMessage returns last assistant content', () {
      final conv = _conv(
        messages: [
          _msg(MessageRole.assistant, 'First'),
          _msg(MessageRole.user, 'User reply'),
          _msg(MessageRole.assistant, 'Second'),
        ],
      );
      expect(conv.lastAssistantMessage, 'Second');
    });

    test('lastAssistantMessage is null with no assistant messages', () {
      final conv = _conv(messages: [_msg(MessageRole.user, 'Hello')]);
      expect(conv.lastAssistantMessage, isNull);
    });

    test('equality is id-based', () {
      final a = _conv();
      final b = Conversation(
        id: 'conv-1',
        userId: 'different-user',
        type: ConversationType.evening,
        date: '2026-03-24',
        messages: const [],
        expiresAt: now,
        createdAt: now,
      );
      expect(a, equals(b));
    });

    test('different ids are not equal', () {
      final a = _conv();
      final b = Conversation(
        id: 'conv-2',
        userId: 'user-1',
        type: ConversationType.morning,
        date: '2026-03-25',
        messages: const [],
        expiresAt: now,
        createdAt: now,
      );
      expect(a, isNot(equals(b)));
    });
  });
}
