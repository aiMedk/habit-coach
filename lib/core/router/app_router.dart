import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:habit_coach/core/widgets/main_shell.dart';
import 'package:habit_coach/features/accountability/presentation/screens/accept_invite_screen.dart';
import 'package:habit_coach/features/accountability/presentation/screens/create_commitment_screen.dart';
import 'package:habit_coach/features/accountability/presentation/screens/invite_partner_screen.dart';
import 'package:habit_coach/features/accountability/presentation/screens/partner_dashboard_screen.dart';
import 'package:habit_coach/features/challenges/presentation/screens/challenge_detail_screen.dart';
import 'package:habit_coach/features/challenges/presentation/screens/challenges_list_screen.dart';
import 'package:habit_coach/features/challenges/presentation/screens/create_challenge_screen.dart';
import 'package:habit_coach/features/challenges/presentation/screens/join_challenge_screen.dart';
import 'package:habit_coach/features/weekly_review/presentation/screens/review_detail_screen.dart';
import 'package:habit_coach/features/weekly_review/presentation/screens/reviews_list_screen.dart';
import 'package:habit_coach/features/ai_coaching/presentation/screens/chat_screen.dart';
import 'package:habit_coach/features/ai_coaching/presentation/screens/conversation_history_screen.dart';
import 'package:habit_coach/features/auth/presentation/providers/auth_providers.dart';
import 'package:habit_coach/features/auth/presentation/screens/login_screen.dart';
import 'package:habit_coach/features/auth/presentation/screens/signup_screen.dart';
import 'package:habit_coach/features/auth/presentation/screens/splash_screen.dart';
import 'package:habit_coach/features/habits/presentation/screens/dashboard_screen.dart';
import 'package:habit_coach/features/habits/presentation/screens/habit_detail_screen.dart';
import 'package:habit_coach/features/onboarding/presentation/screens/habit_creation_screen.dart';
import 'package:habit_coach/features/onboarding/presentation/screens/onboarding_complete_screen.dart';
import 'package:habit_coach/features/onboarding/presentation/screens/welcome_screen.dart';
import 'package:habit_coach/features/habits/presentation/screens/habit_selection_screen.dart';
import 'package:habit_coach/features/settings/presentation/screens/settings_screen.dart';
import 'package:habit_coach/features/notifications/presentation/screens/notification_settings_screen.dart';
import 'package:habit_coach/features/settings/presentation/screens/block_list_screen.dart';
import 'package:habit_coach/features/subscription/presentation/screens/paywall_screen.dart';
import 'package:habit_coach/features/subscription/presentation/screens/subscription_screen.dart';

// ── Route paths ───────────────────────────────────────────────────────────────
abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const onboarding = '/onboarding';
  static const habitCreation = '/onboarding/habit';
  static const onboardingComplete = '/onboarding/complete';
  static const dashboard = '/dashboard';
  static const habitDetail = '/habit/:id';
  static const habitNew = '/dashboard/habit/new';

  // AI coaching
  static const chat = '/chat/:conversationId';
  static const conversations = '/conversations';

  // Accountability
  static const partnerInvite = '/partner/invite';
  static const partnerDashboard = '/partner/dashboard';
  static const acceptInvite = '/invite/:token';
  static const createCommitment = '/partner/commitment/create';

  // Challenges
  static const challenges = '/challenges';
  static const challengeCreate = '/challenges/create';
  static const challengeDetail = '/challenges/:id';
  static const joinChallenge = '/challenge/join/:token';

  // Reviews
  static const reviews = '/reviews';
  static const reviewDetail = '/review/:id';

  // Subscription
  static const paywall = '/paywall';
  static const habitSelection = '/habit-selection';

  // Settings
  static const settings = '/settings';
  static const settingsNotifications = '/settings/notifications';
  static const settingsSubscription = '/settings/subscription';
  static const settingsBlocked = '/settings/blocked';

  /// T128: Returns the deep-link route for a notification tap payload.
  ///
  /// Payload format: `<type>:<id>` (id may be empty for non-entity types).
  ///
  /// Routing rules:
  /// - reminder / streak_at_risk / milestone → dashboard (habit context)
  /// - partner_nudge → partner dashboard
  /// - challenge_update → challenge detail (requires id)
  static String? routeForNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    final parts = payload.split(':');
    final type = parts.first;
    final id = parts.length > 1 ? parts[1] : '';

    return switch (type) {
      'reminder' || 'streak_at_risk' || 'milestone' => dashboard,
      'partner_nudge' => partnerDashboard,
      'challenge_update' when id.isNotEmpty => challengeDetail.replaceFirst(
        ':id',
        id,
      ),
      _ => null,
    };
  }
}

