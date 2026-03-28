// T154 (continued): AuthRepository contract expectations using mocktail.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:habit_coach/core/error/failures.dart';
import 'package:habit_coach/features/auth/domain/entities/user.dart';
import 'package:habit_coach/features/auth/domain/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;

  final testUser = AppUser(
    id: 'user-1',
    email: 'test@example.com',
    displayName: 'Test User',
    timezone: 'UTC',
    subscriptionTier: SubscriptionTier.free,
    notificationPreferences: NotificationPreferences.allEnabled,
    deletionStatus: DeletionStatus.active,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    repository = MockAuthRepository();
  });

  group('AuthRepository contract', () {
    test('signIn returns AppUser on success', () async {
      when(
        () => repository.signIn(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => testUser);

      final result = await repository.signIn(
        email: 'test@example.com',
        password: 'password123',
      );
      expect(result, equals(testUser));
    });

    test('signIn throws AuthFailure on wrong credentials', () async {
      when(
        () => repository.signIn(email: any(named: 'email'), password: 'wrong'),
      ).thenThrow(const AuthFailure('Invalid login credentials'));

      expect(
        () => repository.signIn(email: 'test@example.com', password: 'wrong'),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('signOut completes without error', () async {
      when(() => repository.signOut()).thenAnswer((_) async {});
      await expectLater(repository.signOut(), completes);
    });

    test('getCurrentUser returns null when not authenticated', () async {
      when(() => repository.getCurrentUser()).thenAnswer((_) async => null);
      final result = await repository.getCurrentUser();
      expect(result, isNull);
    });

    test('onAuthStateChange emits user then null', () async {
      when(
        () => repository.onAuthStateChange,
      ).thenAnswer((_) => Stream.fromIterable([testUser, null]));
      expect(repository.onAuthStateChange, emitsInOrder([testUser, null]));
    });
  });
}
