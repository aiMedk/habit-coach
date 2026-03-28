import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_coach/core/router/app_router.dart';
import 'package:habit_coach/core/theme/app_theme.dart';
import 'package:habit_coach/features/auth/presentation/providers/auth_providers.dart';
import 'package:habit_coach/features/notifications/data/services/fcm_notification_service.dart';

/// Root app widget. Consumes the GoRouter from Riverpod and applies
/// the Material 3 theme. Riverpod's ProviderScope is set up in main.dart.
class HabitCoachApp extends ConsumerStatefulWidget {
  const HabitCoachApp({super.key, required this.fcmService});

  final FCMNotificationService fcmService;

  @override
  ConsumerState<HabitCoachApp> createState() => _HabitCoachAppState();
}

class _HabitCoachAppState extends ConsumerState<HabitCoachApp> {
  bool _fcmInitialised = false;

  @override
  void initState() {
    super.initState();
    // Listen for auth state changes to initialise FCM once user is logged in.
    ref.listenManual(currentUserProvider, (_, next) {
      next.whenData((user) {
        if (user != null && !_fcmInitialised) {
          _fcmInitialised = true;
          widget.fcmService.init(user.id);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Habit Coach',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