/// T012 / T143: GoRouter configuration with auth redirect guard and a
/// [StatefulShellRoute] for the four-tab bottom navigation shell.
///
/// The redirect guard checks auth state from [authStateProvider] (wired in T028).
/// Routes expand as user story screens are built in later phases.
final appRouterProvider = Provider<GoRouter>((ref) {
  // Rebuild router when auth state changes so redirect guard fires.
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final onAuthRoute =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.signup;
      final onSplash = state.matchedLocation == AppRoutes.splash;

      if (onSplash) {
        return isLoggedIn ? AppRoutes.dashboard : AppRoutes.login;
      }
      if (!isLoggedIn && !onAuthRoute) return AppRoutes.login;
      if (isLoggedIn && onAuthRoute) return AppRoutes.dashboard;
      return null;
    },
    routes: [
      // ── Auth & onboarding (outside shell) ──────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.habitCreation,
        name: 'habitCreation',
        builder: (context, state) => const HabitCreationScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingComplete,
        name: 'onboardingComplete',
        builder: (context, state) => const OnboardingCompleteScreen(),
      ),

      // ── Deep links (outside shell — no bottom nav on invite/join screens) ──
      GoRoute(
        path: AppRoutes.acceptInvite,
        name: 'acceptInvite',
        builder: (context, state) {
          final token = state.pathParameters['token'] ?? '';
          return AcceptInviteScreen(inviteToken: token);
        },
      ),
      GoRoute(
        path: AppRoutes.joinChallenge,
        name: 'joinChallenge',
        builder: (context, state) {
          final token = state.pathParameters['token'] ?? '';
          return JoinChallengeScreen(inviteToken: token);
        },
      ),

      // ── Subscription / paywall (outside shell) ─────────────────────────────
      GoRoute(
        path: AppRoutes.paywall,
        name: 'paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: AppRoutes.habitSelection,
        name: 'habitSelection',
        builder: (context, state) => const HabitSelectionScreen(),
      ),

      // ── T143: StatefulShellRoute — four bottom-nav tabs ────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: [
          // Branch 0: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                name: 'dashboard',
                builder: (context, state) => const DashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'habit/new',
                    name: 'habitNew',
                    builder:
                        (context, state) => const HabitCreationScreen(
                          afterSaveRoute: AppRoutes.dashboard,
                        ),
                  ),
                  GoRoute(
                    path: 'habit/:id',
                    name: 'habitDetail',
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return HabitDetailScreen(habitId: id);
                    },
                  ),
                  GoRoute(
                    path: 'conversations',
                    name: 'conversations',
                    builder:
                        (context, state) => const ConversationHistoryScreen(),
                    routes: [
                      GoRoute(
                        path: ':conversationId',
                        name: 'chat',
                        builder: (context, state) {
                          final id =
                              state.pathParameters['conversationId'] ?? 'new';
                          return ChatScreen(conversationId: id);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'partner/invite',
                    name: 'partnerInvite',
                    builder: (context, state) => const InvitePartnerScreen(),
                  ),
                  GoRoute(
                    path: 'partner/dashboard',
                    name: 'partnerDashboard',
                    builder: (context, state) => const PartnerDashboardScreen(),
                  ),
                  GoRoute(
                    path: 'partner/commitment/create',
                    name: 'createCommitment',
                    builder: (context, state) => const CreateCommitmentScreen(),
                  ),
                ],
              ),
            ],
          ),

          // Branch 1: Challenges
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.challenges,
                name: 'challenges',
                builder: (context, state) => const ChallengesListScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    name: 'challengeCreate',
                    builder: (context, state) => const CreateChallengeScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    name: 'challengeDetail',
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return ChallengeDetailScreen(challengeId: id);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 2: Weekly Reviews
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.reviews,
                name: 'reviews',
                builder: (context, state) => const ReviewsListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: 'reviewDetail',
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return ReviewDetailScreen(reviewId: id);
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 3: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'notifications',
                    name: 'settingsNotifications',
                    builder:
                        (context, state) => const NotificationSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'subscription',
                    name: 'settingsSubscription',
                    builder: (context, state) => const SubscriptionScreen(),
                  ),
                  GoRoute(
                    path: 'blocked',
                    name: 'settingsBlocked',
                    builder: (context, state) => const BlockListScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
