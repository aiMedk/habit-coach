import 'package:flutter/foundation.dart' show protected;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_coach/features/ai_coaching/data/repositories/supabase_coaching_repository.dart';
import 'package:habit_coach/features/ai_coaching/domain/entities/conversation.dart';
import 'package:habit_coach/features/ai_coaching/domain/repositories/coaching_repository.dart';
import 'package:habit_coach/features/ai_coaching/domain/usecases/coaching_usecase.dart';
import 'package:habit_coach/features/auth/presentation/providers/auth_providers.dart';
import 'package:habit_coach/features/subscription/domain/services/entitlement_service.dart';

/// T061/T073: AI coaching Riverpod providers.

final coachingRepositoryProvider = Provider<CoachingRepository>(
  (ref) => SupabaseCoachingRepository(),
);

final coachingUseCaseProvider = Provider<CoachingUseCase>((ref) {
  return CoachingUseCase(
    coachingRepository: ref.watch(coachingRepositoryProvider),
    entitlementService: ref.watch(entitlementServiceProvider),
  );
});

/// Whether the morning prompt card should be shown on the dashboard.
final morningCardVisibilityProvider = FutureProvider<bool>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return false;
  return ref.watch(coachingUseCaseProvider).canShowMorningCard(user.id);
});

/// Whether the evening prompt card should be shown on the dashboard.
final eveningCardVisibilityProvider = FutureProvider<bool>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return false;
  return ref.watch(coachingUseCaseProvider).canShowEveningCard(user.id);
});

/// Today's morning conversation if already started.
final todayMorningConversationProvider = FutureProvider<Conversation?>((
  ref,
) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return null;
  return ref
      .watch(coachingUseCaseProvider)
      .getTodayMorningConversation(user.id);
});

/// Conversation history for the current user.
final conversationHistoryProvider = FutureProvider<List<Conversation>>((
  ref,
) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return [];
  return ref.watch(coachingUseCaseProvider).getConversationHistory(user.id);
});

/// Notifier that manages the live chat state for an open conversation.
class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this.useCase) : super(const ChatState());

  @protected
  final CoachingUseCase useCase;

  Future<void> sendMessage(String text, {String? conversationId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await useCase.sendMorningMessage(
        conversationId: conversationId ?? state.conversation?.id,
        userMessage: text.isEmpty ? null : text,
      );
      state = state.copyWith(conversation: updated, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> startConversation() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final conv = await useCase.sendMorningMessage();
      state = state.copyWith(conversation: conv, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

/// Notifier for evening reflection conversations.
/// Extends [ChatNotifier] so both morning and evening providers share the same
/// type, allowing [ChatScreen] to hold a single typed provider reference.
class EveningChatNotifier extends ChatNotifier {
  EveningChatNotifier(super.useCase);

  @override
  Future<void> sendMessage(String text, {String? conversationId}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updated = await useCase.sendEveningMessage(
        conversationId: conversationId ?? state.conversation?.id,
        userMessage: text.isEmpty ? null : text,
      );
      state = state.copyWith(conversation: updated, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  @override
  Future<void> startConversation() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final conv = await useCase.sendEveningMessage();
      state = state.copyWith(conversation: conv, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

class ChatState {
  const ChatState({this.conversation, this.isLoading = false, this.error});

  final Conversation? conversation;
  final bool isLoading;
  final String? error;

  ChatState copyWith({
    Conversation? conversation,
    bool? isLoading,
    String? error,
  }) => ChatState(
    conversation: conversation ?? this.conversation,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

final chatProvider = StateNotifierProvider.autoDispose<ChatNotifier, ChatState>(
  (ref) {
    return ChatNotifier(ref.watch(coachingUseCaseProvider));
  },
);

final eveningChatProvider =
    StateNotifierProvider.autoDispose<EveningChatNotifier, ChatState>((ref) {
      return EveningChatNotifier(ref.watch(coachingUseCaseProvider));
    });
