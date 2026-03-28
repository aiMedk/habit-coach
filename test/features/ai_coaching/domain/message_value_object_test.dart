import 'package:flutter_test/flutter_test.dart';
import 'package:habit_coach/features/ai_coaching/domain/entities/message.dart';

/// T162: Message value object unit tests.
void main() {
  final ts = DateTime(2026, 3, 25, 9, 0);

  group('Message', () {
    test('isUser is true for user role', () {
      final m = Message(role: MessageRole.user, content: 'Hi', timestamp: ts);
      expect(m.isUser, isTrue);
      expect(m.isAssistant, isFalse);
    });

    test('isAssistant is true for assistant role', () {
      final m = Message(
        role: MessageRole.assistant,
        content: 'Hello',
        timestamp: ts,
      );
      expect(m.isAssistant, isTrue);
      expect(m.isUser, isFalse);
    });

    group('toJson / fromJson', () {
      test('round-trips correctly for user role', () {
        final original = Message(
          role: MessageRole.user,
          content: 'Test message',
          timestamp: ts,
        );
        final json = original.toJson();
        final restored = Message.fromJson(json);
        expect(restored, equals(original));
      });

      test('round-trips correctly for assistant role', () {
        final original = Message(
          role: MessageRole.assistant,
          content: 'AI reply',
          timestamp: ts,
        );
        final json = original.toJson();
        final restored = Message.fromJson(json);
        expect(restored, equals(original));
      });

      test('toJson uses role name string', () {
        final m = Message(role: MessageRole.user, content: 'x', timestamp: ts);
        expect(m.toJson()['role'], 'user');
      });

      test('fromJson maps unknown role to assistant', () {
        final json = {
          'role': 'something_else',
          'content': 'x',
          'timestamp': ts.toIso8601String(),
        };
        final m = Message.fromJson(json);
        expect(m.isAssistant, isTrue);
      });
    });

    test('equality is value-based', () {
      final a = Message(role: MessageRole.user, content: 'Hi', timestamp: ts);
      final b = Message(role: MessageRole.user, content: 'Hi', timestamp: ts);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different content produces different instances', () {
      final a = Message(role: MessageRole.user, content: 'Hi', timestamp: ts);
      final b = Message(role: MessageRole.user, content: 'Bye', timestamp: ts);
      expect(a, isNot(equals(b)));
    });
  });
}
